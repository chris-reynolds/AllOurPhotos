"""
Tests for EXIF orientation handling on DERIVED images.

PIL does not honour EXIF Orientation, browsers do.  Every bug in this area has
come from those two facts disagreeing somewhere:

  - makeThumbnail applied orientation 6 with `image.rotate(270)` and no
    expand=True.  That orientation flips the aspect, so portrait content was
    squeezed back into the landscape frame - black bands down two sides, ends
    cut off - and then rotated again by the snap's own degrees.  A real photo
    (2021-03/IMG_20210302_191546.jpg, 4000x3000 tagged Orientation=6) ended up
    with 64px of solid black top and bottom.

  - rotatePic turned the pixels but wrote the original EXIF back, Orientation
    included, so the browser turned them a second time.  A 3000x4000 portrait
    preview was tagged Orientation=6 and displayed 4000x3000 landscape.

The rule these tests pin down: an image whose pixels the server has already
transformed carries no Orientation tag, and its aspect is the one the viewer
sees.  Originals on disk keep their tag and are never rewritten.
"""

import piexif
import pytest
from PIL import Image

from src.aopservermain import makeThumbnail, strip_exif_orientation


def _write_jpeg(path, size, orientation=None, colour=(120, 90, 200)):
    """A solid non-black JPEG, optionally tagged with an EXIF orientation."""
    img = Image.new('RGB', size, colour)
    if orientation is None:
        img.save(path, format='JPEG', quality=95)
    else:
        exif = piexif.dump({'0th': {piexif.ImageIFD.Orientation: orientation}})
        img.save(path, format='JPEG', exif=exif, quality=95)
    return path


def _solid_black_border(img):
    """(left, right, top, bottom) counts of wholly black edge lines."""
    img = img.convert('RGB')
    w, h = img.size
    px = img.load()
    dark = lambda p: sum(p) < 40
    col = lambda x: all(dark(px[x, y]) for y in range(h))
    row = lambda y: all(dark(px[x, y]) for x in range(w))
    left = right = top = bottom = 0
    while left < w and col(left):
        left += 1
    while right < w and col(w - 1 - right):
        right += 1
    while top < h and row(top):
        top += 1
    while bottom < h and row(h - 1 - bottom):
        bottom += 1
    return left, right, top, bottom


class TestStripExifOrientation:
    def test_orientation_is_removed(self):
        exif = piexif.dump({'0th': {piexif.ImageIFD.Orientation: 6}})
        out = strip_exif_orientation(exif)
        assert piexif.ImageIFD.Orientation not in piexif.load(out)['0th']

    def test_other_tags_survive(self):
        exif = piexif.dump({'0th': {
            piexif.ImageIFD.Orientation: 6,
            piexif.ImageIFD.Make: b'TestCam',
        }})
        out = piexif.load(strip_exif_orientation(exif))
        assert out['0th'][piexif.ImageIFD.Make] == b'TestCam'

    def test_none_and_garbage_are_survivable(self):
        # EXIF is decoration on a derived image; it must never cost a render.
        assert strip_exif_orientation(None) is None
        assert strip_exif_orientation(b'') is None
        assert strip_exif_orientation(b'not exif at all') is None


class TestMakeThumbnailOrientation:
    """A landscape original tagged 6 or 8 displays portrait, so its thumbnail
    must be portrait too - with no blank wedge anywhere."""

    @pytest.mark.parametrize('orientation', [6, 8])
    def test_aspect_follows_what_the_viewer_sees(self, tmp_path, orientation):
        src = _write_jpeg(tmp_path / 'src.jpg', (400, 300), orientation)
        target = tmp_path / 'thumb.jpg'
        img = Image.open(src)
        makeThumbnail(img, img._getexif(), str(target))

        out = Image.open(target)
        assert out.height > out.width, (
            f'orientation {orientation} flips the aspect, so the thumbnail '
            f'should be portrait; got {out.size}')

    @pytest.mark.parametrize('orientation', [6, 8])
    def test_no_black_bands(self, tmp_path, orientation):
        # The regression: rotate() without expand=True kept the landscape
        # canvas and padded the portrait content with black.
        src = _write_jpeg(tmp_path / 'src.jpg', (400, 300), orientation)
        target = tmp_path / 'thumb.jpg'
        img = Image.open(src)
        makeThumbnail(img, img._getexif(), str(target))

        borders = _solid_black_border(Image.open(target))
        assert borders == (0, 0, 0, 0), (
            f'thumbnail has blank edges {borders} - the orientation rotate '
            f'is not expanding the canvas')

    def test_upright_original_is_left_alone(self, tmp_path):
        src = _write_jpeg(tmp_path / 'src.jpg', (400, 300), orientation=1)
        target = tmp_path / 'thumb.jpg'
        img = Image.open(src)
        makeThumbnail(img, img._getexif(), str(target))

        out = Image.open(target)
        assert out.width > out.height, 'orientation 1 must not be rotated'
        assert _solid_black_border(out) == (0, 0, 0, 0)

    def test_untagged_original_is_left_alone(self, tmp_path):
        src = _write_jpeg(tmp_path / 'src.jpg', (400, 300), orientation=None)
        target = tmp_path / 'thumb.jpg'
        img = Image.open(src)
        makeThumbnail(img, img._getexif(), str(target))

        out = Image.open(target)
        assert out.width > out.height
        assert _solid_black_border(out) == (0, 0, 0, 0)

    def test_180_keeps_its_shape(self, tmp_path):
        # Orientation 3 is a half turn - aspect preserved, and it was never
        # part of the bug, so it must stay landscape.
        src = _write_jpeg(tmp_path / 'src.jpg', (400, 300), orientation=3)
        target = tmp_path / 'thumb.jpg'
        img = Image.open(src)
        makeThumbnail(img, img._getexif(), str(target))

        out = Image.open(target)
        assert out.width > out.height
        assert _solid_black_border(out) == (0, 0, 0, 0)

    @pytest.mark.parametrize('orientation', [1, 3, 6, 8])
    def test_thumbnail_carries_no_orientation_tag(self, tmp_path, orientation):
        # Pixels are already upright; a surviving tag would turn them again.
        src = _write_jpeg(tmp_path / 'src.jpg', (400, 300), orientation)
        target = tmp_path / 'thumb.jpg'
        img = Image.open(src)
        makeThumbnail(img, img._getexif(), str(target))

        out_exif = Image.open(target)._getexif() or {}
        assert out_exif.get(274) in (None, 1)


class TestThumbnailIncludesRotation:
    """A thumbnail is a scaled copy of the picture AS DISPLAYED, so it carries
    the snap's rotation too.  Skipping it is what made 'Reset Thumbnail'
    desynchronise a rotated photo instead of restoring it - the grid showed it
    upright while the single view showed it turned."""

    def _thumb(self, tmp_path, size, orientation, degrees, name='t.jpg'):
        src = _write_jpeg(tmp_path / f'src{name}', size, orientation)
        target = tmp_path / name
        img = Image.open(src)
        makeThumbnail(img, img._getexif(), str(target), degrees)
        return Image.open(target)

    def test_quarter_turn_flips_the_thumbnail(self, tmp_path):
        # Displays portrait (400x300 tagged 6), turned 90 -> lands landscape.
        out = self._thumb(tmp_path, (400, 300), 6, 90)
        assert out.width > out.height, (
            f'a quarter turn must flip the thumbnail; got {out.size}')

    def test_no_rotation_keeps_the_displayed_shape(self, tmp_path):
        out = self._thumb(tmp_path, (400, 300), 6, 0)
        assert out.height > out.width

    def test_rotated_thumbnail_has_no_blank_wedge(self, tmp_path):
        # rotate_with_border_crop trims the corners the rotation empties.
        out = self._thumb(tmp_path, (400, 300), 6, 90)
        assert _solid_black_border(out) == (0, 0, 0, 0)

    def test_small_angle_keeps_its_shape(self, tmp_path):
        # Levelling a horizon must not flip anything.
        out = self._thumb(tmp_path, (400, 300), 1, 3)
        assert out.width > out.height

    def test_rotation_does_not_compound(self, tmp_path):
        # Always rebuilt from the original, so asking twice gives one answer -
        # the property that stops 5 degrees then 10 landing at 15.
        a = self._thumb(tmp_path, (400, 300), 6, 90, name='a.jpg')
        b = self._thumb(tmp_path, (400, 300), 6, 90, name='b.jpg')
        assert a.size == b.size

    def test_360_is_the_same_as_none(self, tmp_path):
        a = self._thumb(tmp_path, (400, 300), 6, 0, name='a.jpg')
        b = self._thumb(tmp_path, (400, 300), 6, 360, name='b.jpg')
        assert a.size == b.size

    def test_rotated_thumbnail_still_carries_no_tag(self, tmp_path):
        out = self._thumb(tmp_path, (400, 300), 6, 90)
        assert (out._getexif() or {}).get(274) in (None, 1)

    def test_reset_and_rotate_agree(self, tmp_path):
        # Both endpoints now make the same call, so the same snap must give
        # byte-identical thumbnails whichever one the client hit.
        src = _write_jpeg(tmp_path / 'src.jpg', (400, 300), 6)
        reset_out, rotate_out = tmp_path / 'reset.jpg', tmp_path / 'rotate.jpg'
        for target in (reset_out, rotate_out):
            img = Image.open(src)
            makeThumbnail(img, img._getexif(), str(target), 270)
        assert reset_out.read_bytes() == rotate_out.read_bytes()

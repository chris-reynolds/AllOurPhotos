"""
Tests for fit_crop_box.

PIL's crop() pads out-of-bounds regions with black instead of raising, so a
crop box that does not match the file on disk produces a silently black image.
That happened for real: the dev photo store holds 640x480 downscaled copies
while the database records the original camera dimensions, so every crop came
out black (mean RGB 0,0,0) or nearly so.
"""

import pytest
from PIL import Image

from src.aopservermain import fit_crop_box, rotate_with_border_crop


def _marker_box(im):
    """Bounding box of the red marker, or None."""
    px = im.convert('RGB').load()
    xs, ys = [], []
    for y in range(0, im.height, 2):
        for x in range(0, im.width, 2):
            r, g, b = px[x, y]
            if r > 180 and g < 80 and b < 80:
                xs.append(x)
                ys.append(y)
    return (min(xs), min(ys), max(xs), max(ys)) if xs else None


class TestCroppingARotatedPhoto:
    """A rotated photo is viewed through /rotate, so the crop rectangle is in
    ROTATED coordinates.  Cropping the unrotated original with them takes a
    quite different region - the crop has to be applied to the same picture
    the user was looking at."""

    def _source(self):
        im = Image.new('RGB', (300, 300), (0, 0, 0))
        im.paste((255, 0, 0), (230, 20, 280, 70))  # marker near the top right
        return im

    def test_the_marker_moves_when_the_photo_is_rotated(self):
        src = self._source()
        assert _marker_box(src) != _marker_box(rotate_with_border_crop(src, 90))

    def test_rotating_first_takes_the_region_the_user_selected(self):
        src = self._source()
        viewed = rotate_with_border_crop(src, 90)  # what the client displays
        left, top, right, bottom = _marker_box(viewed)
        box = (left - 6, top - 6, right + 6, bottom + 6)

        # What the server does now: reproduce the view, then crop it.
        got = rotate_with_border_crop(src, 90).crop(box)
        assert _marker_box(got) is not None, \
            'the crop must contain what the user selected'

    def test_cropping_the_unrotated_original_misses_it(self):
        # The old behaviour, kept as a guard: it must genuinely differ, or the
        # test above proves nothing.
        src = self._source()
        viewed = rotate_with_border_crop(src, 90)
        left, top, right, bottom = _marker_box(viewed)
        box = (left - 6, top - 6, right + 6, bottom + 6)
        assert _marker_box(src.crop(box)) is None, \
            'cropping the original with rotated coordinates takes the wrong bit'


class TestMatchingDimensions:
    """When the file matches the database, the box is passed through."""

    def test_box_is_unchanged(self):
        assert fit_crop_box((100, 200, 900, 800), (3264, 2448),
                            (3264, 2448)) == (100, 200, 900, 800)

    def test_a_full_frame_box_survives(self):
        assert fit_crop_box((0, 0, 3264, 2448), (3264, 2448),
                            (3264, 2448)) == (0, 0, 3264, 2448)


class TestRescaling:
    """The dev store case: a downscaled file behind full-size metadata."""

    def test_box_is_scaled_to_the_real_image(self):
        # 640x480 file, database says 3264x2448 -> scale by 640/3264.
        box = fit_crop_box((1632, 1224, 3264, 2448), (640, 480), (3264, 2448))
        assert box == (320, 240, 640, 480), \
            'the bottom-right quarter should stay the bottom-right quarter'

    def test_result_is_inside_the_real_image(self):
        left, top, right, bottom = fit_crop_box(
            (0, 0, 3264, 2448), (640, 480), (3264, 2448))
        assert (left, top) == (0, 0)
        assert right <= 640 and bottom <= 480

    def test_the_black_crop_case(self):
        # The exact failure: a selection near the far edge of the recorded
        # dimensions lands entirely outside a 640x480 file, so PIL returned
        # a wholly black image.
        left, top, right, bottom = fit_crop_box(
            (1656, 453, 3264, 2448), (640, 480), (3264, 2448))
        assert right <= 640 and bottom <= 480
        assert right > left and bottom > top
        assert left < 640 and top < 480, 'must land on real pixels, not padding'


class TestClamping:
    """Whatever arrives, the box must be inside the image and non-empty."""

    def test_out_of_bounds_box_is_pulled_in(self):
        assert fit_crop_box((-500, -500, 9999, 9999), (640, 480),
                            (640, 480)) == (0, 0, 640, 480)

    def test_inverted_box_is_normalised(self):
        left, top, right, bottom = fit_crop_box((500, 400, 100, 80),
                                                (640, 480), (640, 480))
        assert left < right and top < bottom

    def test_degenerate_box_still_has_area(self):
        left, top, right, bottom = fit_crop_box((300, 300, 300, 300),
                                                (640, 480), (640, 480))
        assert right > left and bottom > top, 'a zero-size crop would fail'

    def test_box_entirely_past_the_edge_is_pulled_back(self):
        left, top, right, bottom = fit_crop_box((5000, 5000, 6000, 6000),
                                                (640, 480), (640, 480))
        assert 0 <= left < right <= 640
        assert 0 <= top < bottom <= 480

    @pytest.mark.parametrize('recorded', [(None, None), (0, 0)])
    def test_missing_recorded_size_just_clamps(self, recorded):
        # width/height are nullable in the database.
        assert fit_crop_box((100, 100, 500, 400), (640, 480),
                            recorded) == (100, 100, 500, 400)

"""
Tests for thumbnail_name().

The server and the Flutter client each derive a thumbnail's filename from the
original photo's name, and they have to agree exactly or the thumbnail written
is not the one fetched.  They drifted: reset_thumbnail and rotate_thumbnail
used `os.path.splitext(name)[0] + '.jpg'`, unconditionally lowercasing the
extension, while the client keeps the original case whenever the name is
already a .jpg in any case.

On case-sensitive Linux that split DSCN5138.JPG (asked for) from DSCN5138.jpg
(written).  Both endpoints rebuilt the thumbnail, returned ok, and left the
stale one on display - for the 20k+ .JPG originals, over half the library.

These cases mirror `String get thumbnailURL` in aopmodel/lib/aop_classes.dart:

    String thumbName = fileName ?? 'noname';
    if (!thumbName.toLowerCase().endsWith('.jpg')) {
      thumbName = path.setExtension(fileName!, '.jpg');
    }

Change one side and this should fail.
"""

import pytest

from src.aopservermain import thumbnail_name


class TestAlreadyJpeg:
    """A name that is already .jpg in any case is returned untouched."""

    @pytest.mark.parametrize('name', [
        'DSCN5138.jpg',
        'DSCN5138.JPG',
        'DSCN5138.Jpg',
        'a.b.JPG',          # only the final extension counts
    ])
    def test_case_is_preserved(self, name):
        assert thumbnail_name(name) == name


class TestOtherExtensions:
    """Anything else has its extension swapped for a lowercase .jpg."""

    @pytest.mark.parametrize('name,expected', [
        ('PIC.png', 'PIC.jpg'),
        ('PIC.PNG', 'PIC.jpg'),
        ('photo.jpeg', 'photo.jpg'),     # .jpeg is not .jpg
        ('VID_1234.mp4', 'VID_1234.jpg'),
        ('MVI_0001.MOV', 'MVI_0001.jpg'),
        ('noext', 'noext.jpg'),
    ])
    def test_extension_is_replaced(self, name, expected):
        assert thumbnail_name(name) == expected


class TestRegression:
    """The specific failure that made rotate and reset appear to do nothing."""

    def test_uppercase_jpg_is_not_lowercased(self):
        # The old code returned 'DSCN5138.jpg' here, which the client never
        # requests, so the rebuilt thumbnail was written and then ignored.
        assert thumbnail_name('DSCN5138.JPG') == 'DSCN5138.JPG'

    def test_thumbnail_is_stable_under_repeated_calls(self):
        # Feeding the result back in must not keep changing the name, or a
        # second rotate would orphan the file the first one wrote.
        once = thumbnail_name('DSCN5138.JPG')
        assert thumbnail_name(once) == once

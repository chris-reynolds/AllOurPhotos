"""
Tests for fit_crop_box.

PIL's crop() pads out-of-bounds regions with black instead of raising, so a
crop box that does not match the file on disk produces a silently black image.
That happened for real: the dev photo store holds 640x480 downscaled copies
while the database records the original camera dimensions, so every crop came
out black (mean RGB 0,0,0) or nearly so.
"""

import pytest

from src.aopservermain import fit_crop_box


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

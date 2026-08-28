"""
Tests for conditional requests on /photos.

Thumbnails went out with an ETag and a Last-Modified but no Cache-Control at
all, which leaves the browser to invent a freshness lifetime - commonly a
tenth of the file's age.  A thumbnail written in 2019 therefore counted as
fresh for years, so rebuilding it on the server changed nothing on screen
until someone hard-refreshed.

Adding 'no-cache' on its own would have been worse: the browser would ask
every time and FileResponse would answer 200 with the whole picture, because
it computes an etag but never returns 304 - that logic lives in StaticFiles,
which this route does not use.  So the header and the 304 have to arrive
together, and then re-checking a grid costs a few hundred bytes per thumbnail
instead of twenty kilobytes.
"""

import pytest

from src.aopservermain import etag_matches


class FakeRequest:
    def __init__(self, headers=None):
        self.headers = headers or {}


class TestEtagMatches:

    def test_no_request_header_is_a_miss(self):
        # First ever view: nothing cached, so send the picture.
        assert etag_matches(FakeRequest(), '"abc"') is False

    def test_exact_match_is_a_hit(self):
        # The normal case - browsers echo back exactly what we sent.
        assert etag_matches(FakeRequest({'if-none-match': '"abc"'}), '"abc"')

    def test_different_etag_is_a_miss(self):
        # A rebuilt thumbnail changes mtime and size, so the etag changes and
        # this is the path that actually delivers the new picture.
        assert etag_matches(
            FakeRequest({'if-none-match': '"stale"'}), '"fresh"') is False

    def test_weak_etag_is_a_hit(self):
        assert etag_matches(FakeRequest({'if-none-match': 'W/"abc"'}), '"abc"')

    def test_list_of_etags_matches_any(self):
        assert etag_matches(
            FakeRequest({'if-none-match': '"other", "abc"'}), '"abc"')

    def test_star_matches_anything_cached(self):
        assert etag_matches(FakeRequest({'if-none-match': '*'}), '"abc"')

    def test_missing_server_etag_is_a_miss(self):
        # Without an etag to compare we must serve the file, never a bare 304.
        assert etag_matches(FakeRequest({'if-none-match': '"abc"'}), None) is False
        assert etag_matches(FakeRequest({'if-none-match': '"abc"'}), '') is False

    def test_unquoted_comparison_still_matches(self):
        # Tolerate a proxy that strips the quotes rather than 200-ing a file
        # the browser already holds.
        assert etag_matches(FakeRequest({'if-none-match': 'abc'}), '"abc"')

    @pytest.mark.parametrize('header', ['', '   ', ','])
    def test_empty_or_junk_headers_are_a_miss(self, header):
        assert etag_matches(FakeRequest({'if-none-match': header}), '"abc"') is False

"""
Tests for the /rotate on-disk cache.

Before this cache, /rotate re-ran the full-resolution PIL rotate on every
request and wrote the result to temp/fred{random}.jpg.  That meant the
rotate was never reused, the ETag changed on every response so browsers
could not cache it either, and the temp files accumulated forever.
"""

import os
import pytest

from src.aopservermain import (
    rotate_cache_path,
    prune_rotate_cache,
    prune_export_files,
    ROOT_DIR,
    ROTATE_CACHE_DIR,
    ROTATE_CACHE_KEEP,
    EXPORT_DIR,
    EXPORT_KEEP,
)


# ---------------------------------------------------------------------------
# rotate_cache_path — the name must depend only on the source path and angle
# ---------------------------------------------------------------------------

class TestRotateCachePath:

    def test_same_inputs_give_same_name(self):
        a = rotate_cache_path('2019/03/P1010101.JPG', 90)
        b = rotate_cache_path('2019/03/P1010101.JPG', 90)
        assert a == b, 'a repeat request must reuse the cached file'

    def test_different_angle_gives_different_name(self):
        a = rotate_cache_path('2019/03/P1010101.JPG', 90)
        b = rotate_cache_path('2019/03/P1010101.JPG', 180)
        assert a != b

    def test_different_path_gives_different_name(self):
        a = rotate_cache_path('2019/03/P1010101.JPG', 90)
        b = rotate_cache_path('2019/03/P1010102.JPG', 90)
        assert a != b

    def test_cache_dir_is_under_the_photos_volume(self):
        # It must sit on the mounted photos volume, not in the container's
        # own filesystem, so it survives a redeploy and can be inspected
        # from the host.
        assert os.path.basename(ROTATE_CACHE_DIR) == 'rotate_temp'
        assert os.path.dirname(ROTATE_CACHE_DIR.replace('\\', '/')).startswith(
            ROOT_DIR.replace('\\', '/').rstrip('/'))

    def test_name_is_in_the_cache_dir_and_marked(self):
        p = rotate_cache_path('2019/03/P1010101.JPG', 90)
        assert os.path.dirname(p) == ROTATE_CACHE_DIR
        # The rot_ prefix is what keeps pruning away from other temp files.
        assert os.path.basename(p).startswith('rot_')
        assert p.endswith('.jpg')

    def test_awkward_paths_do_not_escape_the_cache_dir(self):
        # The name is a hash, so separators in the source path cannot turn
        # into directories.
        p = rotate_cache_path('../../etc/passwd', 90)
        assert os.path.dirname(p) == ROTATE_CACHE_DIR


# ---------------------------------------------------------------------------
# prune_rotate_cache — keep the newest few, and touch nothing else
# ---------------------------------------------------------------------------

def _make(dirpath, name, age_seconds):
    """Creates a file and back-dates it so ordering is deterministic."""
    full = os.path.join(dirpath, name)
    with open(full, 'w') as f:
        f.write('x')
    stamp = 1_600_000_000 - age_seconds
    os.utime(full, (stamp, stamp))
    return full


@pytest.fixture
def cache_dir(tmp_path, monkeypatch):
    d = tmp_path / 'temp'
    d.mkdir()
    monkeypatch.setattr('src.aopservermain.ROTATE_CACHE_DIR', str(d))
    return str(d)


class TestPruneRotateCache:

    def test_keeps_the_newest_and_drops_the_rest(self, cache_dir):
        for i in range(10):
            _make(cache_dir, f'rot_{i:03d}.jpg', age_seconds=i * 60)
        prune_rotate_cache(keep=4)
        left = sorted(os.listdir(cache_dir))
        assert left == ['rot_000.jpg', 'rot_001.jpg', 'rot_002.jpg',
                        'rot_003.jpg'], 'the four most recent should survive'

    def test_does_nothing_when_under_the_limit(self, cache_dir):
        for i in range(3):
            _make(cache_dir, f'rot_{i:03d}.jpg', age_seconds=i * 60)
        prune_rotate_cache(keep=20)
        assert len(os.listdir(cache_dir)) == 3

    def test_leaves_other_files_alone(self, cache_dir):
        # The cache has its own directory now, but the rot_ guard stays as
        # defence in depth - pruning must never reach beyond its own files.
        for i in range(5):
            _make(cache_dir, f'rot_{i:03d}.jpg', age_seconds=i * 60)
        _make(cache_dir, 'export_1234.jpg', age_seconds=99999)
        _make(cache_dir, 'holiday.MOV', age_seconds=99999)
        _make(cache_dir, 'fred7.jpg', age_seconds=99999)
        prune_rotate_cache(keep=1)
        left = set(os.listdir(cache_dir))
        assert 'export_1234.jpg' in left
        assert 'holiday.MOV' in left
        assert 'fred7.jpg' in left
        assert len([n for n in left if n.startswith('rot_')]) == 1

    def test_ignores_part_files_still_being_written(self, cache_dir):
        _make(cache_dir, 'rot_aaa.jpg', age_seconds=0)
        _make(cache_dir, 'rot_bbb.jpg.123.456.part', age_seconds=99999)
        prune_rotate_cache(keep=1)
        left = set(os.listdir(cache_dir))
        assert 'rot_bbb.jpg.123.456.part' in left, \
            'a partial write must not be pruned out from under its writer'

    def test_missing_directory_is_not_an_error(self, tmp_path, monkeypatch):
        monkeypatch.setattr('src.aopservermain.ROTATE_CACHE_DIR',
                            str(tmp_path / 'does_not_exist'))
        prune_rotate_cache(keep=5)   # must not raise

    def test_default_keep_is_the_configured_limit(self, cache_dir):
        for i in range(ROTATE_CACHE_KEEP + 5):
            _make(cache_dir, f'rot_{i:03d}.jpg', age_seconds=i * 60)
        prune_rotate_cache()
        assert len(os.listdir(cache_dir)) == ROTATE_CACHE_KEEP


# ---------------------------------------------------------------------------
# prune_export_files — /export_snap leaked the same way /rotate did
# ---------------------------------------------------------------------------

@pytest.fixture
def export_dir(tmp_path, monkeypatch):
    d = tmp_path / 'exports'
    d.mkdir()
    monkeypatch.setattr('src.aopservermain.EXPORT_DIR', str(d))
    return str(d)


class TestPruneExportFiles:

    def test_export_dir_is_not_on_the_photos_volume(self):
        # Exports are one-shot and worthless once served, so they must not
        # land in the photos tree and end up in the photo backups.
        assert not os.path.isabs(EXPORT_DIR)
        assert 'photos' not in EXPORT_DIR

    def test_keeps_the_newest_and_drops_the_rest(self, export_dir):
        for i in range(30):
            _make(export_dir, f'export_{i:03d}.jpg', age_seconds=i * 60)
        prune_export_files(keep=5)
        left = sorted(os.listdir(export_dir))
        assert left == [f'export_{i:03d}.jpg' for i in range(5)]

    def test_leaves_rotate_and_video_files_alone(self, export_dir):
        for i in range(5):
            _make(export_dir, f'export_{i:03d}.jpg', age_seconds=i * 60)
        _make(export_dir, 'rot_abc.jpg', age_seconds=99999)
        _make(export_dir, 'holiday.MOV', age_seconds=99999)
        prune_export_files(keep=1)
        left = set(os.listdir(export_dir))
        assert 'rot_abc.jpg' in left
        assert 'holiday.MOV' in left

    def test_keeps_enough_headroom_for_concurrent_downloads(self):
        # A file must not be pruned while it is still being streamed.
        assert EXPORT_KEEP >= 10

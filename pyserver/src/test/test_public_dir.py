"""
Tests for the unauthenticated public area at /public.

The files live in <photos>/public but are served from /public, outside the
/photos prefix, so the authenticated /photos routes keep no exemptions.

It must never serve anything outside the public directory - it is the one GET
in the server that skips the session check.
"""

import pytest
from fastapi import HTTPException
from fastapi.testclient import TestClient

import src.aopservermain as server
from src.aopservermain import app

client = TestClient(app, raise_server_exceptions=False)


@pytest.fixture
def public_dir(tmp_path, monkeypatch):
    scratch = tmp_path / 'public'
    scratch.mkdir()
    monkeypatch.setattr(server, 'PUBLIC_DIR', str(scratch))
    return scratch


class TestPublicTempServing:

    def test_file_is_served_without_a_session(self, public_dir):
        (public_dir / 'note.txt').write_text('hello')
        response = client.get('/public/note.txt')
        assert response.status_code == 200
        assert response.text == 'hello'

    def test_nested_file_is_served(self, public_dir):
        (public_dir / 'sub').mkdir()
        (public_dir / 'sub' / 'a.txt').write_text('deep')
        assert client.get('/public/sub/a.txt').text == 'deep'

    def test_response_is_not_cacheable(self, public_dir):
        (public_dir / 'note.txt').write_text('hello')
        response = client.get('/public/note.txt')
        assert response.headers['cache-control'] == 'no-store'

    def test_missing_file_is_404(self, public_dir):
        assert client.get('/public/nope.txt').status_code == 404

    def test_directory_is_not_listed(self, public_dir):
        (public_dir / 'sub').mkdir()
        assert client.get('/public/sub').status_code == 404

    def test_other_photos_paths_still_need_a_session(self, public_dir):
        # The old /photos/public path must not become an unauthenticated way in.
        assert client.get('/photos/2024-01/photo.jpg').status_code == 401
        assert client.get('/photos/public/note.txt').status_code == 401

    def test_put_is_not_allowed(self, public_dir):
        response = client.put('/public/new.txt', content=b'data')
        assert response.status_code in (401, 405)
        assert not (public_dir / 'new.txt').exists()


class TestSafePublicTempPath:

    @pytest.mark.parametrize('name', [
        '../secret.txt',
        '../../config.json',
        'sub/../../secret.txt',
        '',
        '.',
    ])
    def test_escape_attempts_are_rejected(self, public_dir, name):
        with pytest.raises(HTTPException) as exc_info:
            server.safe_public_path(name)
        assert exc_info.value.status_code == 400

    def test_sibling_with_shared_prefix_is_rejected(self, public_dir):
        # 'public_other' starts with 'public' textually but is not inside it.
        (public_dir.parent / 'public_other').mkdir()
        with pytest.raises(HTTPException):
            server.safe_public_path('../public_other/x.txt')

    def test_normal_name_is_accepted(self, public_dir):
        assert server.safe_public_path('a.jpg').endswith('a.jpg')

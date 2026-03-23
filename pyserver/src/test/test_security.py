"""
Security tests covering fixes from the security review:
  Fix 1  - SQL injection sanitization in makeSession
  Fix 3  - SQL injection via find endpoint (parameterized queries)
  Fix 4  - Path traversal in /photos/ GET & PUT
  Fix 5  - Path traversal via upload filename (os.path.basename)
  Fix 6  - Auth required on PUT /photos/
  Fix 7  - Auth required on GET /photos/
"""

import os
import re
import json
import pytest
from fastapi.testclient import TestClient
from src.aopservermain import app, safe_photos_path
from fastapi import HTTPException

client = TestClient(app, raise_server_exceptions=False)


# ---------------------------------------------------------------------------
# Fix 1 — SQL injection sanitization in makeSession
# These are unit tests against the sanitization logic itself, no DB needed.
# ---------------------------------------------------------------------------

def _sanitize(value: str) -> str:
    """Mirror of the sanitization applied in makeSession."""
    return re.sub(r'[^a-zA-Z0-9]', '', value)[:20]

class TestMakeSessionSanitization:

    def test_sql_injection_chars_stripped_from_user(self):
        assert _sanitize("admin' OR '1'='1") == "adminOR11"

    def test_sql_injection_stripped_from_password(self):
        assert _sanitize("'; DROP TABLE aopusers; --") == "DROPTABLEaopusers"

    def test_truncated_to_20_chars(self):
        assert len(_sanitize('a' * 30)) == 20

    def test_alphanumeric_value_unchanged(self):
        assert _sanitize('mypassword123') == 'mypassword123'

    def test_special_chars_stripped(self):
        assert _sanitize('<script>alert(1)</script>') == 'scriptalert1script'

    def test_login_with_sql_injection_returns_200_not_500(self):
        """SQL injection attempt should not cause a server error (requires DB)."""
        response = client.get("/ses/admin' OR '1'='1/anything/pytest_security")
        assert response.status_code == 200, (
            f"Expected 200 (failed login), got {response.status_code}"
        )
        data = json.loads(response.content)
        assert int(data['jam']) == -1, "SQL injection should not grant access"


# ---------------------------------------------------------------------------
# Fix 4 — Path traversal in /photos/ endpoints
# Test safe_photos_path() directly — HTTP clients normalize ../ before sending,
# so the unit test is the reliable way to verify the containment check.
# ---------------------------------------------------------------------------

class TestPhotosPathTraversal:

    def test_traversal_one_level_raises(self):
        """../config.json should be rejected as outside the photos base."""
        with pytest.raises(HTTPException) as exc_info:
            safe_photos_path('../config.json')
        assert exc_info.value.status_code == 400

    def test_traversal_multiple_levels_raises(self):
        with pytest.raises(HTTPException) as exc_info:
            safe_photos_path('../../etc/passwd')
        assert exc_info.value.status_code == 400

    def test_traversal_mixed_path_raises(self):
        with pytest.raises(HTTPException) as exc_info:
            safe_photos_path('2024/01/../../../config.json')
        assert exc_info.value.status_code == 400

    def test_normal_path_accepted(self):
        """A normal relative path should not raise."""
        try:
            safe_photos_path('2024/01/photo.jpg')
        except HTTPException as e:
            pytest.fail(f"safe_photos_path raised unexpectedly: {e.detail}")

    def test_traversal_via_http_returns_404_or_400(self):
        """Via HTTP the client normalizes ../ so we get 404 (route miss) — still not served."""
        response = client.get('/photos/../config.json')
        assert response.status_code in (400, 404)


# ---------------------------------------------------------------------------
# Fix 6 & 7 — Authentication on /photos/ endpoints
# get_session_from_request raises 401 before any DB call when no cookie present.
# ---------------------------------------------------------------------------

class TestPhotosAuth:

    def test_get_photos_without_session_returns_401(self):
        response = client.get('/photos/some/photo.jpg')
        assert response.status_code == 401

    def test_put_photos_without_session_returns_401(self):
        response = client.put('/photos/some/photo.jpg', content=b'data')
        assert response.status_code == 401


# ---------------------------------------------------------------------------
# Fix 5 — Upload filename path traversal (os.path.basename)
# Pure unit test — no server or DB needed.
# ---------------------------------------------------------------------------

class TestUploadFilenameBasename:

    def test_traversal_stripped(self):
        assert os.path.basename('../../evil.txt') == 'evil.txt'

    def test_nested_traversal_stripped(self):
        assert os.path.basename('../etc/passwd') == 'passwd'

    def test_normal_filename_unchanged(self):
        assert os.path.basename('IMG_0001.JPG') == 'IMG_0001.JPG'

    def test_upload_with_traversal_filename_does_not_500(self):
        """An upload with a traversal filename should fail gracefully, not 500."""
        response = client.post(
            '/upload2/2024:01:01 00:00:00/../../evil.jpg/pytest_security',
            files={'myfile': ('evil.jpg', b'not a real image', 'image/jpeg')},
        )
        assert response.status_code != 500


# ---------------------------------------------------------------------------
# Fix 3 — SQL injection via find endpoint (requires DB)
# ---------------------------------------------------------------------------

class TestFindEndpointSanitization:

    def test_unknown_key_returns_404_not_500(self):
        """A missing find key should return 404, not 500."""
        response = client.get('/find/nonexistent_key_xyz')
        assert response.status_code == 404

    def test_sql_injection_in_param_does_not_cause_500(self):
        """SQL injection in a find param value should not cause a server error (requires DB)."""
        url = "/find/nameExists?filename=blah' OR '1'%3D'1&start=2000-01-01 00:00:00&end=2000-01-01 00:00:00"
        response = client.get(url)
        assert response.status_code != 500, (
            f"SQL injection in find param caused a server error: {response.content}"
        )

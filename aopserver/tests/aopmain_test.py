import pytest
from fastapi.testclient import TestClient
from aopservermain import app



@pytest.fixture
def client():
    return TestClient(app)

def test_static(client):
#    client = TestClient(app)
    response = client.get('photos/monthly.txt')
    assert response.status_code == 200
    result = response.text
    delimPos = result.find('199901=cj')
    assert delimPos>0

def test_new_image_dup():
    assert 1 == 0

def test_new_image_original():
    assert 1 == 0

def test_check_thumbnail():
    assert 1 == 0

def test_check_metadata():
    assert 1 == 0

def test_check_location():
    assert 1 == 0


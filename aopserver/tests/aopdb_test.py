import pytest
from fastapi.testclient import TestClient
from aopservermain import app,condb

@pytest.fixture
def db():
    return condb


def test_connect_good(db):
    assert condb.connection.is_connected

def test_connect_bad():
    assert 1 == 0

def test_fetchsome_noparams():
    assert 1 == 0

def test_fetchsome_where():
    assert 1 == 0

def test_fetchsome_cols():
    assert 1 == 0

def test_fetch1(db):
    result = db.getById('snap',12)
    assert result.length == 1

def test_metadata_tables():
    assert 1 == 0

def test_sql_factory_insert():
    assert 1 == 0

def test_sql_factory_update():
    assert 1 == 0

def test_fetchFK():
    assert 1 == 0


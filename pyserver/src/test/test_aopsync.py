import pytest
import os
from fastapi.testclient import TestClient
from src.aopservermain import app

# tests for aopsync
client = TestClient(app)

def loginpair():
  x = os.environ['aop_login'] or 'blah-blah'
  x= x.split('-',1)
  return {'U':x[0],'P':x[1]}

def test_fred():
    print(loginpair())
    response = client.get('/hello')
    assert response.status_code == 200
    
    
def test_login_bad_user():
    raise Exception('Todo')

def test_login_good_user_bad_password():
    raise Exception('To do')

def test_login_good_user_good_passowrd_quoted_device():
    raise Exception('To do')

def test_login_good_user_good_password_unquoted_device():
    raise Exception('To do')

def test_existance_check1_using_filename_date_modified():
    print('*****************************testing**********************')
    raise Exception('To do')

def test_existance_check2_using_metadata():
        raise Exception('To do')

def test_add_file_folder():
    raise Exception('To do')

def test_add_thumbnail():
    raise Exception('To do')

def test_test_add_metadata():
    raise Exception('To do')

def test_test_add_to_db_correctly():
    raise Exception('To do')

def test_location_deduced_and_stored():
    raise Exception('To do')

def clear_testdata():
    pass





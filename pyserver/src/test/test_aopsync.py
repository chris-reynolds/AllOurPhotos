import pytest
import os
import json
import datetime as dt
from fastapi.testclient import TestClient
from src.aopservermain import app
# from test_utils as tu

# tests for aopsync
client = TestClient(app)

def loginpair():
  x = os.environ['aop_test_login'] or 'blah-blah'
  x= x.split('-',1)
  return {'U':x[0],'P':x[1]}

def loginCheck(response, expected):
    assert response.status_code == 200
    print(response)
    jam_object = json.loads(response.content)
    if (expected):
      assert(int(jam_object['jam']) > 0) 
    else:
      assert(int(jam_object['jam']) == -1) 
        

@pytest.fixture
def clean():
    pass
#    tu.init_env(loginpair())
#    tu.clear_testdata()

def test_login_bad_user():
    uspw = loginpair()
    url = '/ses/baduser/blah/pytest_bad_user'
    response = client.get(url)
    assert response.status_code == 200
    print(response)
    jam_object = json.loads(response.content)
    assert(jam_object['jam'] == '-1') 


def test_login_good_user_bad_password():
    uspw = loginpair()
    url = '/ses/{uspw.U}/blah/pytest_bad_password'
    response = client.get(url)
    assert response.status_code == 200
    print(response)
    jam_object = json.loads(response.content)
    assert(jam_object['jam'] == '-1') 

def login_good_user_good_password():
    uspw = loginpair()
    url = f'/ses/{uspw["U"]}/{uspw["P"]}/pytest_unquoted_device'
    response = client.get(url)
    loginCheck(response, True)
    session = response.content
    return session

def test_login_good_user_good_password_quoted_device():
    uspw = loginpair()
    url = f"/ses/{uspw['U']}/{uspw['P']}/pytest'device"
    response = client.get(url)
    loginCheck(response, True)

def test_existance_check1_using_filename_date_modified():
    login_good_user_good_password()
    myFilename = 'IMG_0700.JPG'
    myTakendate = '1980-01-01 00:00:19'
    url = f'/find/nameExists?filename={myFilename}&start={myTakendate}&end={myTakendate}'
    response = client.get(url)
    values = json.loads(response.content)
    assert values[0][0] > 0, 'Count should be greater than zero for existing photo'
    url = f'/find/nameExists?filename=blahblah&start={myTakendate}&end={myTakendate}'
    response = client.get(url)
    values = json.loads(response.content)
    assert values[0][0] == 0, 'Count should be  zero for non-existant photo'


def test_camera_post(clean):
    session = login_good_user_good_password()
    testFilename = 'P5074819.JPG'
    testFile = open(f'testdata/{testFilename}','rb')
    modified_time = os.path.getmtime(f'testdata/{testFilename}')
    modified_timeStr = dt.datetime.fromtimestamp(modified_time).strftime('%Y:%m:%d %H:%M:%S')
    url = f'/upload2/{modified_timeStr}/{testFilename}/pytest'
    response = client.post(url,files={'myfile': testFile},headers=[(b'Preserve',session)]) 
    assert response.status_code == 200, f'Failed http {response.status_code}\n{response.content}'

def test_samsung_post():
    session = login_good_user_good_password()
    print(os.curdir)
    testFilename = '20230510_111443.jpg'
    testFile = open(f'testdata/{testFilename}','rb')
    modified_time = os.path.getmtime(f'testdata/{testFilename}')
    modified_timeStr = dt.datetime.fromtimestamp(modified_time).strftime('%Y:%m:%d %H:%M:%S')
    url = f'/upload2/{modified_timeStr}/{testFilename}/pytest'
    response = client.post(url,files={'myfile': testFile},headers=[(b'Preserve',session)]) 
    assert response.status_code == 200, f'Failed http {response.status_code}\n{response.content}'

def test_huawei_post():
    session = login_good_user_good_password()
    testFilename = 'IMG_20230511_172050.jpg'
    testFile = open(f'testdata/{testFilename}','rb')
    modified_time = os.path.getmtime(f'testdata/{testFilename}')
    modified_timeStr = dt.datetime.fromtimestamp(modified_time).strftime('%Y:%m:%d %H:%M:%S')
    url = f'/upload2/{modified_timeStr}/{testFilename}/pytest'
    response = client.post(url,files={'myfile': testFile},headers=[(b'Preserve',session)]) 
    assert response.status_code == 200, f'Failed http {response.status_code}\n{response.content}'

def test_video(clean):
    session = login_good_user_good_password()
    testFilename = 'adji.mov' #'agopro.mp4'
    testFile = open(f'testdata/{testFilename}','rb')
    modified_time = os.path.getmtime(f'testdata/{testFilename}')
    modified_timeStr = dt.datetime.fromtimestamp(modified_time).strftime('%Y:%m:%d %H:%M:%S')
    url = f'/upload_video/{modified_timeStr}/{testFilename}/pytest'
    response = client.post(url,files={'video': testFile},headers=[(b'Preserve',session)]) 
    assert response.status_code == 200, f'Failed http {response.status_code}\n{response.content}'

def test_add_file_folder():
    raise Exception('To do')

def test_add_thumbnail():
    raise Exception('To do')

def test_add_metadata():
    raise Exception('To do')

def test_add_to_db_correctly():
    raise Exception('To do')

def test_location_deduced_and_stored():
    raise Exception('To do')

def clear_testdata():
    pass





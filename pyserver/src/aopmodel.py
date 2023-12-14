# Generated by Maxim from fastapi.txt 
# Chris Reynolds on 25-Oct-2023 07:54:09
from pydantic import BaseModel
from typing import Union, List
#                                 '*** Start Custom Code importing
from datetime import datetime
#                                 '*** End Custom Code

#                                 '*** Start Custom Code maxim types
MxString = str
MxDatetime = datetime
MxFloat = float
MxInteger = int
MxMemo = str
opMxString = str | None
opMxDatetime = datetime | None
opMxFloat = float | None
opMxInteger = int | None
opMxMemo = str | None
#                                 '*** End Custom Code

class Album(BaseModel):
    id: opMxInteger = None
    created_on: opMxDatetime = None
    updated_on: opMxDatetime = None
    updated_user: opMxString = None
    name: MxString
    description: Union[MxString, None] = None
    first_date: Union[MxDatetime, None] = None
    last_date: Union[MxDatetime, None] = None
    user_id: Union[int, None] = None
#                                 '*** Start Custom Code album
#                                 '*** End Custom Code
	
class AlbumItem(BaseModel):
    id: opMxInteger = None
    created_on: opMxDatetime = None
    updated_on: opMxDatetime = None
    updated_user: opMxString = None
    album_id: Union[int, None] = None
    snap_id: Union[int, None] = None
#                                 '*** Start Custom Code albumitem
#                                 '*** End Custom Code
	
class Session(BaseModel):
    id: opMxInteger = None
    created_on: opMxDatetime = None
    updated_on: opMxDatetime = None
    updated_user: opMxString = None
    start_date: Union[MxDatetime, None] = None
    end_date: Union[MxDatetime, None] = None
    source: Union[MxString, None] = None
    user_id: Union[int, None] = None
#                                 '*** Start Custom Code session
#                                 '*** End Custom Code
	
class Snap(BaseModel):
    id: opMxInteger = None
    created_on: opMxDatetime = None
    updated_on: opMxDatetime = None
    updated_user: opMxString = None
    file_name: Union[MxString, None] = None
    directory: Union[MxString, None] = None
    taken_date: Union[MxDatetime, None] = None
    original_taken_date: Union[MxDatetime, None] = None
    modified_date: Union[MxDatetime, None] = None
    device_name: Union[MxString, None] = None
    caption: Union[MxString, None] = None
    ranking: MxInteger
    longitude: Union[MxFloat, None] = None
    latitude: Union[MxFloat, None] = None
    width: Union[MxInteger, None] = None
    height: Union[MxInteger, None] = None
    location: Union[MxString, None] = None
    rotation: Union[MxString, None] = None
    import_source: Union[MxString, None] = None
    media_type: MxString
    imported_date: Union[MxDatetime, None] = None
    media_length: Union[MxInteger, None] = None
    tag_list: Union[MxString, None] = None
    metadata: Union[MxMemo, None] = None
    session_id: Union[int, None] = None
    user_id: Union[int, None] = None
#                                 '*** Start Custom Code snap
#                                 '*** End Custom Code
	
class User(BaseModel):
    id: opMxInteger = None
    created_on: opMxDatetime = None
    updated_on: opMxDatetime = None
    updated_user: opMxString = None
    name: MxString
    hint: Union[MxString, None] = None
#                                 '*** Start Custom Code user
#                                 '*** End Custom Code
	

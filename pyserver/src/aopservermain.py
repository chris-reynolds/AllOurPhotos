# Generated by Maxim from fastapi.txt 
# Chris Reynolds on 25-Oct-2023 07:54:09
from fastapi import FastAPI, HTTPException, Request,Response, File, UploadFile
import mysql.connector
import json
import shutil
from PIL import Image,ExifTags,TiffImagePlugin
# from PIL.ExifTags import TAGS
import io
from datetime import datetime
from src.aopmodel import *
from src.geo import dmsToDeg,getLocation,trimLocation
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import FileResponse
#                                 '*** Start Custom Code importing

from fastapi.staticfiles import StaticFiles
#from fastapi.middleware.cors import CORSMiddleware
#from fastapi.responses import FileResponse
import os
import typing

MxString = str
MxDatetime = float
MxFloat = float
MxInteger = int
MxMemo = str
opMxString = str | None
opMxDatetime = datetime | None
opMxFloat = float | None
opMxInteger = int | None
opMxMemo = str | None
#                                 '*** End Custom Code


# Configure the MySQL database connection
config = json.load(open('config.json'))

# Create a MySQL connection pool
connection_pool = mysql.connector.pooling.MySQLConnectionPool(autocommit=True,pool_name="mypool", pool_size=10, pool_reset_session=True, **config['db'])

app = FastAPI()

#                                 '*** Start Custom Code custom routes
origins = [
    "http://127.0.0.1",
    "http://127.0.0.1:*",
    "http://localhost",
    "http://localhost:*",
]

ROOT_DIR = 'c:\\data\\photos\\'

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"], # origins,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.get('/hello')
async def hello():
    return 'hello aop'

@app.get('/ses/{user}/{password}/{source}')
async def makeSession(response: Response, user,password,source):
    source = "''".join(source.split("'"))
    sqlText = f"select spsessioncreate('{user}','{password}','{source}') as sessionid"
    rows = raw_sql(sqlText)
    sessionid = rows[0]['sessionid']  
    if sessionid < 0:
        response.delete_cookie (key='jam')
    else:   
        response.set_cookie (key='jam', value=f"{sessionid}")
#    sess = temp   # todo put in array
    return {"jam":f"{sessionid}" }     # f"{session.id}"}

@app.get('/find/{key}')
async def find(request: Request, key:str):
#    (updated_user,user_id) = username_and_id(request)
    queryList = config['find']
    if queryList == None or not key in queryList:
        raise HTTPException(status_code=404,detail='not found in line')
    sql = queryList[key]
    valueMap = dict(request.query_params)
    for key in valueMap:
        sql = sql.replace('@'+key,valueMap[key])
    return raw_sql(sql,asDictionary=False)

@app.post('/upload2/{modified}/{filename}/{sourceDevice}')
async def uploader(modified: str, filename: str, sourceDevice: str, myfile:UploadFile): #modified: str,filename: str, 
    request_object_content = await myfile.read()
    mediaLength = len(request_object_content)
    img = Image.open(io.BytesIO(request_object_content))
    img_exif = img.getexif()
    await myfile.seek(0)  # rest file cursor to get get full copy after reading exif
    taken = img_exif.get(306)  #DateTime
    date_original = img_exif.get(36867)  #DateTimeOriginal
    takendate = datetime.strptime(date_original or taken or modified,'%Y:%m:%d %H:%M:%S')
    monthDir = takendate.strftime('%Y-%m')
    modified_ts = datetime.strptime(modified,'%Y:%m:%d %H:%M:%S').timestamp()
#    myfile: UploadFile = aform.get('myfile')
    print(f"uploading ({modified})")
    targetFile = ROOT_DIR+monthDir+'\\'+filename
    targetThumbnail = ROOT_DIR+monthDir+'\\thumbnails\\'+filename
    targetMetadata = ROOT_DIR+monthDir+'\\metadata\\' +filename +'.json'
    if not os.path.exists(targetFile):
      with open(targetFile, "wb") as buffer:
        shutil.copyfileobj(myfile.file, buffer)
      os.utime(targetFile, (modified_ts, modified_ts))
    if not os.path.exists(targetThumbnail):
        makeThumbnail(img,img_exif,targetThumbnail)
    filteredMetadata: dict[str,str] = filterMetadata(img_exif)
    if not os.path.exists(targetMetadata):
        with open(targetMetadata, 'w') as targ:
            json.dump(filteredMetadata, targ, sort_keys=True, ensure_ascii=False, indent=4)
    await makeDatabaseRow(img,filteredMetadata,sourceDevice,monthDir,filename,takendate,modified,mediaLength) 
    print(f"uploaded ({modified})")
    return f"uploaded ({modified} {targetFile})"
    
def makeThumbnail(image: Image.Image, imageExif: Image.Exif,target: str):
    origWidth = image.width
    origHeight = image.height
    isLandscape: bool = origWidth>origHeight
    targetSize = {'width':640,'height':480} if isLandscape else {'width':480,'height':640}
    scale = min(origWidth/targetSize['width'],origHeight/targetSize['height'])
    newSize = int(origWidth/scale),int(origHeight/scale)
    image.thumbnail(newSize,Image.Resampling.LANCZOS)
    image.save(target,quality=50)
    return True


def filterMetadata(imageExif: Image.Exif) -> dict[str,str]:
    def exif_cast(v):
        if isinstance(v, TiffImagePlugin.IFDRational):
            return float(v)
        elif isinstance(v, tuple):
            return tuple(exif_cast(t) for t in v)
        elif isinstance(v, bytes):
            return v.decode(errors="replace")
        elif isinstance(v, dict):
            for kk, vv in v.items():
                v[kk] = exif_cast(vv)
            return v
        else: 
            return v
    result = {}
    for keyid,value in imageExif.items():
        value2 = exif_cast(value)
        tagName = ExifTags.TAGS.get(keyid,keyid)
        if (not value2 is str) or len(value2)<100:
            result[tagName] = value2
    return result
 

async def makeDatabaseRow(img: Image.Image,filteredExif: dict[str,str], sourceDevice: str, monthDir: str,filename: str,takenDate: datetime,modified: str, mediaLength: int):
      model = filteredExif.get('Model',None)
      deviceName: str = model or sourceDevice or 'No Device';
      importSource: str = sourceDevice or model or 'No source';
      newSnap = Snap()
      newSnap.file_name = filename
      newSnap.directory = monthDir
      newSnap.width = img.width
      newSnap.height = img.height
      newSnap.taken_date = takenDate
      newSnap.modified_date = datetime.strptime(modified,'%Y:%m:%d %H:%M:%S')
      newSnap.device_name = deviceName
      newSnap.rotation = '0' 
      newSnap.import_source = importSource
      newSnap.imported_date = datetime.now()

      software = filteredExif.get('device.software','').lower()
      if 'scan' in software:
        newSnap.import_source = (newSnap.import_source or '')  + ' scanned';
      newSnap.original_taken_date = newSnap.taken_date;
      # checkl for duplicate
      newSnap.media_length = mediaLength
      if filteredExif.get('GPSInfo',False):
        newSnap.latitude,newSnap.longitude = dmsToDeg(filteredExif['GPSInfo'])
      if (newSnap.latitude != None and abs(newSnap.latitude) > 1e-6):
        location = await getLocation(newSnap.longitude or 0, newSnap.latitude);
        if (location != None):
            newSnap.location = trimLocation(location);
        print('found location : ${newSnap.location}');
      

def raw_sql(sqlText: str, values = None, asDictionary: bool = True):
    try:
        with connection_pool.get_connection() as connection:
          with connection.cursor(dictionary=asDictionary) as cursor:
            cursor.execute(sqlText,values)
            result = cursor.fetchall()
#            cursor.commit()
        return result
    except Exception as ex:
        print("Error:", ex)
        raise HTTPException(status_code=500, detail=f"{ex} for {sqlText}")

user_list = raw_sql('select * from aopusers')

def get_session_from_request(request: Request) -> Session:
    jam = None
    preserve = request.headers['Preserve']
    if preserve != None:
        jam1 = json.loads(preserve)
        jam = jam1['jam']
        #    jam = request.cookies.get('jam')
    if jam == None : raise HTTPException(status_code=403,detail='No musicians')
    return get_session(request,int(jam))    # type: ignore



def get_user_from_session(session: Session) -> User:
    userId = session.user_id
    maybeUser: dict | None = next((d for d in user_list if d['id'] == userId), None)
    if maybeUser == None: raise Exception('user not found')
    return User(**maybeUser)

def username_and_id(request: Request):
    try:
        session = get_session_from_request(request)
        current_user = get_user_from_session(session)
        return (current_user.name, current_user.id)
    except HTTPException:
        raise
    except Exception as ex:
        raise HTTPException(status_code=403, detail=f"{ex}")
    
@app.get('/photos/{aPath:path}')
def photos(request: Request,aPath:str):
    fullFileName = config['photos']+aPath
    #print(fullFileName)
    cacheHeaders: dict[str,str] = {}
    if aPath.lower().endswith('txt'):
        cacheHeaders['Cache-Control'] = 'no-cache, no-store, must-revalidate'
        cacheHeaders['Pragma'] = 'no-cache'
        cacheHeaders['Expires'] = '0'
    if os.path.isfile(fullFileName):
        return FileResponse(path=fullFileName,headers=cacheHeaders)
    else:
        raise HTTPException(status_code=404,detail=f"'{aPath}' is not found.")

@app.put('/photos/{aPath:path}')
async def photos_put(request: Request,aPath:str):
    fullFileName = config['photos']+aPath
    print('photos_put '+fullFileName)
    if os.path.isfile(fullFileName):
      contents: bytes = await request.body()
      print(len(contents))
      with open(fullFileName, "wb") as binFile:
        binFile.write(contents)
    else:
        raise HTTPException(status_code=404,detail=f"'{aPath}' is not found.")


#                                 '*** End Custom Code

# API route to create a new album
@app.post("/albums", response_model=Album)
def create_album(request:Request, album: Album) -> Album:
    try:
        (album.updated_user,user_id) = username_and_id(request)
        if hasattr(album,'user_id'): album.user_id = user_id 
        query = "INSERT INTO aopalbums (created_on,updated_on,updated_user,name,description,first_date,last_date,user_id) VALUES (%s,%s,%s,%s,%s,%s,%s,%s)"
        values = (datetime.now(),datetime.now(),album.updated_user,album.name,album.description,album.first_date,album.last_date,album.user_id)
        thisid = -1
        with connection_pool.get_connection() as conn:
            with conn.cursor() as cursor:
                cursor.execute(query, values)
                conn.commit()
                cursor.execute('select last_insert_id()')
                thisid = cursor.fetchone()[0]
                print(f'inserted Album {thisid}')
        return get_album(request, thisid)
    except HTTPException: raise
    except Exception as ex:
        exmess: str = str(ex)
        print("Error:", exmess)
        if exmess.find('Duplicate entry')>0:
            raise HTTPException(status_code=409, detail=f"{ex}")
        else:
            raise HTTPException(status_code=500, detail=f"{ex}")

@app.get("/albums/{id}", response_model=Album)
def get_album(request:Request, id: int) -> Album:
    result = get_albums(request,where=f'id={id}')
    if result == None or result == []:
        raise HTTPException(status_code=404, detail="Album not found")
    else:
        return result[0]

# API route to get some albums
@app.get("/albums/", response_model=List[Album])
def get_albums(request:Request, where: str = '1=0', orderby: str = 'id', limit: int = 1001, offset: int = 0) -> List[Album]:
    session: Session = get_session_from_request(request) 
    queryText = f"SELECT * FROM aopalbums where {where} order by {orderby}  LIMIT {limit} OFFSET {offset} "
    try:
        with connection_pool.get_connection() as connection:
          with connection.cursor(dictionary=True) as cursor:
            cursor.execute(queryText)
            rows = cursor.fetchall()
            albums = [Album(**row) for row in rows]
        return albums
    except HTTPException: raise
    except Exception as ex:
        print("Error:", ex)
        raise HTTPException(status_code=500, detail=f"{ex}")


# API route to delete a album
@app.delete("/albums/{id}", response_model=Album)
def delete_album(request:Request, id: int):
    try:
        (updated_user,user_id) = username_and_id(request)
        oldAlbum = get_album(request,id)
        query = "DELETE FROM aopalbums WHERE id = %s"
        with connection_pool.get_connection() as connection:
          with connection.cursor() as cursor:          
            cursor.execute(query, (id,))  # Now Delete the album
        return oldAlbum 
    except HTTPException: raise
    except Exception as ex:
        print("Error:", ex)
        raise HTTPException(status_code=500, detail=f"{ex}")

# API route to update a album
@app.put("/albums", response_model=Album)
def update_album(request:Request, newAlbum: Album) -> Album:
    try:
        thisId: int = newAlbum.id # type: ignore
        (updating_user,user_id) = username_and_id(request)
        oldAlbum = get_album(request,thisId)
        last_updated_on = oldAlbum.updated_on
        query = "update aopalbums set   name=%s, description=%s, first_date=%s, last_date=%s, user_id= %s," 
        query += "updated_on=%s, updated_user=%s WHERE id = %s and updated_on = %s"
        values = (newAlbum.name, newAlbum.description, newAlbum.first_date, newAlbum.last_date, newAlbum.user_id,datetime.now(), updating_user, thisId, oldAlbum.updated_on)
        with connection_pool.get_connection() as connection:
          with connection.cursor() as cursor:          
            cursor.execute(query, values)  # Now update the album
#            if cursor.rowcount == 0: raise HTTPException(
        return get_album(request,thisId)   #refresh from db and return to client
    except HTTPException: raise
    except Exception as ex:
        print("Error:", ex)
        raise HTTPException(status_code=500, detail=f"{ex}")


# API route to create a new albumItem
@app.post("/album_items", response_model=AlbumItem)
def create_albumItem(request:Request, albumItem: AlbumItem) -> AlbumItem:
    try:
        (albumItem.updated_user,user_id) = username_and_id(request)
        if hasattr(albumItem,'user_id'): albumItem.user_id = user_id 
        query = "INSERT INTO aopalbum_items (created_on,updated_on,updated_user,album_id,snap_id) VALUES (%s,%s,%s,%s,%s)"
        values = (datetime.now(),datetime.now(),albumItem.updated_user,albumItem.album_id,albumItem.snap_id)
        thisid = -1
        with connection_pool.get_connection() as conn:
            with conn.cursor() as cursor:
                cursor.execute(query, values)
                conn.commit()
                cursor.execute('select last_insert_id()')
                thisid = cursor.fetchone()[0]
                print(f'inserted AlbumItem {thisid}')
        return get_albumItem(request, thisid)
    except HTTPException: raise
    except Exception as ex:
        exmess: str = str(ex)
        print("Error:", exmess)
        if exmess.find('Duplicate entry')>0:
            raise HTTPException(status_code=409, detail=f"{ex}")
        else:
            raise HTTPException(status_code=500, detail=f"{ex}")

@app.get("/album_items/{id}", response_model=AlbumItem)
def get_albumItem(request:Request, id: int) -> AlbumItem:
    result = get_albumItems(request,where=f'id={id}')
    if result == None or result == []:
        raise HTTPException(status_code=404, detail="AlbumItem not found")
    else:
        return result[0]

# API route to get some albumItems
@app.get("/album_items/", response_model=List[AlbumItem])
def get_albumItems(request:Request, where: str = '1=0', orderby: str = 'id', limit: int = 1001, offset: int = 0) -> List[AlbumItem]:
    session: Session = get_session_from_request(request) 
    queryText = f"SELECT * FROM aopalbum_items where {where} order by {orderby}  LIMIT {limit} OFFSET {offset} "
    try:
        with connection_pool.get_connection() as connection:
          with connection.cursor(dictionary=True) as cursor:
            cursor.execute(queryText)
            rows = cursor.fetchall()
            albumItems = [AlbumItem(**row) for row in rows]
        return albumItems
    except HTTPException: raise
    except Exception as ex:
        print("Error:", ex)
        raise HTTPException(status_code=500, detail=f"{ex}")


# API route to delete a albumItem
@app.delete("/album_items/{id}", response_model=AlbumItem)
def delete_albumItem(request:Request, id: int):
    try:
        (updated_user,user_id) = username_and_id(request)
        oldAlbumItem = get_albumItem(request,id)
        query = "DELETE FROM aopalbum_items WHERE id = %s"
        with connection_pool.get_connection() as connection:
          with connection.cursor() as cursor:          
            cursor.execute(query, (id,))  # Now Delete the albumItem
        return oldAlbumItem 
    except HTTPException: raise
    except Exception as ex:
        print("Error:", ex)
        raise HTTPException(status_code=500, detail=f"{ex}")

# API route to update a albumItem
@app.put("/album_items", response_model=AlbumItem)
def update_albumItem(request:Request, newAlbumItem: AlbumItem) -> AlbumItem:
    try:
        thisId: int = newAlbumItem.id # type: ignore
        (updating_user,user_id) = username_and_id(request)
        oldAlbumItem = get_albumItem(request,thisId)
        last_updated_on = oldAlbumItem.updated_on
        query = "update aopalbum_items set   album_id= %s,snap_id= %s," 
        query += "updated_on=%s, updated_user=%s WHERE id = %s and updated_on = %s"
        values = (newAlbumItem.album_id,newAlbumItem.snap_id,datetime.now(), updating_user, thisId, oldAlbumItem.updated_on)
        with connection_pool.get_connection() as connection:
          with connection.cursor() as cursor:          
            cursor.execute(query, values)  # Now update the albumItem
#            if cursor.rowcount == 0: raise HTTPException(
        return get_albumItem(request,thisId)   #refresh from db and return to client
    except HTTPException: raise
    except Exception as ex:
        print("Error:", ex)
        raise HTTPException(status_code=500, detail=f"{ex}")


# API route to create a new session
@app.post("/sessions", response_model=Session)
def create_session(request:Request, session: Session) -> Session:
    try:
        (session.updated_user,user_id) = username_and_id(request)
        if hasattr(session,'user_id'): session.user_id = user_id 
        query = "INSERT INTO aopsessions (created_on,updated_on,updated_user,start_date,end_date,source,user_id) VALUES (%s,%s,%s,%s,%s,%s,%s)"
        values = (datetime.now(),datetime.now(),session.updated_user,session.start_date,session.end_date,session.source,session.user_id)
        thisid = -1
        with connection_pool.get_connection() as conn:
            with conn.cursor() as cursor:
                cursor.execute(query, values)
                conn.commit()
                cursor.execute('select last_insert_id()')
                thisid = cursor.fetchone()[0]
                print(f'inserted Session {thisid}')
        return get_session(request, thisid)
    except HTTPException: raise
    except Exception as ex:
        exmess: str = str(ex)
        print("Error:", exmess)
        if exmess.find('Duplicate entry')>0:
            raise HTTPException(status_code=409, detail=f"{ex}")
        else:
            raise HTTPException(status_code=500, detail=f"{ex}")

@app.get("/sessions/{id}", response_model=Session)
def get_session(request:Request, id: int) -> Session:
    result = get_sessions(request,where=f'id={id}')
    if result == None or result == []:
        raise HTTPException(status_code=404, detail="Session not found")
    else:
        return result[0]

# API route to get some sessions
@app.get("/sessions/", response_model=List[Session])
def get_sessions(request:Request, where: str = '1=0', orderby: str = 'id', limit: int = 1001, offset: int = 0) -> List[Session]:
    queryText = f"SELECT * FROM aopsessions where {where} order by {orderby}  LIMIT {limit} OFFSET {offset} "
    try:
        with connection_pool.get_connection() as connection:
          with connection.cursor(dictionary=True) as cursor:
            cursor.execute(queryText)
            rows = cursor.fetchall()
            sessions = [Session(**row) for row in rows]
        return sessions
    except HTTPException: raise
    except Exception as ex:
        print("Error:", ex)
        raise HTTPException(status_code=500, detail=f"{ex}")


# API route to delete a session
@app.delete("/sessions/{id}", response_model=Session)
def delete_session(request:Request, id: int):
    try:
        (updated_user,user_id) = username_and_id(request)
        oldSession = get_session(request,id)
        query = "DELETE FROM aopsessions WHERE id = %s"
        with connection_pool.get_connection() as connection:
          with connection.cursor() as cursor:          
            cursor.execute(query, (id,))  # Now Delete the session
        return oldSession 
    except HTTPException: raise
    except Exception as ex:
        print("Error:", ex)
        raise HTTPException(status_code=500, detail=f"{ex}")

# API route to update a session
@app.put("/sessions", response_model=Session)
def update_session(request:Request, newSession: Session) -> Session:
    try:
        thisId: int = newSession.id # type: ignore
        (updating_user,user_id) = username_and_id(request)
        oldSession = get_session(request,thisId)
        last_updated_on = oldSession.updated_on
        query = "update aopsessions set   start_date=%s, end_date=%s, source=%s, user_id= %s," 
        query += "updated_on=%s, updated_user=%s WHERE id = %s and updated_on = %s"
        values = (newSession.start_date, newSession.end_date, newSession.source, newSession.user_id,datetime.now(), updating_user, thisId, oldSession.updated_on)
        with connection_pool.get_connection() as connection:
          with connection.cursor() as cursor:          
            cursor.execute(query, values)  # Now update the session
#            if cursor.rowcount == 0: raise HTTPException(
        return get_session(request,thisId)   #refresh from db and return to client
    except HTTPException: raise
    except Exception as ex:
        print("Error:", ex)
        raise HTTPException(status_code=500, detail=f"{ex}")


# API route to create a new snap
@app.post("/snaps", response_model=Snap)
def create_snap(request:Request, snap: Snap) -> Snap:
    try:
        (snap.updated_user,user_id) = username_and_id(request)
        if hasattr(snap,'user_id'): snap.user_id = user_id 
        query = "INSERT INTO aopsnaps (created_on,updated_on,updated_user,file_name,directory,taken_date,original_taken_date,modified_date,device_name,caption,ranking,longitude,latitude,width,height,location,rotation,import_source,media_type,imported_date,media_length,tag_list,metadata,session_id,user_id) VALUES (%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s)"
        values = (datetime.now(),datetime.now(),snap.updated_user,snap.file_name,snap.directory,snap.taken_date,snap.original_taken_date,snap.modified_date,snap.device_name,snap.caption,snap.ranking,snap.longitude,snap.latitude,snap.width,snap.height,snap.location,snap.rotation,snap.import_source,snap.media_type,snap.imported_date,snap.media_length,snap.tag_list,snap.metadata,snap.session_id,snap.user_id)
        thisid = -1
        with connection_pool.get_connection() as conn:
            with conn.cursor() as cursor:
                cursor.execute(query, values)
                conn.commit()
                cursor.execute('select last_insert_id()')
                thisid = cursor.fetchone()[0]
                print(f'inserted Snap {thisid}')
        return get_snap(request, thisid)
    except HTTPException: raise
    except Exception as ex:
        exmess: str = str(ex)
        print("Error:", exmess)
        if exmess.find('Duplicate entry')>0:
            raise HTTPException(status_code=409, detail=f"{ex}")
        else:
            raise HTTPException(status_code=500, detail=f"{ex}")

@app.get("/snaps/{id}", response_model=Snap)
def get_snap(request:Request, id: int) -> Snap:
    result = get_snaps(request,where=f'id={id}')
    if result == None or result == []:
        raise HTTPException(status_code=404, detail="Snap not found")
    else:
        return result[0]

# API route to get some snaps
@app.get("/snaps/", response_model=List[Snap])
def get_snaps(request:Request, where: str = '1=0', orderby: str = 'id', limit: int = 1001, offset: int = 0) -> List[Snap]:
    session: Session = get_session_from_request(request) 
    queryText = f"SELECT * FROM aopsnaps where {where} order by {orderby}  LIMIT {limit} OFFSET {offset} "
    try:
        with connection_pool.get_connection() as connection:
          with connection.cursor(dictionary=True) as cursor:
            cursor.execute(queryText)
            rows = cursor.fetchall()
            snaps = [Snap(**row) for row in rows]
        return snaps
    except HTTPException: raise
    except Exception as ex:
        print("Error:", ex)
        raise HTTPException(status_code=500, detail=f"{ex}")


# API route to delete a snap
@app.delete("/snaps/{id}", response_model=Snap)
def delete_snap(request:Request, id: int):
    try:
        (updated_user,user_id) = username_and_id(request)
        oldSnap = get_snap(request,id)
        query = "DELETE FROM aopsnaps WHERE id = %s"
        with connection_pool.get_connection() as connection:
          with connection.cursor() as cursor:          
            cursor.execute(query, (id,))  # Now Delete the snap
        return oldSnap 
    except HTTPException: raise
    except Exception as ex:
        print("Error:", ex)
        raise HTTPException(status_code=500, detail=f"{ex}")

# API route to update a snap
@app.put("/snaps", response_model=Snap)
def update_snap(request:Request, newSnap: Snap) -> Snap:
    try:
        thisId: int = newSnap.id # type: ignore
        (updating_user,user_id) = username_and_id(request)
        oldSnap = get_snap(request,thisId)
        last_updated_on = oldSnap.updated_on
        query = "update aopsnaps set   file_name=%s, directory=%s, taken_date=%s, original_taken_date=%s, modified_date=%s, device_name=%s, caption=%s, ranking=%s, longitude=%s, latitude=%s, width=%s, height=%s, location=%s, rotation=%s, import_source=%s, media_type=%s, imported_date=%s, media_length=%s, tag_list=%s, metadata=%s, session_id= %s,user_id= %s," 
        query += "updated_on=%s, updated_user=%s WHERE id = %s and updated_on = %s"
        values = (newSnap.file_name, newSnap.directory, newSnap.taken_date, newSnap.original_taken_date, newSnap.modified_date, newSnap.device_name, newSnap.caption, newSnap.ranking, newSnap.longitude, newSnap.latitude, newSnap.width, newSnap.height, newSnap.location, newSnap.rotation, newSnap.import_source, newSnap.media_type, newSnap.imported_date, newSnap.media_length, newSnap.tag_list, newSnap.metadata, newSnap.session_id,newSnap.user_id,datetime.now(), updating_user, thisId, oldSnap.updated_on)
        with connection_pool.get_connection() as connection:
          with connection.cursor() as cursor:          
            cursor.execute(query, values)  # Now update the snap
#            if cursor.rowcount == 0: raise HTTPException(
        return get_snap(request,thisId)   #refresh from db and return to client
    except HTTPException: raise
    except Exception as ex:
        print("Error:", ex)
        raise HTTPException(status_code=500, detail=f"{ex}")


# API route to create a new user
@app.post("/users", response_model=User)
def create_user(request:Request, user: User) -> User:
    try:
        (user.updated_user,user_id) = username_and_id(request)
        if hasattr(user,'user_id'): user.user_id = user_id 
        query = "INSERT INTO aopusers (created_on,updated_on,updated_user,name,hint) VALUES (%s,%s,%s,%s,%s)"
        values = (datetime.now(),datetime.now(),user.updated_user,user.name,user.hint)
        thisid = -1
        with connection_pool.get_connection() as conn:
            with conn.cursor() as cursor:
                cursor.execute(query, values)
                conn.commit()
                cursor.execute('select last_insert_id()')
                thisid = cursor.fetchone()[0]
                print(f'inserted User {thisid}')
        return get_user(request, thisid)
    except HTTPException: raise
    except Exception as ex:
        exmess: str = str(ex)
        print("Error:", exmess)
        if exmess.find('Duplicate entry')>0:
            raise HTTPException(status_code=409, detail=f"{ex}")
        else:
            raise HTTPException(status_code=500, detail=f"{ex}")

@app.get("/users/{id}", response_model=User)
def get_user(request:Request, id: int) -> User:
    result = get_users(request,where=f'id={id}')
    if result == None or result == []:
        raise HTTPException(status_code=404, detail="User not found")
    else:
        return result[0]

# API route to get some users
@app.get("/users/", response_model=List[User])
def get_users(request:Request, where: str = '1=0', orderby: str = 'id', limit: int = 1001, offset: int = 0) -> List[User]:
    session: Session = get_session_from_request(request) 
    queryText = f"SELECT * FROM aopusers where {where} order by {orderby}  LIMIT {limit} OFFSET {offset} "
    try:
        with connection_pool.get_connection() as connection:
          with connection.cursor(dictionary=True) as cursor:
            cursor.execute(queryText)
            rows = cursor.fetchall()
            users = [User(**row) for row in rows]
        return users
    except HTTPException: raise
    except Exception as ex:
        print("Error:", ex)
        raise HTTPException(status_code=500, detail=f"{ex}")


# API route to delete a user
@app.delete("/users/{id}", response_model=User)
def delete_user(request:Request, id: int):
    try:
        (updated_user,user_id) = username_and_id(request)
        oldUser = get_user(request,id)
        query = "DELETE FROM aopusers WHERE id = %s"
        with connection_pool.get_connection() as connection:
          with connection.cursor() as cursor:          
            cursor.execute(query, (id,))  # Now Delete the user
        return oldUser 
    except HTTPException: raise
    except Exception as ex:
        print("Error:", ex)
        raise HTTPException(status_code=500, detail=f"{ex}")

# API route to update a user
@app.put("/users", response_model=User)
def update_user(request:Request, newUser: User) -> User:
    try:
        thisId: int = newUser.id # type: ignore
        (updating_user,user_id) = username_and_id(request)
        oldUser = get_user(request,thisId)
        last_updated_on = oldUser.updated_on
        query = "update aopusers set   name=%s, hint=%s, " 
        query += "updated_on=%s, updated_user=%s WHERE id = %s and updated_on = %s"
        values = (newUser.name, newUser.hint, datetime.now(), updating_user, thisId, oldUser.updated_on)
        with connection_pool.get_connection() as connection:
          with connection.cursor() as cursor:          
            cursor.execute(query, values)  # Now update the user
#            if cursor.rowcount == 0: raise HTTPException(
        return get_user(request,thisId)   #refresh from db and return to client
    except HTTPException: raise
    except Exception as ex:
        print("Error:", ex)
        raise HTTPException(status_code=500, detail=f"{ex}")


app.mount("/", StaticFiles(directory=config['frontend'],html=True,follow_symlink=True), name="frontend")
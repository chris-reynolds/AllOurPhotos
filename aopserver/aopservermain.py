import uvicorn
from aopdb import DBSession
from logger import iprint,eprint
import json
from fastapi import FastAPI,HTTPException
from fastapi.staticfiles import StaticFiles

# todo : setup api server
# todo : implement static
# implement fetchsome - no parameters
# 
app = FastAPI()

config = json.load(open('config.json'))
condb = DBSession(config['db'])


app.mount('/photos',StaticFiles(directory='c:\\data\\photos'))

iprint('albums=')
iprint(condb.fetch('select id from aopalbums'))

@app.get("/")
async def root():
    return {"message": "Hello World"}

@app.get('/api/albums')
async def albums():
  return condb.fetch('select id from aopalbums')

@app.get('/api/{entityName}/{id}')
async def getById(entityName,id):
  if not DBSession.entityIsValid(entityName):
     raise HTTPException(status_code=404, detail="Item REALLY not found")
  else:
    result = DBSession.fetch1(entityName,(id,))
    if result == None:
        raise HTTPException(status_code=404, detail="Item not found")
    else:
       return result

@app.get('/session/{user}/{password}/{source}')
async def session(user,password,source):
   return DBSession.makeSession(user,password,source)       

# del condb  # disconnect from database

iprint('done')

if __name__ == '__main__':
   uvicorn.run(app)
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
model =json.load(open('model.json'))
sess = DBSession(config['db'],model)


app.mount('/photos',StaticFiles(directory='c:\\data\\photos'))

iprint('albums=')
iprint(sess.fetch('select id from aopalbums'))

@app.get("/")
async def root():
    return {"message": "Hello World"}

@app.get('/api/albums')
async def albums():
  return session.db.fetch('select id from aopalbums')

@app.get('/api/{entityName}/{where}')
async def getById(entityName: str, where: str):
  if not sess.entityIsValid(entityName):
     raise HTTPException(status_code=404, detail="Item REALLY not found")
  else:
    if (where.isnumeric()):  where = 'id='+where   
    result = sess.fetch(entityName,where)
    if result == None:
        raise HTTPException(status_code=404, detail="Item not found")
    else:
       return result

@app.get('/ses/{user}/{password}/{source}')
async def session(user,password,source):
   return session.makeSession(user,password,source)       

# del session  # disconnect from database

iprint('done')

if __name__ == '__main__':
   uvicorn.run(app)
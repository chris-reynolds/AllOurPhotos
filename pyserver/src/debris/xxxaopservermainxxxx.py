# import uvicorn
from xxxaopdbxxxx import DBSession
#from logger import iprint,eprint
import json
from fastapi import FastAPI,HTTPException
from fastapi.staticfiles import StaticFiles

# todo : setup api server
# todo : implement static
# implement fetchsome - no parameters
# 

config = json.load(open('config.json'))
model =json.load(open('model.json'))

sess = DBSession(config['db'],model)

app = FastAPI()

app.mount('/photos',StaticFiles(directory='c:\\data\\photos'))


@app.get("/")
async def root():
    return {"message": "Hello World3"}

@app.get('/api/albums')
async def albums():
  return sess.fetch('aopalbums',where='1=1',columns='id,name')


@app.get('/api/{entityName}/{where}')
async def getById(entityName: str, where: str,orderby: str = 'created_on',columns: str = ''):
  if not sess.entityIsValid(entityName):
     raise HTTPException(status_code=404, detail="Item REALLY not found")
  else:
    if (where.isnumeric()):  where = 'id='+where   
    result = sess.fetch(entityName,where,orderby=orderby,columns=columns)
    if result == None or result == []:
        raise HTTPException(status_code=404, detail="Item not found")
    else:
       return result

@app.get('/ses/{user}/{password}/{source}')
async def makeSession(user,password,source):
   return sess.makeSession(user,password,source)       

# del session  # disconnect from database

print('loading complete')

# if __name__ == '__main__':
#   uvicorn.run(app)
import mysql.connector
from mysql.connector import Error
# from  logger import iprint,eprint 

'''
class DBSession():
    def __init__(self,config):
      self.id: int = 0
      self.db = SqlDatabase(config)
   
    def fetch(self,sqltext: str):
        if (self.id <= 0):  raise Exception('musicians required')
        return self.db.fetch(sqltext)
    
    def  makeSession(self,user:str,password:str,source:str): 
        self.id = 0
        sqltext = f"select spsessioncreate('{user}','{password}','{source}')"
        acursor =  self.db.checkedConnection().cursor()
        acursor.execute(sqltext)
        row =  acursor.fetchone()
        if row is not None:
          self.id = int(f"{row[0]}")  # just get first column
        acursor.close()
        print('session id is',self.id)
        return self
    
class SqlDatabase():
    def __init__(self,config):
        print('config is',config)
        self._config = config
        self.tryconnect()

    def __del__(self):
        if self.connection.is_connected():
            self.connection.close()
            print("MySQL connection is closed")

    def checkedConnection(self):
        if not self.connection.is_connected():
            self.tryconnect()
        if not self.connection.is_connected():
            raise Exception('Lost in space!!!!!!!!!!!!!!!!!!')
        return self.connection

    def fetch(self, sqltext: str):
        x = None
        with self.checkedConnection().cursor(dictionary=True) as acursor:
          acursor.execute(sqltext)
          x =  acursor.fetchall()
          acursor.close()
        return x       
   
    def tryconnect(self):
        try:
            self.connection = mysql.connector.connect(**self._config) 
            if self.connection.is_connected():
                db_Info = self.connection.get_server_info()
                record = self.fetch("select database();")
                print("You're connected to database: ", record, db_Info)
                #cursor.close()
        except Error as e:
            print("Error while connecting to MySQL", e)

'''
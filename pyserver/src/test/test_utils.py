from mysql.connector import Error
import os
import mysql.connector as mysql


_root_dir = 'c:/data/photos/'
_dbname = 'allourphotos_asus'
_connection : mysql.MySQLConnection|None = None

def init_env(uspw):
    setup_connection(uspw)

def setup_connection(uspw):
    if _connection is None:
        try:
            _connection = mysql.connect(
                host='localhost',
                user=uspw.U,
                passwd=uspw.P,
                database=_dbname
            )
            print("Connection to MySQL DB successful")
        except Error as e:
            print(f"The error '{e}' occurred")

def delete_row_by_filename_and_directory(file_name, directory):
    cursor = _connection.cursor()
    try:
        cursor.execute("DELETE FROM aopsnaps WHERE file_name = %s AND directory = %s", (file_name, directory))
        _connection.commit()
        print(f"Row with file_name '{file_name}' and directory '{directory}' deleted successfully")
    except Error as e:
        print(f"The error '{e}' occurred")
    finally:
        cursor.close()

ROOT_DIR = "/C:/Users/chris/projects/AllOurPhotos"

def remove_file(file_name, directory):
    file_path = os.path.join(ROOT_DIR, directory, file_name)
    if os.path.exists(file_path):
        try:
            os.remove(file_path)
            print(f"File '{file_path}' removed successfully")
        except Exception as e:
            print(f"An error occurred while trying to remove the file: {e}")

def clear_testdata():
    connection = DatabaseConnection.get_connection

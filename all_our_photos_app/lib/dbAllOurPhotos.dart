import 'dart:async';
//import 'dart:io';
import 'package:mysql1/mysql1.dart';


class DbAllOurPhotos {

  MySqlConnection _conn;

  void initConnection() async {
    if (_conn==null )
      _conn = await MySqlConnection.connect(new ConnectionSettings(
          host: '192.168.1.251', port: 3306, user: 'photos', password:'photos00', db: 'allourphotos'));
  }

  Future<dynamic> addImage(String name,int width,int height,List<int> picContents) async {
    // Insert some data
    await initConnection();
    var result = await _conn.query(
        'insert into aopimages (updated_user, file_name, directory, ranking, has_thumbnail, media) values (?, ?, ?, ?, ?, ?)',
        ['testuser', 'my filename', 'mydirectory', 3, 0, picContents]);
    print("Inserted row - aopimages id=${result.insertId}");
  } // addImage

  void close() {
    if (_conn!=null)
      _conn.close();
    _conn = null;
  }  // of close

}  // of DbAllOurPhotos
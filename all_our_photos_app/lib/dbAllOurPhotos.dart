import 'dart:async';
//import 'dart:io';
import 'package:mysql1/mysql1.dart';
import 'package:all_our_photos_app/classes.dart';

class DbAllOurPhotos {

  MySqlConnection _conn;

  void initConnection() async {
    //todo : get db connection/session parameters from local storage
    if (_conn==null ) {
      _conn = await MySqlConnection.connect(new ConnectionSettings(
          host: '192.168.1.251', port: 3306, user: 'photos', password:'photos00', db: 'allourphotos'));
      await _conn.query("select spsessioncreate('chris','chris00','aopDev')");
    }
  }

  Future<dynamic> addImage(Media item,List<int> picContents) async {
    // Insert some data
    await initConnection();
    var result = await _conn.query(
        'insert into aopimages ( file_name, width,height, taken_date, longitude, latitude, directory, ranking, has_thumbnail, media) '
            +'values ( ?, ?, ?, ?, ?, ?, ?, ?, ?, ? )',
        [ item.name, item.width, item.height, item.taken_date.toIso8601String(), item.longtitude, item.latitude,'mydirectory', 3, 0, picContents]);
    print("Inserted row - aopimages id=${result.insertId}");
  } // addImage

  void close() {
    if (_conn!=null)
      _conn.close();
    _conn = null;
  }  // of close

}  // of DbAllOurPhotos
import 'dart:async';
import 'package:mysql1/mysql1.dart';
import '../dart_common/Logger.dart' as Log;


MySqlConnection dbConn;

class DbAllOurPhotos {
  static Map _lastConfig;
  Future<int> initConnection(Map config) async {
    //todo : get db connection/session parameters from local storage
    if (dbConn==null ) {
      dbConn = await MySqlConnection.connect(new ConnectionSettings(
          host: config['dbhost'], port: int.parse(config['dbport']), user: config['dbuser'],
          password:config['dbpassword'], db: config['dbname']));
      Log.message('Database connection = ${config["dbname"]}');
      _lastConfig = config; // save for reconnect
    }
    return 1;
  } // future<int> forces us to use await with compile error

  Future<int> startSession(Map config) async {
    Results res = await dbConn.query("select spsessioncreate('${config['sesuser']}','${config['sespassword']}','${config['sesdevice']}')");
    Iterable spResult = res.first.asMap().values;
    return spResult.first as int;
  } // of startSession

  static Future<int> reconnect() async {
    if (dbConn!=null)
      dbConn.close();
    dbConn = null;
    var dbAop = DbAllOurPhotos();
    await dbAop.initConnection(_lastConfig);
    return await dbAop.startSession(_lastConfig);
  }
  /*
  Future<dynamic> addImage(Media item,List<int> picContents) async {
    // Insert some data
    await initConnection();
    var result = await dbConn.query(
        'insert into aopimages ( file_name, width,height, taken_date, longitude, latitude, directory, ranking, has_thumbnail, media) '
            +'values ( ?, ?, ?, ?, ?, ?, ?, ?, ?, ? )',
        [ item.name, item.width, item.height, item.taken_date.toIso8601String(), item.longtitude, item.latitude,'mydirectory', 3, 0, picContents]);
    print("Inserted row - aopimages id=${result.insertId}");
  } // addImage
*/
  void close() {
    if (dbConn!=null)
      dbConn.close();
    dbConn = null;
  }  // of close


}  // of DbAllOurPhotos



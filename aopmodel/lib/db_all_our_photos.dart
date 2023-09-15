/*
import 'dart:async';
import 'package:mysql1/mysql1.dart';
import 'package:aopcommon/aopcommon.dart';


MySqlConnection? dbConn;

class DbAllOurPhotos {
  static late Config _lastConfig;
  Future<int> initConnection(Config config) async {
    if (dbConn == null) {
      dbConn = await MySqlConnection.connect(ConnectionSettings(
          host: config['dbhost'],
          port: int.parse(config['dbport']),
          user: config['dbuser'],
          password: config['dbpassword'],
          db: config['dbname']));
      log.message(
          'Database connected to ${config["dbhost"]} ${config["dbname"]}');
      _lastConfig = config; // save for reconnect
    }
    return 1;
  } // future<int> forces us to use await with compile error

  Future<int> startSession(Config config) async {
    try {
      Results res = await dbConn!.query(
          "select spsessioncreate('${config['sesuser']}','${config['sespassword']}','${config['sesdevice']}')");
      Iterable spResult = res.first.asMap().values;
      int sessionid = (spResult.first as int?) ?? -999;
      if (sessionid <= 0) throw 'Bad sessionid';
      log.message('session created with id=$sessionid');
      return sessionid;
    } catch (ex) {
      throw "Failed to create aop session $ex";
    }
  } // of startSession

  static Future<int> reconnect() async {
    if (dbConn != null) dbConn!.close();
    dbConn = null;
    var dbAop = DbAllOurPhotos();
    await dbAop.initConnection(_lastConfig);
    await dbAop.startSession(_lastConfig);
    return 1;
  }

  void close() {
    if (dbConn != null) dbConn!.close();
    dbConn = null;
  } // of close
}  // of DbAllOurPhotos

*/

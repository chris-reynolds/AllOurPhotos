import 'dart:async';
import 'dart:convert';
import 'package:aopcommon/aopcommon.dart';
// import './dbAllOurPhotos.dart';
import 'package:http/http.dart' as http;

bool urlLogging = true;
int sessionId = 0;

String rootUrl = 'Unassigned'; //http://localhost:8000/';
String modelSessionid = 'unassigned';

abstract class DomainObject {
  DomainObject({required Map<String, dynamic> data});

  int? id;
  DateTime? createdOn;
  DateTime? updatedOn;
  String? updatedUser;
  List<String> lastErrors = [];

  bool get isValid => lastErrors.isEmpty;

  Future<void> validate() async {
    lastErrors = [];
  } // this writes to the lastErrors

  Future<void> save() async {
    throw Exception("todo save");
  }

  Map<String, dynamic> toMap();

  void fromMap(Map<String, dynamic> map);

  void fromRow(dynamic row) {
    String fld = '';
    try {
      fld = 'id';
      id = row[0];
      fld = 'createdOn';
      createdOn = row[1];
      fld = 'updatedOn';
      updatedOn = row[2];
      fld = 'updatedUser';
      updatedUser = row[3];
    } catch (ex) {
      throw Exception('Failed to assign field $fld : $ex');
    }
  } // from Row

  List<dynamic> toRow() {
    var result = [];
    result.add(id);
    result.add(createdOn);
    result.add(updatedOn);
    result.add(updatedUser);
    return result;
  } // to Row
} // of abstract class DomainObject

List<int?> idList(List<DomainObject> dobjList) {
  List<int?> result = [];
  for (var element in dobjList) {
    result.add(element.id);
  }
  return result;
} // of idList

class DOProvider<TDO extends DomainObject> {
  String tableName;
  List<String> columnList;
  late RestURLFactory urlStatements;
  http.Client client;
  Function newFn;

  List<TDO> toList(dynamic r) {
    // todo tighter declaration than dynamic
    var result = <TDO>[];
    for (var row in r) {
      TDO newDomainObject = (newFn() as TDO);
      newDomainObject.fromMap(row);
      result.add(newDomainObject);
    }
    return result;
  }

  DOProvider(this.tableName, this.columnList, this.newFn)
      : client = http.Client() {
    urlStatements = RestURLFactory(tableName);
  }

  Future<dynamic> _sendRequest(String verb, String url, {dynamic data}) async {
    try {
      if ((verb == 'post' || verb == 'put') && data == Null) {
        throw 'No data to send or bad verb';
      }
      if (!(url.startsWith('http'))) {
        url = '$rootUrl/$url';
      }
      log.message('Send Request : $verb $url');
      Map<String, String> headers = {
        'Accept': 'application/json',
        'Content-type': 'application/json',
        'Cookie': 'jam=$modelSessionid'
      };
      http.Response? response;
      switch (verb.toLowerCase()) {
        case 'get':
          response = await client.get(Uri.parse(url), headers: headers);
          break;
        case 'put':
          response = await client.put(Uri.parse(url),
              headers: headers,
              body: jsonEncode(data),
              encoding: Encoding.getByName('utf-8'));
          break;
        case 'post':
          response = await client.post(Uri.parse(url),
              headers: headers,
              body: jsonEncode(data),
              encoding: Encoding.getByName('utf-8'));
          break;
        case 'delete':
          response = await client.delete(Uri.parse(url),
              headers: headers,
              body: jsonEncode(data),
              encoding: Encoding.getByName('utf-8'));
          break;
      }
      log.message('Response status: ${response?.statusCode}');
      // log.message('Response body: ${response?.body}');
      switch (response?.statusCode) {
        case 200:
          //        var ss = response?.body;
          var xxx = jsonDecode(response?.body ?? '');
          return xxx;
        case 404:
          throw 'not found';
        default:
          throw 'server error ${response?.statusCode}\n ${response?.body} ';
      }
    } catch (error) {
      log.error('sendRequest error: $error');
      rethrow;
    }
  }

  Future<dynamic> rawRequest(String url, {String verb = 'get'}) async {
    return _sendRequest(verb, url);
  } // of queryWithReOpen

  Future<int?> save(TDO aDomainObject) async {
    String url, verb;
    try {
      List<dynamic> dataFields = aDomainObject.toRow();
      if (aDomainObject.id != null && aDomainObject.id! > 0) {
        (verb, url) = urlStatements.updateStatement(aDomainObject.id ?? 0);
      } else {
        (verb, url) = urlStatements.insertStatement();
      }
      if (urlLogging) log.message('save url : $url');
      dataFields.add(aDomainObject.id);
      var r = await _sendRequest(verb, url, data: dataFields);
      aDomainObject.fromMap(r);
      return aDomainObject.id;
    } catch (ex) {
      log.error('$ex');
      rethrow;
    }
  } // of save

  Future<TDO> get(int? id) async {
    if (id == null) throw "id is unavalable ";
    String verb, url;
    (verb, url) = urlStatements.getIdStatement(id);
    var r = _sendRequest(verb, url);
    TDO newDomainObject = (newFn() as TDO);
    newDomainObject.fromMap(r as Map<String, dynamic>);
    return newDomainObject;
  } //

  Future<List<TDO>> getWithFKey(String keyname, int? keyValue) async {
    String verb, url;
    (verb, url) = urlStatements.getSomeStatement('$keyname.eq.$keyValue');
    var r = await _sendRequest(verb, url);
    return toList(r);
  }

  Future<List<TDO>> getSome(String whereClause,
      {String orderBy = 'created_on'}) async {
    String verb, url;
    (verb, url) = urlStatements.getSomeStatement(whereClause, orderBy: orderBy);
    try {
      log.message('url:$verb: $url');
      var r = await _sendRequest(verb, url);
      return toList(r);
    } catch (ex) {
      log.error('$ex \n caused by $url');
      rethrow;
    }
  }

  Future<bool> delete(TDO aDomainObect) async {
    String verb, url;
    (verb, url) = urlStatements.deleteStatement(aDomainObect.id ?? 0);
    if (urlLogging) {
      log.message('Delete for $tableName id=${aDomainObect.id} ');
    }
    try {
      _sendRequest(verb, url);
      return true;
    } catch (ex) {
      log.error(ex.toString());
      throw Exception('Failed Delete for $tableName id=${aDomainObect.id} ');
    }
  } // of delete

  Future<dynamic> rawExecute(String sql, [List<dynamic>? params]) async {
    throw 'rawExecute not supported';
  } // of execute

  Future<void> refreshFromDb(TDO aDomainObject) async {
    String verb, url;
    (verb, url) = urlStatements.getIdStatement(aDomainObject.id ?? 0);
    var r = await _sendRequest(verb, url);
    aDomainObject.fromMap(r);
  } //
} // of DOProvider

class RestURLFactory {
  final String _tableName;

  RestURLFactory(this._tableName);

  (String, String) deleteStatement(int id) =>
      ('DELETE', '$rootUrl/$_tableName/$id');

  (String, String) insertStatement() => ('POST', '$rootUrl/$_tableName');

  (String, String) updateStatement(int id) =>
      ('PUT', '$rootUrl/$_tableName/$id');

  (String, String) getIdStatement(int id) =>
      ('GET', '$rootUrl/$_tableName/$id');

  (String, String) getSomeStatement(String whereClause,
          {String orderBy = 'created_on'}) =>
      ('GET', '$_tableName/?where=$whereClause&orderby=$orderBy');
} // of RestURLFactory

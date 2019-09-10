/*
  Created by chrisreynolds on 2019-09-09
  
  Purpose: 

*/
import 'dart:io';
import 'dart:convert';
import 'Config.dart';
import 'Logger.dart' as Log;

String get rootUrl => 'http://${config["dbhost"]}:3333';

class WebFile {
  String url;
  String contents = '';

  WebFile._(this.url) {} // private constructor
}

Future<WebFile> loadWebFile(String url, String defaultValue) async {
  if (!url.contains('http:')) url = rootUrl + '/' + url;
  final uri = Uri.parse(url);
  var httpClient = HttpClient();
  HttpClientRequest request;
  try {
    request = await httpClient.openUrl('GET', uri);
  } catch (ex) {
    Log.error(ex);
  }
  HttpClientResponse response = await request.close();
//  HttpResponse responseBody = await response.transform(utf8.decoder).join();
  //   print("Received $responseBody...");
  httpClient.close();
  WebFile result = WebFile._(url);
  if (response.statusCode != 200) {
    if (defaultValue == null) throw 'Failed to load ' + url;
    result.contents = defaultValue;
  } else
    await utf8.decoder.bind(response /*5*/).forEach((x) {
      result.contents += x;
    });
  return result;
}

Future<bool> saveWebFile(WebFile webFile, {bool silent: true}) async {
  HttpClientResponse response;
  try {
    final uri = Uri.parse(webFile.url);
    var httpClient = HttpClient();
    HttpClientRequest request;
    try {
      request = await httpClient.openUrl('PUT', uri);
      request.write(webFile.contents);
    } catch (ex) {
      Log.error(ex);
      return false;
    }
    response = await request.close();
    httpClient.close();
    if (response.statusCode != 200)
      throw response.reasonPhrase;
  } catch (ex) {
    String errMessage = 'Failed to save ${webFile.url} with reason ${response.reasonPhrase}';
    Log.error(errMessage);
    if (silent)
      return false;
    else
      rethrow;
  }
  return true;
} // of saveWebFile

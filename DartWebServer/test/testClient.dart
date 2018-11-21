
import 'dart:io';
import 'dart:convert';
import 'dart:async';
//import 'package:http/http.dart' as http;

main() async {
  print('starting');
  var url = Uri.parse("http://localhost:3333/2017-08/testClient.dart");
  var httpClient = HttpClient();
  var request = await httpClient.putUrl(url);
//  request.cookies.add(Cookie('aop','F71'));
  request.add(utf8.encode('blah3'));
  request.add(utf8.encode('blah3'));
  var response = await request.close();
  var data = await response.transform(utf8.decoder).toList();
  print('Response ${response.statusCode}: $data');
  httpClient.close();
}  // of main

Future<HttpClientResponse> foo() async {
  Map<String, dynamic> jsonMap = {
    'homeTeam': {'team': 'Team A'},
    'awayTeam': {'team': 'Team B'},
  };
  final _httpClient = HttpClient();
  final _host = 'http://localhost';
  final _port = 3333;
  String jsonString = json.encode(jsonMap); // encode map to json
  String paramName = 'param'; // give the post param a name
  String formBody = paramName + '=' + Uri.encodeQueryComponent(jsonString);
  List<int> bodyBytes = utf8.encode(formBody); // utf8 encode
  HttpClientRequest request = await _httpClient.post(_host, _port, '/a/b/c');
  // it's polite to send the body length to the server
  request.headers.set('Content-Length', bodyBytes.length.toString());
  // todo add other headers here
  request.add(bodyBytes);
  return await request.close();
}

import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;

main() async {
  print('starting');
  var url = Uri.parse("http://localhost:3333/2017-08/testClient.dart");
  var httpClient = HttpClient();
  var request = await httpClient.putUrl(url);
  request.cookies.add(Cookie('aop','F71'));
  request.
  var response = await request.close();
  var data = await response.transform(utf8.decoder).toList();
  print('Response ${response.statusCode}: $data');
  httpClient.close();
}  // of main
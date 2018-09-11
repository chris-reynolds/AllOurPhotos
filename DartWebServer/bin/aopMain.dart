import 'dart:io';
import 'dart:async';
import 'dart:process';

Future main(List<String> arguments) async {
    dynamic config = await loadConfig()
    final requests = await HttpServer.bind('localhost', 8888);
    await for (var request in requests) {
      if (!processRequest(request))
       break;
    }
    print('outer main');
    exitCode = 64;
    return;
  } // of main

  bool processRequest(HttpRequest request) {
    print('Got request for ${request.uri.path}');
    final response = request.response;
    if (request.uri.path == '/quit')
      return false;
    if (request.uri.path == '/dart') {
      response
        ..headers.contentType = ContentType(
          'text',
          'plain',
        )
        ..write('Hello from the server');
    } else {
      response.statusCode = HttpStatus.notFound;
    }
    response.close();
    return true;
  } // of process request

  dynamic loadConfig() async {
    dynamic result = {};
    String configFileName = __dirname + '\\aopConfig.json'
    if (fs.existsSync(configFileName )) {
    let contents= fs.readFileSync(configFileName,'utf8')
    result = _.merge(result,JSON.parse(contents));
    }
    return result;
  }
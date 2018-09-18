import 'dart:io';
import 'dart:async';
import 'dart:convert' show jsonDecode,utf8;
import 'package:http_server/http_server.dart';

HttpServer mainServer;
VirtualDirectory _staticFileRoot;
Map config;

Future main(List<String> arguments) async {
  try {
    if (arguments.length==0)
      throw 'Configuration file not found';
    config = await loadConfig(arguments[0]);
    int webServerPort = int.tryParse(config['webserver_port']) ?? 8888;
    mainServer = await loadServer(webServerPort, config['fileserver_root']);
    mainServer.listen(processRequest);
    print('AOP Server running on $webServerPort');
    return;
  } catch (ex) {
    print('Failed to load AllOurPhotos server : $ex');
    exit(16);
  } // of catch
} // of main

  Future<HttpServer> loadServer(int port, String rootPath) async {
    _staticFileRoot = new VirtualDirectory(rootPath)
      ..allowDirectoryListing = true;
    _staticFileRoot.directoryHandler = (dir, request) {
      var indexUri = Uri.file(dir.path).resolve('index.json');
      _staticFileRoot.serveFile(File(indexUri.toFilePath()), request);
    };
    return await HttpServer.bind('localhost',port);
  }  // of loadServer

  Future processRequest(HttpRequest request) async {
    print('Got request for ${request.uri.path}');
    final response = request.response;
    void plainResponse(int thisStatusCode,String text) {
      response
        ..statusCode = thisStatusCode
        ..headers.contentType = ContentType('text','plain')
        ..write(text);
      response.close();
    } // of plainResponse
    Cookie aopCookie;
    String cookieValue = response.cookies.length==0 ? 'NONE' : response.cookies[0].value;
    bool permissionDenied = securityCheck(cookieValue);
    if (request.method == 'GET') {
      if (request.uri.path.substring(0, 8) == '/located') {
        List<String> bits = request.uri.path.split('/');
        String newToken = bits.length == 4
            ? securityToken(bits[2], bits[3])
            : '';
        permissionDenied = (newToken == '');
        if (!permissionDenied) {
          response.cookies.clear();
          response.cookies.add(Cookie('aop', newToken));
          plainResponse(HttpStatus.accepted, 'Ready');
        }
      }
      if (request.uri.path == '/quit') {
        response
          ..headers.contentType = ContentType('text', 'plain')
          ..write('Goodbyte from the server');
        response.close();
        exit(0); // server abort
      } else if (request.uri.path == '/dart') {
        response
          ..headers.contentType = ContentType('text', 'plain')
          ..write('Hello from the server');
        response.close();
      } else if (permissionDenied) { // failed security check
        response
          ..statusCode = HttpStatus.unauthorized
          ..headers.contentType = ContentType('text', 'plain')
          ..write('Permission Denied');
        response.close();
      } else {
        await _staticFileRoot.serveRequest(request);
      }
    } else if (request.method == 'PUT') {
      String filePath = config['fileserver_root']+request.uri.toFilePath();
      HttpRequestBody body = await HttpBodyHandler.processRequest(request , );
      if (body.type == 'binary') {
        try {
          File(filePath).writeAsBytesSync(body.body, flush: true);
          plainResponse(200, 'Written ${request.uri.path}');
        } catch (ex) {
          plainResponse(500, 'Failed to write $filePath \n $ex');
        } // of catch
      } else
         plainResponse(400, 'Todo put non-binary $filePath');
    } else
      plainResponse(HttpStatus.methodNotAllowed, 'Invalid method ${request.method}');
  } // of process request

  Future<Map> loadConfig(String filename) async {
    if (!FileSystemEntity.isFileSync(filename))
      throw 'Invalid configuration filename';
    else {
      String configContents = File(filename).readAsStringSync(encoding: utf8);
      try {
        return jsonDecode(configContents);
      } catch(err) {
        throw 'Corrupt configuration file';
      } // of catch
    }
  }
  bool securityCheck(String token) {
     return token.contains('F71');  // TODO: security check
  } // of security check

  String securityToken(String username,String password) {
    int suffixHelp = 9;
    if (config['password.'+username]==password) {
      return DateTime.now().millisecondsSinceEpoch.toRadixString(13)
        +'F'+(8*suffixHelp-1).toString();
    } else {
      return ''; // failed
    }
  }  // of security token
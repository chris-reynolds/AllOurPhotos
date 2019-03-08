import 'dart:io';
import 'dart:async';
import 'dart:convert' show jsonDecode,utf8;
import 'package:http_server/http_server.dart';
import 'package:path/path.dart' as Path;

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
    // TODO: check rootpath file existance
    _staticFileRoot = new VirtualDirectory(rootPath)
      ..allowDirectoryListing = false;
//      ..allowDirectoryListing = true;
//    _staticFileRoot.directoryHandler = serveDirectory;
    return await HttpServer.bind(InternetAddress.anyIPv4,port);
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
    String cookieValue = response.cookies.length==0 ? 'NONE' : response.cookies[0].value;
    bool permissionDenied = securityCheck(cookieValue);
    if (request.method == 'GET') {
      if (request.uri.path.length>8 && request.uri.path.substring(0, 8) == '/located') {
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
/*
void serveDirectory(Directory dir, HttpRequest request) async {
  HttpResponse response = request.response;
  var dirStats = dir.statSync();
  String rootPath = config['fileserver_root'];
  String currentURL = '';
  // local function to get from file back to url
  String pathToURL(String path) {
    if (path.length>=rootPath.length  && path.substring(0,rootPath.length)==rootPath) {
      String result = path.substring(rootPath.length).replaceAll('\\', '/');
      if (result.length >2 && result.substring(0,3) == '/./')  // noise from virtualDirecotry ??
        result = result.substring(2);
      return result;
    } else
      return 'BADPATH='+path;
  } // of pathToURL
//    if (request.headers.ifModifiedSince != null &&
//        !dirStats.modified.isAfter(request.headers.ifModifiedSince)) {
//      response.statusCode = HttpStatus.notModified;
//      response.close();
//      return;
//    }
    response.headers.contentType = new ContentType('text', 'tab-separated-values');
    response.headers.set(HttpHeaders.lastModifiedHeader, dirStats.modified);
//    var path = Uri.decodeComponent(request.uri.path);
    response.writeln('name\tmodified:d\tsize:i\tfolder:b');

    void addLine(String name, String modified, var size, bool folder) {
      size ??= "-";
      modified ??= "";
      String entry = '${name}\t${modified}\t${size}\t${folder}';
      print(entry);
      response.writeln(entry);
    }
    void addFileSystemEntity(FileSystemEntity entity) {
      var stat = entity.statSync();
      String newURL = pathToURL(Path.dirname(entity.path));
      String fileName = Path.basename(entity.path);
      if (newURL == '/.') return; // skip pointer to current directory
      if (newURL != currentURL) {  // insert directory lines on change of directory
        currentURL = newURL;
        response.writeln(); // add blankline as visual separator
        addLine(currentURL,stat.modified.toString(),-1,true);
      }
      if (entity is File)
        addLine(fileName, stat.modified.toString(), stat.size, false);
       else if (entity is Directory)
        addLine(fileName, stat.modified.toString(), null, true);
    } // of addFileSystemEntity
    var dirList = await dir.list(recursive: true, followLinks: true).toList();
    for (FileSystemEntity fse in dirList) {addFileSystemEntity(fse);}

    response.close();
    print('close');
}
*/
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
     return token.contains('F71');  // TODO: proper security check
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
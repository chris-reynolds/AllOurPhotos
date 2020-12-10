import 'dart:io';
import 'dart:async';
import 'dart:convert' show jsonDecode, utf8;
import 'package:http_server/http_server.dart';
import 'package:path/path.dart' as path;
import 'package:exif/exif.dart';

String VERSION = '2019.03.09';
HttpServer mainServer;
VirtualDirectory _staticFileRoot;
Map config;
List<String> _topCache = <String>[];

Future main(List<String> arguments) async {
  try {
    if (arguments.length == 0) throw 'Configuration file not found';
    config = await loadConfig(arguments[0]);
    int webServerPort = int.tryParse(config['webserver_port']) ?? 8888;
    mainServer = await loadServer(webServerPort, config['fileserver_root']);
    mainServer.listen(processRequest);
    print('AOP Server $VERSION running on $webServerPort');
    return;
  } catch (ex) {
    print('Failed to load AllOurPhotos server : $ex');
    exit(16);
  } // of catch
} // of main

Future<String> extractExif(String path) async {
  List<String> result = [];
  Map<String, IfdTag> data =
      await readExifFromBytes(await new File(path).readAsBytes());
  if (data == null || data.isEmpty)
    result.add('Error: No EXIF information found');
  else {
    if (data.containsKey('JPEGThumbnail')) {
      result.add('File has JPEG thumbnail');
      data.remove('JPEGThumbnail');
    }
    if (data.containsKey('TIFFThumbnail')) {
      result.add('File has TIFF thumbnail');
      data.remove('TIFFThumbnail');
    }
    for (String key in data.keys)
      result.add("$key (${data[key].tagType}): ${data[key]}");
  }
  return result.join('\n');
} // of extractExif

Future<HttpServer> loadServer(int port, String rootPath) async {
  // TODO: check rootpath file existance
  _staticFileRoot = new VirtualDirectory(rootPath)
    ..allowDirectoryListing = false;
//      ..allowDirectoryListing = true;
//    _staticFileRoot.directoryHandler = serveDirectory;
  return await HttpServer.bind(InternetAddress.anyIPv4, port);
} // of loadServer

Future processRequest(HttpRequest request) async {
  print('Got ${request.method} request for ${request.uri.path}');
  final response = request.response;
  void plainResponse(int thisStatusCode, String text) {
    response
      ..statusCode = thisStatusCode
      ..headers.contentType = ContentType('text', 'plain')
      ..write(text);
    response.close();
  } // of plainResponse

  String cookieValue =
      response.cookies.length == 0 ? 'NONE' : response.cookies[0].value;
  bool permissionDenied = securityCheck(cookieValue);
  List<String> bits = request.uri.path.split('/');
  if (request.method == 'GET') {
    if (request.uri.path.length > 8 &&
        request.uri.path.substring(0, 8) == '/located') {
      String newToken = bits.length == 4 ? securityToken(bits[2], bits[3]) : '';
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
    } else if (permissionDenied) {
      // failed security check
      response
        ..statusCode = HttpStatus.unauthorized
        ..headers.contentType = ContentType('text', 'plain')
        ..write('Permission Denied');
      response.close();
    } else if (bits[1].toLowerCase() == 'exif') {
      bits.removeAt(1);
      String pictureFile = config['fileserver_root'] + bits.join('/');
      if (File(pictureFile).existsSync()) {
        // now extract the exif data
        plainResponse(HttpStatus.accepted, await extractExif(pictureFile));
      } else
        plainResponse(HttpStatus.notFound, '$pictureFile not found');
    } else {
      await _staticFileRoot.serveRequest(request);
    }
  } else if (request.method == 'PUT') {
    String filePath = config['fileserver_root'] + request.uri.toFilePath();
    HttpRequestBody body = await HttpBodyHandler.processRequest(
      request,
    );
    if (body.type == 'binary') {
      try {
// force the existence of the directory on the server
        String dirName = path.dirname(filePath);
        if (!Directory(dirName).existsSync()) {
          Directory(dirName).createSync(recursive: true);
          print('Creating directory $dirName');
        }
        File(filePath).writeAsBytesSync(body.body, flush: true);
        plainResponse(
            200, 'Written ${request.uri.path} with ${body.body.length}');
      } catch (ex) {
        print('Exception on PUT : $ex');
        plainResponse(500, 'Failed to write $filePath \n $ex');
      } // of catch
    } else
      plainResponse(400, 'Todo put non-binary $filePath');
  } else
    plainResponse(
        HttpStatus.methodNotAllowed, 'Invalid method${request.method}');
} // of process request


Future<Map> loadConfig(String filename) async {
  if (!FileSystemEntity.isFileSync(filename))
    throw 'Invalid configuration filename ($filename)';
  else {
    String configContents = File(filename).readAsStringSync(encoding: utf8);
    try {
      return jsonDecode(configContents);
    } catch (err) {
      throw 'Corrupt configuration file';
    } // of catch
  }
}

bool securityCheck(String token) {
  return token.contains('F71'); // TODO: proper security check
} // of security check

String securityToken(String username, String password) {
  int suffixHelp = 9;
  if (config['password.' + username] == password) {
    return DateTime.now().millisecondsSinceEpoch.toRadixString(13) +
        'F' +
        (8 * suffixHelp - 1).toString();
  } else {
    return ''; // failed
  }
} // of security token

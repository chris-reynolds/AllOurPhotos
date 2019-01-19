/**
 * Created by Chris on 11/10/2018.
 */
import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:all_our_photos_app/ImgFile.dart';
import 'package:all_our_photos_app/Logger.dart' as log;
import 'package:all_our_photos_app/utils/timing.dart';
import 'dart:async';

const webRoute = 'http://192.168.1.251:3333/';
const rootFilename = 'aopTop.txt';
const indexFilename = 'index.tsv';




Future<String> loadTop(Function continuer) async {
  String result = '';
  int requestCount = 0;
  Timing.start('loadTop');
  try {
    List<String> dirNames = await getRemoteStrings(webRoute+rootFilename,delimiter:'~');
    if (dirNames.length<2)
      throw('Invalid index. rebuild required');
    dirNames.removeAt(0);
    dirNames.removeLast();
    log.message('Index loading');
    ImgCatalog.clear();
    for (String thisDirName in dirNames) {
      ImgDirectory thisDirectory = ImgCatalog.newDirectory(thisDirName);
      requestCount++;
      getRemoteStrings(webRoute+thisDirName+'/'+indexFilename).then((remoteIndex) {
        thisDirectory.fromStrings(remoteIndex);
        if (--requestCount==0)
          continuer();
      });
    } // of dirName loop
    result = 'Index loaded ${ImgCatalog.length} directories';
  } catch(ex) {
    result = (ex is String)? ex : ex.toString();
  } // of try except
  return result;
} // of loadTop

Future<List<String>> getRemoteStrings(String url, {String delimiter:"\n"}) async {
  var response = await http.get(url);
  if (response.statusCode == 200) {
    return response.body.split(delimiter);
  } else {
    throw Exception('Failed to load remote info');
  }
} // of getRemoteStrings

Future<void> writeRemoteString(String dirname,String filename,String contents) async {
  int statusCode = 0;
  List<String> returnData;
  log.message('starting writefile $dirname/$filename');
  try {
    Uri url = Uri.parse("$webRoute$dirname/$filename");
    HttpClient httpClient = HttpClient();
    HttpClientRequest request = await httpClient.putUrl(url);
    request.cookies.add(Cookie('aop','F71'));
    request.add(utf8.encode(contents));
    HttpClientResponse response = await request.close();
    returnData = await response.transform(utf8.decoder).toList();
    statusCode = response.statusCode;
    log.message('Response ${response.statusCode}: $returnData');
    httpClient.close();
  } catch(ex) {
    throw new Exception('Failed to write file: '+ex.toString());
  }
  if (statusCode != 200)
    throw new Exception('Failed to write to server $statusCode: \n $returnData');
}  // of writeRemoteString

String thumbnailURL(ImgFile imgFile) => '$webRoute${imgFile.dirname}/thumbnails/${imgFile.filename}';
String fullsizeURL(ImgFile imgFile) => '$webRoute${imgFile.dirname}/${imgFile.filename}';

const oneSec = Duration(seconds:10);
Timer _timer;
void initTimer() {

  _timer = new Timer.periodic(oneSec, directoryWatcher);
} // of initTimer

void cancelTimer() => _timer.cancel;

bool saveDirectoryIfRequired(ImgDirectory thisDirectory) {
  if (thisDirectory.dirty) {
    log.message('dirty ${thisDirectory.directoryName}');
    try {
      writeRemoteString(thisDirectory.directoryName,
          indexFilename, thisDirectory.toStrings().join("\n"));
      thisDirectory.dirty = false;
    } catch(ex) {
      log.message('Failed to write directory ${thisDirectory.directoryName} : ${ex.toString()}');
    }

  }
  return true;
}
void directoryWatcher(Timer timer) {
//  log.message('tick tock2');
  ImgCatalog.forEachDir(saveDirectoryIfRequired);
}

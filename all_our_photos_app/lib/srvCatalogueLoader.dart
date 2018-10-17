/**
 * Created by Chris on 11/10/2018.
 */
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import 'dart:async';
import 'package:all_our_photos_app/ImgFile.dart';
import 'package:all_our_photos_app/Logger.dart' as log;

const webRoute = 'http://192.168.1.251:3333/';
const rootFilename = 'aopTop.txt';
const indexFilename = 'index.tsv';

Future<String> loadTop() async {
  String result = '';
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
      List<String> remoteIndex = await getRemoteStrings(webRoute+thisDirName+'/'+indexFilename);
      thisDirectory.fromStrings(remoteIndex);
   //   log.message('$thisDirName loaded with ${remoteIndex.length} entries');
    } // of dirName loop
    log.message('Index loaded ${ImgCatalog.length} directories');
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
/**
 * Created by Chris on 25/10/2018.
 */
import './Logger.dart' as log;
//import 'dart:collection';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:all_our_photos_app/appNavigator.dart' as appNavigator;

final String baseURL = 'https://photoslibrary.googleapis.com/v1/';

class GoogleAlbum {
  String id;
  String title;
  String productUrl;
  int mediaItemsCount;

  GoogleAlbum(this.id,this.title,this.productUrl,this.mediaItemsCount);

  factory GoogleAlbum.fromJson(Map<String,dynamic> jsonNode) {
    return GoogleAlbum(jsonNode['id'].toString(), jsonNode['title'].toString(),
      jsonNode['productUrl'].toString(),int.parse(jsonNode['mediaItemsCount']));
  } // fromJson factory

} // of GoogleAlbum

class GooglePhoto {


} // of GooglePhoto

abstract class PhotosLibraryClient {

  static Future<Map<String,dynamic>> fetch(String thisPath) async {
    http.Response httpResponse = await http.get(Uri.encodeFull(baseURL+thisPath),
                                      headers:appNavigator.authHeaders);
    Map<String,dynamic> result = json.decode(httpResponse.body);
    return result;
  } // of fetch

  static Future<List<GoogleAlbum>> listAlbums() async {
    List<GoogleAlbum> result = [];
    Map<String,dynamic>thisMap = await fetch('albums');
    if (thisMap.containsKey('error'))
      throw Exception(thisMap['error'].message);
    for(var thisNode in thisMap['albums'])
      result.add(new GoogleAlbum.fromJson(thisNode));
    log.message('I have loaded ${result.length} albums');
    return result;
  }  // of listAlbums

} // of PhotosLibraryClient

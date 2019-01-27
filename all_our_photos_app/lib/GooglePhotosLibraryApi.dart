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
  String baseUrl;
  int mediaItemsCount;

  GoogleAlbum(this.id, this.title, this.productUrl, this.baseUrl, this.mediaItemsCount);

  factory GoogleAlbum.fromJson(Map<String, dynamic> jsonNode) {
    return GoogleAlbum(
        jsonNode['id'].toString(),
        jsonNode['title'].toString(),
        jsonNode['productUrl'].toString(),
        jsonNode['baseUrl'].toString(),
        int.parse(jsonNode['mediaItemsCount']));
  } // fromJson factory

} // of GoogleAlbum

class GooglePhoto {
  String id;
  String baseUrl;
  String productUrl;
  String filename;
  DateTime creationDate;
  int height;
  int width;

  GooglePhoto(this.id, this.baseUrl, this.productUrl, this.filename,
      this.creationDate, this.height, this.width);

  factory GooglePhoto.fromJson(Map<String, dynamic> jsonNode) {

    Map<String, dynamic> metadata = jsonNode['mediaMetadata'];
    return GooglePhoto(
        jsonNode['id'].toString(),
        jsonNode['baseUrl'].toString(),
        jsonNode['productUrl'].toString(),
        jsonNode['filename'].toString(),
        DateTime.parse(metadata['creationTime'].toString()),
        int.parse(metadata['height'].toString()),
        int.parse(metadata['width'].toString()));
  } // fromJson

} // of GooglePhoto

abstract class GooglePhotosLibraryClient {
  static Future<Map<String, dynamic>> fetch(String thisPath) async {
    http.Response httpResponse = await http.get(
        Uri.encodeFull(baseURL + thisPath),
        headers: appNavigator.authHeaders);
    Map<String, dynamic> result = json.decode(httpResponse.body);
    return result;
  } // of fetch

  static Future<Map<String, dynamic>> search(
      String thisPath, Map<String, String> parameters) async {
    String jsonBody = jsonEncode(parameters);
    http.Response httpResponse = await http.post(
        Uri.encodeFull(baseURL + thisPath),
        headers: appNavigator.authHeaders,
        body:jsonBody) ;
    Map<String, dynamic> result = json.decode(httpResponse.body);
    return result;
  } // of search

  static Future<List<GoogleAlbum>> listAlbums() async {
    List<GoogleAlbum> result = [];
    Map<String, dynamic> thisMap = await fetch('albums');
    if (thisMap.containsKey('error')) throw Exception(thisMap['error'].message);
    for (var thisNode in thisMap['albums'])
      result.add(new GoogleAlbum.fromJson(thisNode));
    log.message('I have loaded ${result.length} albums');
    return result;
  } // of listAlbums

  static Future<List<GooglePhoto>> listAlbumPhotos(String albumId) async {
    List<GooglePhoto> result = [];
    Map<String, dynamic> thisMap = await search('mediaItems:search',
        {"albumId" : albumId});
    if (thisMap.containsKey('error')) throw Exception(thisMap['error'].message);
    for (var thisNode in thisMap['mediaItems'])
      result.add(new GooglePhoto.fromJson(thisNode));
    log.message('I have loaded ${result.length} photos');
    return result;
  } // of listAlbumPhotos

} // of GooglePhotosLibraryClient

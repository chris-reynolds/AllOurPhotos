/**
 * Created by Chris on 8/10/2018.
 * Purpose: To reverse geocode from camera latitude/longitude to displayable name
 */

import 'dart:io';
import 'dart:math';
import 'dart:convert';
import 'Logger.dart' as Log;



class GeocodingSession  {

  static const _host = 'https://nominatim.openstreetmap.org/reverse?format=jsonv2&zoom=14';
  static double calcSign(String direction,double magnitude) {
    if (direction == null)
      return magnitude;
    if ('SWsw'.indexOf(direction)>=0)
      magnitude = - magnitude;
    return magnitude;
  }
  final double _tileSizeKms = 5.0;
  String _calcKey(double longitude,double latitude) {
    double latDegree = 111.0;
    double longDegree = 111.0*cos(latitude*pi/180);
    int latTiles = (latitude*latDegree/_tileSizeKms).round();
    int longTiles = (longitude*longDegree/_tileSizeKms).round();
    return '$longTiles:$latTiles';
  } // of _calcKey

  static Map<String,String> _cache = {};

  int get length => _cache.length;

  Future<String> getLocation(double longitude,double latitude) async {
    final key = _calcKey(longitude, latitude);
    if (_cache[key]==null) {
      String newLocation = await urlLookupFromCoordinates(latitude, longitude);
      _cache[key] = newLocation;
    }
    return _cache[key];
  } // of getLocation

  void setLocation(double longitude,double latitude,String location) {
    final key = _calcKey(longitude, latitude);
    _cache[key] = location;
  } // of setLocation

  Future<String> urlLookupFromCoordinates(double latitude, double longitude) async {
    final url = '$_host&lat=$latitude&lon=$longitude';
    Log.message("Sending $url...");
    final uri = Uri.parse(url);
    var httpClient = HttpClient();
    HttpClientRequest request;
    try {
      request = await httpClient.openUrl('GET',uri);
    } catch (ex) {
      Log.error(ex);
    }
    HttpClientResponse response = await request.close();
    var responseBody = await response.transform(utf8.decoder).join();
 //   print("Received $responseBody...");
    var data = jsonDecode(responseBody);
    httpClient.close();
    var result = data["display_name"];
    bool goodLocationFound = (result != null) ;
    if (!goodLocationFound)
      Log.error('Bad geolocation response $data');
    return goodLocationFound ? result : null;
  }  // of urlLookupFromCoordinates

} // of GeocodingSession
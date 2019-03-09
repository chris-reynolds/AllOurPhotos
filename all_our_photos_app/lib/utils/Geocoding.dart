/**
 * Created by Chris on 8/10/2018.
 */

import 'dart:io';
import 'dart:math';
import 'dart:convert';
import 'Logger.dart' as log;

String apiKey = 'AIzaSyDl6PsEAYBbataJfQSn3hiOs8x02ntBhAk';
double tileSizeKms = 5.0;
String _calcKey(double longitude,double latitude) {
    double latDegree = 111.0;
    double longDegree = 111.0*cos(latitude*pi/180);
    int latTiles = (latitude*latDegree/tileSizeKms).round();
    int longTiles = (longitude*longDegree/tileSizeKms).round();
    return '$longTiles:$latTiles';
  } // of _calcKey

Map<String,String> _cache = {};

int get length => _cache.length;

String getLocation(double longitude,double latitude) {
  final key = _calcKey(longitude, latitude);
  return _cache[key];
} // of getLocation

void setLocation(double longitude,double latitude,String location) {
  final key = _calcKey(longitude, latitude);
  _cache[key] = location;
} // of setLocation

GeocodingSession _session;
dynamic fetchGoogleLocation(double longitude,double latitude) async {
  if (_session == null)   // first time setup
    _session = GeocodingSession(apiKey);
  return await _session.findLocationFromCoordinates(latitude, longitude);
} // of fetchGoogleLocation



class GeocodingSession  {

  static const _host = 'https://maps.google.com/maps/api/geocode/json';

  final String sessionApiKey;
  final String resultType ='location_type=ROOFTOP&result_type=street_address';

  GeocodingSession(this.sessionApiKey) {
    assert(sessionApiKey != null, "geocoding apiKey is required");
  }

  dynamic findLocationFromCoordinates(double latitude, double longitude) async {
    final url = '$_host?key=$sessionApiKey&latlng=$latitude,$longitude';
    print("Sending $url...");
    final uri = Uri.parse(url);
    var httpClient = HttpClient();
    HttpClientRequest request;
    try {
      request = await httpClient.openUrl('GET',uri);
    } catch (ex) {
      print(ex);
    }
 //   HttpClientRequest
    HttpClientResponse response = await request.close();
    var responseBody = await response.transform(utf8.decoder).join();
 //   print("Received $responseBody...");
    var data = jsonDecode(responseBody);
    httpClient.close();
    bool goodLocationFound = false;
    var result = data["plus_code"];
    if (result != null) {
      result = result["compound_code"];
      if (result is String && result.indexOf(' ') > 0) {
        // strip code off the front of the address
        result = (result as String).substring(result.indexOf(' ')+1);
        goodLocationFound = true;
      }
    }
    if (!goodLocationFound)
      log.error('Bad geolopcation response $data');
    return goodLocationFound ? result : null;
  }  // of _send
} // of GeocodingSession
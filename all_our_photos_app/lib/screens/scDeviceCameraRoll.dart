import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:multi_image_picker/multi_image_picker.dart' as MIP;
import 'package:device_info/device_info.dart';
import '../dart_common/DateUtil.dart';
import '../dart_common/Logger.dart' as Log;
import '../dart_common/Geocoding.dart';
import '../shared/aopClasses.dart';
import '../shared/dbAllOurPhotos.dart';

class CameraRollPage extends StatefulWidget {
  @override
  _CameraRollPageState createState() => _CameraRollPageState();
}

class _CameraRollPageState extends State<CameraRollPage> {
  int _imagesToUpload = 0;
  int _skipCount = 0;
  List<MIP.Asset> _images = [];
  GeocodingSession _geo = GeocodingSession();

  Future<void> _uploadJpg(String urlString, ByteData bytes) async {
//    Future<TestRequest> get(String url,{String accept ,String cookie,List<int> putData}) async {
//      var url2 = Uri.parse(TEST_HOST + url);
//      var httpClient = HttpClient();
//      HttpClientRequest request;
//      if (putData == null)
//        request = await httpClient.getUrl(url2);
//      else {
//        request = await httpClient.putUrl(url2);
//        request.add(putData);
//      }
//      if (cookie != null)
//        request.cookies.add(Cookie('aop',cookie));
//      response = await request.close();
//      responseText = await response.transform(utf8.decoder).toList();
//      testLog('Response ${response.statusCode}: type ${responseText.runtimeType} $responseText');
//      if (response.headers.value('content-type').contains('json')) {
//        responseData = jsonDecode(responseText.join());
//      } else
//        responseData = null;
//      httpClient.close();
//      return this;
//    }
    var postUri = Uri.parse(urlString);
    HttpClient httpClient = HttpClient();
    var request = await httpClient.putUrl(postUri);
    //   request.fields['user'] = 'blah';
    //   request.files.add(new http.MultipartFile.fromBytes('file', await File.fromUri("<path/to/file").readAsBytes(), contentType: new MediaType('image', 'jpeg')))
    request.add(bytes.buffer.asUint8List());
    var response = await request.close();
    httpClient.close();
    if (response.statusCode == 200)
      Log.message("Uploaded $urlString");
    else
      throw Exception('Failed to upload $urlString with $response');
    ;
  } // of httpPostImage

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text('Camera Roll uploader'),
          actions: <Widget>[
            IconButton(
              icon: Icon(Icons.add_a_photo),
              onPressed: getDeviceCameraRoll,
            ),
            if (_images.length > 0)
              IconButton(
                icon: Icon(Icons.file_upload),
                onPressed: uploader,
              ),
          ],
        ),
        body: Center(
            child: Column(
          children: <Widget>[
            if (_images.length > 0)
              Text('Photos to upload $_imagesToUpload',
                  style: TextStyle(fontSize: 30)),
            if (_skipCount > 0)
              Text('Skipped Photos  $_skipCount',
                  style: TextStyle(fontSize: 20)),
          ],
        ))); // scaffold
  } // of build

  Future<void> getDeviceCameraRoll() async {
    var images = await MIP.MultiImagePicker.pickImages(maxImages: 1000);
    setState(() {
      _images = images;
      _imagesToUpload = _images.length;
      _skipCount = 0;
    });
  } // of getDeviceCameraRoll

  @override
  void initState() {
    super.initState();
    getDeviceCameraRoll();
    initGeoCache();
  } // of initState

  Future<void> initGeoCache() async {
    dynamic r = await AopSnap.existingLocations;
    for (dynamic row in r) _geo.setLocation(row[1], row[2], row[0]);
  }

  Widget thumbnailBuild(BuildContext context, snapshot) {
    return Container(
      height: 80.0,
      margin: EdgeInsets.all(10),
      child: snapshot.hasData ? snapshot.data : Text('loading..'),
    );
  } // thumbnails

  Future<ByteData> thumbnail640(MIP.Asset anImage) {
    double scale = anImage.isLandscape
        ? 640 / anImage.originalWidth
        : 640 / anImage.originalHeight;
    return anImage.requestThumbnail((anImage.originalWidth * scale).floor(),
        (anImage.originalHeight * scale).floor());
  } // thumbnail640

  void uploader() async {
    bool success;
    Log.message('uploader start');
    for (int imageIx = 0; imageIx < _images.length; imageIx++) {
      try {
        var db = DbAllOurPhotos();
        success = await uploadImage(_images[imageIx], db);
      } catch (ex) {
        success = false;
        Log.message('Failed to update database \n $ex');
      } finally {
        _imagesToUpload = _images.length - imageIx - 1;
        if (!success) _skipCount++;
        setState(() {
          Log.message('todo $_imagesToUpload skipped $_skipCount');
        });
      }
      Log.message('while');
    }
    Log.message('uploader ended');
    setState(() {
      _images = [];
      _imagesToUpload = 0;
    });
  } // of uploader

  Future<bool> uploadImage(MIP.Asset anImage, DbAllOurPhotos db) async {
    try {
      DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
      String deviceName = 'Unknown';
      if (!Platform.isIOS) {
        AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
        deviceName = androidInfo.device;
//      print('Running on ${androidInfo.model}');  // e.g. "Moto G (4)"
      } else {
        IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
        deviceName = iosInfo.name;
//      print('Running on ${iosInfo.utsname.machine}');  // e.g. "iPod7,1"
      }
//    var imageData = await anImage.requestOriginal();
      var metaData = await anImage.requestMetadata();
      AopSnap newSnap = AopSnap()
        ..fileName = anImage.name
        ..directory = '1982-01'
        ..width = anImage.originalWidth
        ..height = anImage.originalHeight
        ..takenDate = dateTimeFromExif(metaData.exif.dateTimeOriginal)
        ..modifiedDate = dateTimeFromExif(metaData.exif.dateTimeOriginal)
        ..latitude = metaData.gps.gpsLatitude
        ..longitude = metaData.gps.gpsLongitude
        ..deviceName = deviceName
        ..rotation = '0' // todo support enumeration
        ..importSource = deviceName
        ..importedDate = DateTime.now();
      bool isScanned =
          ((metaData.device.software ?? '').toLowerCase().indexOf('scan') >= 0);
      newSnap.importSource += isScanned ? ' scanned' : ' camera roll';
      if (newSnap.latitude != null) {
        String location =
            await _geo.getLocation(newSnap.longitude, newSnap.latitude);
        if (location != null) {
          if (location.length > 100)
            location = location.substring(location.length - 100);
          newSnap.location = location;
        }
      }
      newSnap.originalTakenDate = newSnap.takenDate;
      newSnap.directory =
          formatDate(newSnap.originalTakenDate, format: 'yyyy-mm');
      ByteData fullImageBytes = await anImage.requestOriginal();
      ByteData thumbnailBytes = await thumbnail640(anImage);

      newSnap.mediaLength = fullImageBytes.lengthInBytes;
      if (await AopSnap.exists(newSnap.fileName, newSnap.mediaLength))
        return false;
      await _uploadJpg(newSnap.thumbnailURL, thumbnailBytes);
      await _uploadJpg(newSnap.fullSizeURL, fullImageBytes);
      await newSnap.save();
      return true;
    } catch (ex) {
      Log.message('Failed save for ${anImage.name} - $ex');
      return false;
    } // of try
  } // of uploadImage

}

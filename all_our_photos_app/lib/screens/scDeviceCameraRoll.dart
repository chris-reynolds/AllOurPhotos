import 'package:all_our_photos_app/utils/DateUtil.dart';
import 'package:multi_image_picker/multi_image_picker.dart' as MIP;
import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:io';
import 'package:all_our_photos_app/shared/dbAllOurPhotos.dart';
import 'dart:typed_data';
import 'package:all_our_photos_app/shared/aopClasses.dart';
//import 'package:image_gallery/image_gallery.dart';
import 'package:device_info/device_info.dart';

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  Image _image;
  ByteData _imageData;
  List<MIP.Asset> _images;

  void uploader() async {
    print('uploader start');
    try {
      var db = DbAllOurPhotos();
      await uploadImage(_images[0],db);
    } catch(ex) {
       print('Failed to update database \n $ex');
    }
    print('uploader ended');
  } // of uploader

  Future<void> uploadImage(MIP.Asset anImage, DbAllOurPhotos db) async {
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
      ..directory = '$deviceName roll'
      ..width = anImage.originalWidth
      ..height = anImage.originalHeight
      ..takenDate = dateTimeFromExif(metaData.exif.dateTimeOriginal)
      ..modifiedDate = dateTimeFromExif(metaData.exif.dateTimeOriginal)
      ..latitude= metaData.gps.gpsLatitude
      ..longitude = metaData.gps.gpsLongitude
      ..deviceName = metaData.device.model
      ..rotation = '0'  // todo support enumeration
      ..importSource = '${metaData.device.cameraOwnerName??metaData.device.model} camera roll'
      ..importedDate = DateTime.now()
    ;
    //int insertId =
    await newSnap.save();
  } // of uploadImage

  Future getImage() async {

    _images = await MIP.MultiImagePicker.pickImages(maxImages: 1000);
    Image firstImage;
    if (_images.length==0)
      firstImage = null;
    else {
      _imageData = await _images[0].requestOriginal();
      firstImage = Image.memory(_imageData.buffer.asUint8List());
    } setState(() {
      _image = firstImage;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Image Picker Example'),
      ),
      body: _image == null
          ? Text('No image selected.') : Column(
        children:  [
          RaisedButton(onPressed: uploader,child:Text('upload') ),
             _image,
 //       RaisedButton(onPressed: loadImageList,child:Text('list device') )
      ]
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: getImage,
        tooltip: 'Pick Image',
        child: Icon(Icons.add_a_photo),
      ),
    );
  }
}
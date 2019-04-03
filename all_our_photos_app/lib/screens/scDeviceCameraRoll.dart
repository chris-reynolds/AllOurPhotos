import 'package:all_our_photos_app/utils/DateUtil.dart';
import 'package:multi_image_picker/multi_image_picker.dart' as MIP;
import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:io';
import 'package:all_our_photos_app/dbAllOurPhotos.dart';
import 'dart:typed_data';
import 'package:all_our_photos_app/classes.dart';
//import 'package:image_gallery/image_gallery.dart';

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
    var imageData = await anImage.requestOriginal();
    var thumbnail = await anImage.releaseThumb();
    var metaData = await anImage.requestMetadata();
    Media newImage = Media()
      ..name = anImage.name
      ..width = anImage.originalWidth
      ..height = anImage.originalHeight
      ..taken_date = dateTimeFromExif(metaData.exif.dateTimeOriginal)
      ..latitude= metaData.gps.gpsLatitude
      ..longtitude = metaData.gps.gpsLongitude;
    await db.addImage(newImage, imageData.buffer.asUint8List());
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
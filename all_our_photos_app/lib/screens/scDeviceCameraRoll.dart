import 'package:multi_image_picker/multi_image_picker.dart' as MIP;
import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:io';
import 'package:all_our_photos_app/dbAllOurPhotos.dart';
import 'dart:typed_data';

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
      db.addImage('blah', 43, 44, _imageData.buffer.asUint8List());
    } catch(ex) {
       print('Failed to update database \n $ex');
    }
    print('uploader ended');
  } // of uploader

  Future getImage() async {

    _images = await MIP.MultiImagePicker.pickImages(maxImages: 3);
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
      body: Column(
        children: [_image == null
            ? Text('No image selected.')
            : _image,
          RaisedButton(onPressed: uploader,child:Text('upload') )
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
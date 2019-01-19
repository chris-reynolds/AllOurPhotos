import 'dart:io';
import 'package:flutter/material.dart';

class CameraRollWidget extends StatelessWidget {
//  static final Directory _photoDir =
//  new Directory('/storage/emulated/0/DCIM/Camera');

  @override
  Widget build(BuildContext context) {
    List<FileSystemEntity> _photoList;

    Widget buildPhoto(int index) {
      if (index >= _photoList.length) {
        return null;
      }
      print('Loading photo[$index]: ${_photoList[index]}... done');
      return new Container(
        margin: EdgeInsets.all(8.0),
        child: new Image.file(
          _photoList[index],
          // Use small images to fit more on the screen at once
          // Shows the loading speed more clearly
          width: 96.0,
          height: 96.0,
          scale: 16.0,
          fit: BoxFit.contain,
        ),
      );
    }

    Widget buildPhotoList() {
      try {
        _photoList = []; //_photoDir.listSync();
      } catch(ex) {
        print('Failed to get directory : $ex');
        _photoList = <FileSystemEntity>[]; // empty array
      }
        return new ListView.builder(
          itemBuilder: (BuildContext context, int index) => buildPhoto(index),
        );
    } // buildPhotoList

    return  new Center(
        child: new Align(
          alignment: Alignment.topCenter,
          child: buildPhotoList(),
        ),
    );
  }
}
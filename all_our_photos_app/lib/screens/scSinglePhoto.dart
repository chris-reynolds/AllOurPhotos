/*
  Created by chrisreynolds on 2019-09-18
  
  Purpose: Stateful SinglePhotoWidget
*/

import 'dart:convert';
import '../dart_common/DateUtil.dart';
import '../dart_common/WebFile.dart';
import '../widgets/PhotoViewWithRectWidget.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as Im;
import '../shared/aopClasses.dart';
import '../dart_common/Logger.dart' as Log;
import '../flutter_common/WidgetSupport.dart';

class SinglePhotoWidget extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return new SinglePhotoWidgetState();
  }
}

class SinglePhotoWidgetState extends State<SinglePhotoWidget> {
  List<AopSnap> snapList;
  int _snapIndex = -1;
  AopSnap currentSnap;
  AopAlbum maybeCurrentAlbum;
  final GlobalKey pvKey = GlobalKey();
  bool isPhotoScaled = false;

  void _initParams() {
    List params = ModalRoute.of(context).settings.arguments;
    snapList = params[0];
    _snapIndex = params[1];
    if (params.length > 2) maybeCurrentAlbum = params[2];
  } // of initParams

  void set snapIndex(int newIndex) {
    if (newIndex >= 0 && newIndex < snapList.length)
      setState(() {
        _snapIndex = newIndex;
      });
  }

  Widget buildAppBar(BuildContext context) {
    return AppBar(
      title: new Text(currentSnap.fileName + ' ' + currentSnap.caption),
      actions: <Widget>[
        IconButton(
          icon: Icon(Icons.arrow_upward),
          onPressed: (_snapIndex == 0)
              ? null
              : () {
                  snapIndex = _snapIndex - 1;
                },
        ),
        IconButton(
            icon: Icon(Icons.arrow_downward),
            onPressed: (_snapIndex >= snapList.length - 1)
                ? null
                : () {
                    snapIndex = _snapIndex + 1;
                  }),
        IconButton(
            icon: Icon(Icons.edit),
            onPressed: () {
              Navigator.of(context).pushNamed('MetaEditor', arguments: currentSnap);
            }),
        IconButton(
          icon: Icon(Icons.rotate_left),
          onPressed: () async {
            currentSnap.rotate(-1);
            await currentSnap.save();
            setState(() {});
          },
        ),
        IconButton(
          icon: Icon(Icons.rotate_right),
          onPressed: () async {
            currentSnap.rotate(1);
            await currentSnap.save();
            setState(() {});
          },
        ),
        IconButton(
            icon: Icon(Icons.crop),
            onPressed: () {
              cropMe(context, currentSnap);
            }),
        IconButton(icon: Icon(Icons.palette), onPressed: (_snapIndex == 1) ? () {} : null),
        PopupMenuButton<String>(
          onSelected: (String result) {
            if (result == 'exif') {
              showExif(context, currentSnap);
            }
          },
          itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
            PopupMenuItem<String>(
              value: 'exif',
              child: Text('exif Data'),
              enabled: (currentSnap.metadata != null),
            ),
          ],
        ),
      ], // of actions
    );
  } // of buildAppbar

  @override
  Widget build(BuildContext context) {
    if (snapList == null) _initParams(); // can't get params until we have a context!!!!
    currentSnap = snapList[_snapIndex];
    return Scaffold(
      appBar: buildAppBar(context),
      body: Center(
        child: Transform.rotate(
          angle: currentSnap.angle,
          child: PhotoViewerWithRect(
            key: pvKey,
            url: currentSnap.fullSizeURL,
            onScale: setIsPhotoScaled,
          ),
        ),
      ),
    );
  } // of build

  void setIsPhotoScaled(bool value) {
    Log.message('Scaling $value');
//    setState(() {
    isPhotoScaled = value;
//    });
  }

  void cropMe(BuildContext context, AopSnap snap) async {
    if (isPhotoScaled)
      showMessage(context, 'Nothing to do. \nZoom before clicking',
          title: 'Picture is all showing');
    else {
      await snapCrop(
          context,
          snap,
          (pvKey.currentWidget as PhotoViewerWithRect)
              .currentRect(Size(0.0 + snap.width, 0.0 + snap.height)));
    }
  } // of cropMe

  Future<AopSnap> snapCrop(BuildContext context, AopSnap originalSnap, Rect rect) async {
    if (rect == null) return null;
    try {
      Im.Image originalImage = await loadWebImage(originalSnap.fullSizeURL);
      print('clipping ${originalSnap.fileName} ${originalImage.length}');
      Im.Image newFullImage = Im.copyCrop(originalImage, rect.right.round(), rect.top.round(),
          (rect.left - rect.right).round(), (rect.bottom - rect.top).round());
      Im.Image newThumbnail = Im.copyResize(newFullImage,
          width: (originalImage.width >= originalImage.height) ? 640 : 480);
      Map buffer = originalSnap.toMap();
      buffer.remove('id'); //
      var newSnap = AopSnap()..fromMap(buffer);
      // sourceMarker is used for tracking where photos came from
      String sourcerMarker = 'Crop+${originalSnap.id}';
      newSnap.fileName = await calcNewFilenameForSnap(originalSnap, sourcerMarker);
      Map<String, dynamic> metaMap = jsonDecode(originalSnap.metadata);
      metaMap['width'] = newFullImage.width;
      metaMap['height'] = newFullImage.height;
      metaMap['cropped'] = formatDate(DateTime.now());
      newSnap.metadata = jsonEncode(metaMap);
      newSnap.importSource = sourcerMarker;
      print('clipping saving thumbnail');
      await saveWebImage(newSnap.thumbnailURL, image: newThumbnail);
      print('clipping saving fullimage');
      await saveWebImage(newSnap.fullSizeURL, image: newFullImage);
      print('clipping saving mketa');
      await saveWebImage(newSnap.metadataURL, metaData: newSnap.metadata);
      print('clipping saving db');
      await newSnap.save();
      snapList.add(newSnap);
      // is it part of the current album. If so add it to album
      if (maybeCurrentAlbum != null) {
        AopAlbumItem item = AopAlbumItem();
        item.albumId = maybeCurrentAlbum.id;
        item.snapId = newSnap.id;
        await item.save();
        maybeCurrentAlbum.albumItems.then((list) => list.add(item));
        maybeCurrentAlbum.snaps.then((list) => list.add(newSnap));
      }
      showMessage(context, 'Cropping to ${newSnap.fileName} completed');
    } on Exception catch (ex) {
      showMessage(context, 'Failed to crop image : $ex');
    }
  }

  Future<String> calcNewFilenameForSnap(AopSnap snap, String sourceMarker) async {
    int previousCrops = await AopSnap.getPreviousCropCount(sourceMarker);
    int dotPos = snap.fileName.lastIndexOf('\.');
    if (dotPos < 0) throw 'Failed to get extention of ${snap.fileName}';
    String result = snap.fileName.substring(0, dotPos) +
        '_cp${previousCrops + 1}' +
        snap.fileName.substring(dotPos);
    return result;
  } // of calcNewFilenameForSnap

  void showExif(BuildContext context, AopSnap thisSnap) {
    Navigator.of(context);
    Map<String, dynamic> tags = jsonDecode(thisSnap.metadata);
    String tagResult = '';
    tags.forEach((k, v) => tagResult += '$k = $v \n');
    showMessage(context, tagResult, title: 'Exif for ${thisSnap.fileName}');
  } // of showExif

}

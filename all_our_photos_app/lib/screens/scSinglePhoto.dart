/*
  Created by chrisreynolds on 2019-09-18
  
  Purpose: Stateful SinglePhotoWidget
*/

import 'dart:convert';
import '../utils/ExportPic.dart';
import '../widgets/PhotoViewWithRectWidget.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as Im;
import 'package:aopcommon/aopcommon.dart';
import '../shared/aopClasses.dart';
import '../flutter_common/WidgetSupport.dart';
import '../widgets/wdgImageFilter.dart'; // only for the icons

class SinglePhotoWidget extends StatefulWidget {
  const SinglePhotoWidget({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return SinglePhotoWidgetState();
  }
}

class SinglePhotoWidgetState extends State<SinglePhotoWidget> {
  List<AopSnap>? snapList;
  int _snapIndex = -1;
  AopSnap? currentSnap;
  AopAlbum? maybeCurrentAlbum;
  final GlobalKey pvKey = GlobalKey();
  bool isPhotoScaled = false;
  bool _isClippingInProgress = false;

  set isClippingInProgress(bool value) {
    setState(() {
      _isClippingInProgress = value;
    });
  }

  void _initParams() {
    List params = ModalRoute.of(context)!.settings.arguments as List<dynamic>;
    snapList = params[0];
    _snapIndex = params[1];
    if (params.length > 2) maybeCurrentAlbum = params[2];
  } // of initParams

  void _changeRanking(BuildContext context) {
    currentSnap!.ranking = (currentSnap!.ranking! + 1) % 3 + 1;
    _saveWithError(context);
  } // of changeRanking

  void _saveWithError(BuildContext context) async {
    try {
      await currentSnap!.save();
    } catch (ex) {
      showMessage(context, '$ex');
    }
    setState(() {});
  }

  set snapIndex(int newIndex) {
    if (newIndex >= 0 && newIndex < snapList!.length)
      setState(() {
        _snapIndex = newIndex;
      });
  }

  Widget buildAppBar(BuildContext context) {
    return AppBar(
      title: Text('${currentSnap!.fileName} ${currentSnap!.caption}'),
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
            onPressed: (_snapIndex >= snapList!.length - 1)
                ? null
                : () {
                    snapIndex = _snapIndex + 1;
                  }),
        IconButton(
            icon: Icon(Icons.edit),
            onPressed: () async {
              await Navigator.pushNamed(context, 'MetaEditor', arguments: currentSnap);
              setState(() {}); //force repaint on return
            }),
        IconButton(
          icon: Icon(Icons.rotate_left),
          onPressed: () async {
            currentSnap!.rotate(-1);
            _saveWithError(context);
          },
        ),
        IconButton(
          icon: Icon(Icons.rotate_right),
          onPressed: () async {
            currentSnap!.rotate(1);
            _saveWithError(context);
          },
        ),
        IconButton(
          icon: Icon(Icons.download_outlined),
          onPressed: () async {
            ExportPic.save(currentSnap!.fullSizeURL, currentSnap!.fileName, 'AllOurPhotos').then((success){
              showMessage(context, success?"Downloaded":"Download failed");
            });
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
              showExif(context, currentSnap!);
            } else if (result == 'exif-thumb') showThumbnailExif(context, currentSnap!);
          },
          itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
            PopupMenuItem<String>(
              value: 'exif',
              enabled: (currentSnap!.metadata != null),
              child: Text('exif Data'),
            ),
            PopupMenuItem<String>(
              value: 'exif-thumb',
              enabled: (currentSnap!.metadata != null),
              child: Text('exif Data thumbnail'),
            ),
          ],
        ),
      ], // of actions
    );
  } // of buildAppbar

  @override
  Widget build(BuildContext context) {
    double yPos;
    if (snapList == null) _initParams(); // can't get params until we have a context!!!!
    currentSnap = snapList![_snapIndex];
    return Scaffold(
        appBar: buildAppBar(context) as PreferredSizeWidget?,
        body: GestureDetector(
          onVerticalDragStart: (cursorPos) => yPos = cursorPos.localPosition.direction,
          onVerticalDragUpdate: (cursorPos) {
            if (cursorPos.delta.dy > 100)
              snapIndex = _snapIndex + 1;
            else if (cursorPos.delta.dy < -100) snapIndex = _snapIndex - 1;
            log.message('onVerticalDragUpdate $_snapIndex ${cursorPos.delta.dy}');
          },
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: <Widget>[
              Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
                IconButton(
                  onPressed: () {
                    _changeRanking(context);
                  },
                  icon: Icon(Icons.star, color: filterColors[currentSnap!.ranking!], size: 40.0),
                ),
                Text(
                  '${currentSnap!.caption ?? ''}\n${currentSnap!.location ?? ''}',
                  style: TextStyle(color: Colors.greenAccent.withOpacity(1.0), fontSize: 20),
                ),
              ]),
              Expanded(
                flex: 1,
                child: GestureDetector(
                  onVerticalDragEnd: (dragDetails){
                    if (dragDetails.primaryVelocity! < 0) { // swipe up
                      if (_snapIndex<snapList!.length-1) snapIndex=_snapIndex+1;
                    } else if (dragDetails.primaryVelocity! > 0) { // swipe down
                      if (_snapIndex>0) snapIndex = _snapIndex-1;
                    }
                  },
                  child: Transform.rotate(
                    angle: currentSnap!.angle,
                    child: PhotoViewerWithRect(
                      key: pvKey,
                      url: currentSnap!.fullSizeURL,
                      onScale: setIsPhotoScaled,
                    ), // of PhotoViewerWithRect
                  ), // of Transform
                ), // of GestureDetector
              ), // of Expanded
              if (_isClippingInProgress) Center(child: CircularProgressIndicator()),
            ],
          ),
        ));
  } // of build

  void setIsPhotoScaled(bool value) {
    log.message('Scaling $value');
//    setState(() {
    isPhotoScaled = value;
//    });
  }

  void cropMe(BuildContext context, AopSnap? snap) async {
    if (isPhotoScaled)
      showMessage(context, 'Nothing to do. \nZoom before clicking',
          title: 'Picture is all showing');
    else {
      try {
        isClippingInProgress = true;
        await snapCrop(
            context,
            snap,
            (pvKey.currentWidget as PhotoViewerWithRect)
                .currentRect(Size(0.0 + snap!.width!, 0.0 + snap.height!)));
      } catch (ex, stack) {
        showMessage(context, '$ex \n $stack', title: 'Failed to clip');
      } finally {
        isClippingInProgress = false;
      } // of try
//      Navigator.pop(context,{});
    }
  } // of cropMe

  Future<AopSnap?> snapCrop(BuildContext context, AopSnap? originalSnap, Rect? rect) async {
    if (rect == null) return null;
    try {
      Im.Image originalImage = (await loadWebImage(originalSnap!.fullSizeURL))!;
      log.message('clipping ${originalSnap.fileName} ${originalImage.length}');
      Im.Image newFullImage = Im.copyCrop(originalImage, rect.right.round(), rect.top.round(),
          (rect.left - rect.right).round(), (rect.bottom - rect.top).round());
      Im.Image newThumbnail = Im.copyResize(newFullImage,
          width: (originalImage.width >= originalImage.height) ? 640 : 480);
      Map<String,dynamic> buffer = originalSnap.toMap();
      buffer.remove('id'); //
      var newSnap = AopSnap(data:buffer);
      // sourceMarker is used for tracking where photos came from
      String sourcerMarker = 'Crop+${originalSnap.id}';
      newSnap.fileName = await calcNewFilenameForSnap(originalSnap, sourcerMarker);
      Map<String, dynamic> metaMap = jsonDecode(originalSnap.metadata!);
      metaMap['width'] = newFullImage.width;
      metaMap['height'] = newFullImage.height;
      metaMap['cropped'] = formatDate(DateTime.now());
      newSnap.metadata = jsonEncode(metaMap);
      newSnap.importSource = sourcerMarker;
      log.message('clipping saving thumbnail');
      await saveWebImage(newSnap.thumbnailURL, image: newThumbnail);
      log.message('clipping saving fullimage');
      await saveWebImage(newSnap.fullSizeURL, image: newFullImage);
      log.message('clipping saving mketa');
      await saveWebImage(newSnap.metadataURL, metaData: newSnap.metadata);
      log.message('clipping saving db');
      await newSnap.save();
      snapList!.add(newSnap);
      // is it part of the current album. If so add it to album
      if (maybeCurrentAlbum != null) {
        AopAlbumItem item = AopAlbumItem(data:{});
        item.albumId = maybeCurrentAlbum!.id;
        item.snapId = newSnap.id;
        await item.save();
        maybeCurrentAlbum!.albumItems.then((list) => list.add(item));
        maybeCurrentAlbum!.snaps.then((list) => list.add(newSnap));
      }
      showMessage(context, 'Cropping to ${newSnap.fileName} completed');
      return newSnap;
    } on Exception catch (ex) {
      showMessage(context, 'Failed to crop image : $ex');
      return null;
    }
  }

  Future<String> calcNewFilenameForSnap(AopSnap snap, String sourceMarker) async {
    int previousCrops = (await AopSnap.getPreviousCropCount(sourceMarker));
    int dotPos = snap.fileName!.lastIndexOf('.');
    if (dotPos < 0) throw 'Failed to get extention of ${snap.fileName}';
    String result = '${snap.fileName!.substring(0, dotPos)}_cp${previousCrops + 1}${snap.fileName!.substring(dotPos)}';
    return result;
  } // of calcNewFilenameForSnap

  void showExif(BuildContext context, AopSnap thisSnap) {
    Navigator.of(context);
    Map<String, dynamic> tags = jsonDecode(thisSnap.metadata!);
    String tagResult = '';
    tags.forEach((k, v) => tagResult += '$k = $v \n');
    showMessage(context, tagResult, title: 'Exif for ${thisSnap.fileName}');
  } // of showExif

  void showThumbnailExif(BuildContext context, AopSnap thisSnap) async {
    Navigator.of(context);
    List<int> fileContents = await loadWebBinary(thisSnap.thumbnailURL);
    JpegLoader jpegLoader = JpegLoader();
    await jpegLoader.extractTags(fileContents);
    Map<String, dynamic> tags = jpegLoader.tags;
    String tagResult = '';
    if (tags.isEmpty)
      tagResult = 'NO EXIF DATA';
    else
      tags.forEach((k, v) => tagResult += '$k = $v \n');
    showMessage(context, tagResult, title: 'Exif for Thumbnail of ${thisSnap.fileName}');
  } // of showExif
}

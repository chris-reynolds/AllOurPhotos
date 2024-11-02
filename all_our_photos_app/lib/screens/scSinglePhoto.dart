/*
  Created by chrisreynolds on 2019-09-18
  
  Purpose: Stateful SinglePhotoWidget
*/

import 'dart:convert';
//import 'dart:typed_data';
import 'package:aopmodel/aopmodel.dart';
//import 'package:flutter/widgets.dart';
import 'dart:math';
import '../utils/ExportPic.dart';
//import '../widgets/PhotoViewWithRectWidget.dart';
import 'package:flutter/material.dart';
// import 'package:image/image.dart' as Im;
import 'package:aopcommon/aopcommon.dart';
import 'package:aopmodel/aop_classes.dart';
import '../flutter_common/WidgetSupport.dart';
import '../widgets/wdgImageFilter.dart'; // only for the icons
import '../widgets/wdgClipper.dart';
import '../widgets/wdgImageRotator.dart';

//import 'package:http/http.dart' as http;
//import 'package:http_parser/http_parser.dart';

class SinglePhotoWidget extends StatefulWidget {
  const SinglePhotoWidget({super.key});

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
  bool isRotatorVisible = false;
  bool _isClippingInProgress = false;
  Rect? _currentCroppingRect;

  set isClippingInProgress(bool value) {
    //setState(() {
    _isClippingInProgress = value;
    // });
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

  Future<void> _doDownload(BuildContext context) async {
    try {
      var success = await ExportPic.export(currentSnap!, 'AllOurPhotos');
      if (!success) showMessage(context, "Download failed");
    } catch (ex) {
      log.error('$ex');
      showMessage(context, '$ex');
    }
  } // of download

  Widget? buildAppBar(BuildContext context) {
    if (isRotatorVisible) return null; // no app bar wile doing rotation
    return AppBar(
      leading: MyIconButton(Icons.arrow_back, onPressed: () {
        Navigator.pop(context);
      }),
      actions: [
        Spacer(),
        if (!UIPreferences.isSmallScreen)
          Text('${currentSnap!.fileName} ${currentSnap!.caption}'),
        MyIconButton(Icons.star, onPressed: () {
          _changeRanking(context);
        }, color: filterColors[currentSnap!.ranking!]),
        MyIconButton(
          Icons.arrow_upward,
          enabled: (_snapIndex > 0),
          onPressed: () {
            snapIndex = _snapIndex - 1;
          },
        ),
        MyIconButton(Icons.arrow_downward,
            enabled: (_snapIndex < snapList!.length - 1), onPressed: () {
          snapIndex = _snapIndex + 1;
        }),
        MyIconButton(Icons.edit, onPressed: () async {
          await Navigator.pushNamed(context, 'MetaEditor',
              arguments: currentSnap);
          setState(() {}); //force repaint on return
        }), // edit iconButton
        MyIconButton(
          Icons.sync,
          onPressed: () async {
            setState(() {
              isRotatorVisible = true;
            });
          },
        ),
        // MyIconButton(
        //   Icons.rotate_left,
        //   onPressed: () async {
        //     currentSnap!.rotate(-1);
        //     _saveWithError(context);
        //   },
        // ),
        // MyIconButton(
        //   Icons.rotate_right,
        //   onPressed: () async {
        //     currentSnap!.rotate(1);
        //     _saveWithError(context);
        //   },
        // ),
        MyIconButton(
          Icons.download_outlined,
          onPressed: () async {
            await _doDownload(context);
          },
        ),
        MyIconButton(Icons.crop, onPressed: () {
          cropMe(context, currentSnap!);
        }),
        MyIconButton(Icons.list, onPressed: () {
          showExif(context, currentSnap!);
        }),
      ], // of actions
    );
  } // of buildAppbar

  @override
  Widget build(BuildContext context) {
    // TODO:  restore swipes for single photo
    if (snapList == null)
      _initParams(); // can't get params until we have a context!!!!
    currentSnap = snapList![_snapIndex];
    var thisURL = currentSnap!.fullSizeURL;
    thisURL += '?fred=${Random().nextInt(1000)}';
    log.message('single photo $thisURL');
    return Scaffold(
        appBar: buildAppBar(context) as PreferredSizeWidget?,
        body: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            if (!isRotatorVisible)
              Expanded(
                child: Clipper(
                  imageUrl: thisURL,
                  rectCallback: currentRect,
                  canCropCallBack: canCropCallback,
                  // verticalSwipeCallBack: (value) {
                  //   snapIndex = _snapIndex + ((value < 0) ? 1 : -1);
                  // },
                  show: (s) => log
                      .message('------------------ $s ---------------------'),
                ),
              ),
            if (isRotatorVisible && currentSnap != null)
              Expanded(
                  child: ImageRotator(
                snap: currentSnap!,
                closeRotator: () {
                  setState(() {
                    isRotatorVisible = false;
                  });
                },
              )),
//        buildAppBar(context),
            if (_isClippingInProgress)
              Center(child: CircularProgressIndicator()),
          ],
//          ),
        ));
  } // of build

  void canCropCallback(bool value) {
    isPhotoScaled = value;
  } // of canCropCallback

  void currentRect(Rect rect) {
    _currentCroppingRect = rect; // passed up from the cropping widget
  }

  void setIsPhotoScaled(bool value) {
    log.message('Scaling $value');
//    setState(() {
    isPhotoScaled = value;
//    });
  }

  void cropMe(BuildContext context, AopSnap snap) async {
    if (!isPhotoScaled)
      showMessage(context, 'Nothing to do. \nZoom before clicking',
          title: 'Picture is all showing');
    else {
      Stopwatch stopwatch = Stopwatch()..start();
      try {
        isClippingInProgress = true;
        // await snapCrop(context, snap, _currentCroppingRect);
        var cropArea = _currentCroppingRect!;
        var croppedSnap = await AopSnap.snapCropper(
            snap.id!,
            cropArea.left.toInt(),
            cropArea.top.toInt(),
            cropArea.right.toInt(),
            cropArea.bottom.toInt());
        snapList!.insert(_snapIndex + 1, croppedSnap);
        snapIndex = _snapIndex + 1; // force a repaint
      } catch (ex, stack) {
        showMessage(
            context, '$ex \n ${cleanUpLines(stack.toString(), 'dart-sdk')}',
            title: 'Failed to crop');
      } finally {
        isClippingInProgress = false;
        log.message('cropping took ${stopwatch.elapsed}');
      } // of try
    }
  } // of cropMe

  // Future<AopSnap?> snapCrop(
  //     BuildContext context, AopSnap? originalSnap, Rect? rect) async {
  //   if (rect == null) return null;
  //   try {
  //     log.message('re-loading ${originalSnap!.fileName}');
  //     Im.Image originalImage = (await loadWebImage(originalSnap.fullSizeURL))!;
  //     // num degreesRotation = double.parse(originalSnap.rotation ?? '0') * 90;
  //     // if (degreesRotation.abs() > 1e-1) {
  //     //   originalImage = Im.copyRotate(originalImage, angle: degreesRotation);
  //     //   log.message('rotated before crop');
  //     // }
  //     log.message('clipped ${originalSnap.fileName} ${originalImage.length} '
  //         ' width:${originalImage.width} height:${originalImage.height}');
  //     Im.Image newFullImage = Im.copyCrop(originalImage,
  //         x: rect.right.round(),
  //         y: rect.top.round(),
  //         width: (rect.right - rect.left).round(),
  //         height: (rect.bottom - rect.top).round());
  //     // sourceMarker is used for tracking where photos came from
  //     log.message('clipped ${originalSnap.fileName} ${newFullImage.length} '
  //         'right:${rect.right} top:${rect.top} width:${newFullImage.width} height:${newFullImage.height}');
  //     String sourceMarker = 'Crop+${originalSnap.id}';
  //     String newFilename =
  //         await calcNewFilenameForSnap(originalSnap, sourceMarker);
  //     Map<String, dynamic> metaMap = jsonDecode(originalSnap.metadata!);
  //     metaMap['width'] = newFullImage.width;
  //     metaMap['height'] = newFullImage.height;
  //     metaMap['cropped'] = formatDate(DateTime.now());
  //     Uint8List payload = Im.encodeJpg(newFullImage);
  //     String uploadResult = await uploadImage4(
  //         newFilename, DateTime.now(), payload, sourceMarker);
  //     if (uploadResult.startsWith('Error')) throw uploadResult;
  //     AopSnap newSnap = AopSnap(data: jsonDecode(uploadResult));
  //     snapList!.add(newSnap);
  //     // is it part of the current album. If so add it to album
  //     if (maybeCurrentAlbum != null) {
  //       AopAlbumItem item = AopAlbumItem(data: {});
  //       item.albumId = maybeCurrentAlbum!.id;
  //       item.snapId = newSnap.id;
  //       await item.save();
  //       maybeCurrentAlbum!.albumItems.then((list) => list.add(item));
  //       maybeCurrentAlbum!.snaps.then((list) => list.add(newSnap));
  //     }
  //     showMessage(context, 'Cropping to ${newSnap.fileName} completed');
  //     return newSnap;
  //   } on Exception catch (ex) {
  //     showMessage(context, 'Failed to crop image : $ex');
  //     return null;
  //   }
  // }

  // Future<String> uploadImage4(String imageName, DateTime modifiedDate,
  //     Uint8List fileContents, String importSource) async {
  //   try {
  //     String fileDateStr =
  //         formatDate(modifiedDate, format: 'yyyy:mm:dd hh:nn:ss');
  //     var postUrl =
  //         "${WebFile.rootUrl}upload2/$fileDateStr/$imageName/$importSource";
  //     var request = http.MultipartRequest("POST", Uri.parse(postUrl));
  //     request.headers
  //         .addAll({'Accept': 'application/json', 'Preserve': WebFile.preserve});
  //     request.files.add(http.MultipartFile.fromBytes('myfile', fileContents,
  //         filename: 'not_used_filename_on_url',
  //         contentType: MediaType('image', 'jpeg')));
  //     // request.files.add(await http.MultipartFile.fromPath('myfile', filePath));
  //     var response = await request.send();
  //     var responseBody = await response.stream.bytesToString();
  //     if (response.statusCode == 200) {
  //       log.debug("Uploaded $imageName");
  //       return responseBody;
  //     } else {
  //       log.error(
  //           'Failed to upload $imageName  - code ${response.statusCode}\n $responseBody');
  //       return "Error: $imageName \n reason: $responseBody"; // signal error
  //     }
  //   } catch (ex, st) {
  //     log.error('$ex\n$st');
  //     return "Error $imageName exception \n reason: '$ex\n$st"; // signal error
  //   }
  // } //of uploadImageFile

  // Future<String> calcNewFilenameForSnap(
  //     AopSnap snap, String sourceMarker) async {
  //   int previousCrops = (await AopSnap.getPreviousCropCount(sourceMarker));
  //   int dotPos = snap.fileName!.lastIndexOf('.');
  //   if (dotPos < 0) throw 'Failed to get extention of ${snap.fileName}';
  //   String result =
  //       '${snap.fileName!.substring(0, dotPos)}_cp${previousCrops + 1}${snap.fileName!.substring(dotPos)}';
  //   return result;
  // } // of calcNewFilenameForSnap

  void showExif(BuildContext context, AopSnap thisSnap) {
    Navigator.of(context);
    Map<String, dynamic> tags = jsonDecode(thisSnap.metadata!);
    String tagResult = '';
    tags.forEach((k, v) => tagResult += '$k = $v \n');
    showMessage(context, tagResult, title: 'Exif for ${thisSnap.fileName}');
  } // of showExif

  // void showThumbnailExif(BuildContext context, AopSnap thisSnap) async {
  //   Navigator.of(context);
  //   List<int> fileContents = await loadWebBinary(thisSnap.thumbnailURL);
  //   JpegLoader jpegLoader = JpegLoader();
  //   await jpegLoader.extractTags(fileContents);
  //   Map<String, dynamic> tags = jpegLoader.tags;
  //   String tagResult = '';
  //   if (tags.isEmpty)
  //     tagResult = 'NO EXIF DATA';
  //   else
  //     tags.forEach((k, v) => tagResult += '$k = $v \n');
  //   showMessage(context, tagResult,
  //       title: 'Exif for Thumbnail of ${thisSnap.fileName}');
  // } // of showExif
}

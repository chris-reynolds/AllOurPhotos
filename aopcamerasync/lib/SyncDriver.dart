/*
  Created by chrisreynolds on 2019-09-27
  
  Purpose: This is the actual sync driving engine

*/

import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:meta/meta.dart';
import 'package:image/image.dart';
import 'shared/aopClasses.dart';
import 'dart_common/Logger.dart' as Log;
import 'dart_common/Config.dart';
import 'dart_common/JpegLoader.dart';
import 'dart_common/Geocoding.dart';
import 'dart_common/DateUtil.dart';
import 'dart_common/WebFile.dart';
import 'dart_common/ImageUploader.dart';

class SyncDriver {
  String localFileRoot;
  DateTime fromDate;
  StreamController<String> messageController = StreamController<String>();

  SyncDriver({@required this.localFileRoot, this.fromDate});

  String fileName(String path) => (path.lastIndexOf('/') > 0)
      ? path.substring(path.lastIndexOf('/') + 1)
      : path.substring(path.lastIndexOf('\\') + 1);

  Future<List<FileSystemEntity>> loadFileList() async {
    messageController.add('Loading from ${formatDate(fromDate)}');
    Stream<FileSystemEntity> origin = Directory(localFileRoot).list(recursive: true);
    List<FileSystemEntity> result = [];
    int totalChecked = 0;
    await for (var fse in origin) {
      totalChecked += 1;
      FileStat stats = fse.statSync();
      // use 'continue' to jump to the end of the loop and not save this file to the list.
      if (stats.size < 8096) continue; // too small
      if (stats.modified.isBefore(fromDate)) continue;
      if (fse.path.contains('thumbnails')) continue;
      if (fse.path.contains('shrink_')) continue;
      String thisExt = fse.path.substring(fse.path.length - 3).toLowerCase();
      if (['jpg', 'png'].contains(thisExt) == false) continue;
      String imageName = fileName(fse.path);
//      Log.message('checking $imageName');
      bool alreadyExists =
          await AopSnap.sizeOrNameOrDeviceAtTimeExists(stats.modified, stats.size, imageName, 'no');
      if (alreadyExists) continue;
      alreadyExists = await AopSnap.nameExists(imageName, stats.size);
      if (alreadyExists) continue;
      Log.message('Maybe add ${imageName} size=${stats.size} modified=${stats.modified}');
      result.add(fse);
    }
    Log.message('Found ${result.length} new pictures, skipped ${totalChecked - result.length}');
    return result; // finished the where filter
  } // loadFileList

  void processList(List<FileSystemEntity> fileList) async {
    Log.message('Start processing ${fileList.length} pictures');
    String fullPath;
    int sofar = 0;
    for (FileSystemEntity fse in fileList) {
      try {
        sofar += 1;
        fullPath = (fse as File).path;
        if (await uploadFile(fse as File)) {
          Log.message('added $fullPath OK');
          messageController.add('added $fullPath   ${sofar} of ${fileList.length}');
        } else {
          Log.message('Skipped  upload $fullPath ');
          messageController.add('Skipped $fullPath ${sofar} of ${fileList.length}');
        }
      } catch (ex) {
        Log.error('Failed to upload $fullPath with $ex');
      }
    }
    messageController.add('Processed-complete');
  } // of processList

//  Future<bool> uploadImage(File thisPicFile) async {
//    //   String tagDeviceName;
//    try {
//      FileStat thisPicStatsx = thisPicFile.statSync();
//      List<int> fileContents = thisPicFile.readAsBytesSync();
//      Image thisImage = decodeImage(fileContents);
//      String imageName = fileName(thisPicFile.path);
//      Log.message('uploading $imageName');
//      GeocodingSession _geo = GeocodingSession();
//      JpegLoader jpegLoader = JpegLoader();
//      await jpegLoader.extractTags(fileContents);
//      String deviceName = jpegLoader.tag('Model') ?? config['sesdevice'];
//      DateTime takenDate = dateTimeFromExif(jpegLoader.tag('dateTimeOriginal')) ??
//          jpegLoader.tag('dateTime') ??
//          thisPicStats.modified;
//
//      bool alReadyExists = await AopSnap.sizeOrNameOrDeviceAtTimeExists(
//          takenDate, thisImage.length, imageName, deviceName);
//      if (alReadyExists) return false;
//      AopSnap newSnap = AopSnap()
//        ..fileName = imageName
//        ..directory = '1982-01'
//        ..width = thisImage.width
//        ..height = thisImage.height
//        ..takenDate = takenDate
//        ..modifiedDate = thisPicStats.modified
//        ..deviceName = deviceName
//        ..rotation = '0' // todo support enumeration
//        ..importSource = deviceName
//        ..importedDate = DateTime.now();
//
//      bool isScanned =
//          ((jpegLoader.tag('device.software') ?? '').toLowerCase().indexOf('scan') >= 0);
//      newSnap.importSource += isScanned ? ' scanned' : ' camera roll';
//
//      newSnap.originalTakenDate = newSnap.takenDate;
//      newSnap.directory = formatDate(newSnap.originalTakenDate, format: 'yyyy-mm');
//      // checkl for duplicate
//      newSnap.mediaLength = thisPicStats.size;
//      if (jpegLoader.tag("GPSLatitudeRef") != null) {
//        newSnap.latitude =
//            jpegLoader.dmsToDeg(jpegLoader.tag('GPSLatitude'), jpegLoader.tag('GPSLatitudeRef'));
//        newSnap.longitude =
//            jpegLoader.dmsToDeg(jpegLoader.tag('GPSLongitude'), jpegLoader.tag('GPSLongitudeRef'));
//      }
//      if (newSnap.latitude != null) {
//        String location = await _geo.getLocation(newSnap.longitude, newSnap.latitude);
//        if (location != null) newSnap.trimSetLocation(location);
//      }
//
//      if (newSnap.originalTakenDate != null && newSnap.originalTakenDate.year > 1980) {
//        if (await AopSnap.dateTimeExists(newSnap.originalTakenDate, newSnap.mediaLength))
//          return false;
//      } else {
//        if (await AopSnap.nameExists(newSnap.fileName, newSnap.mediaLength)) return false;
//      }
//      // all looks good to upload but it might be a different picture with the same name and month
//      if (await newSnap.nameClashButDifferentSize()) {
//        int lastDot = newSnap.fileName.lastIndexOf('.');
//        if (lastDot < 0) throw "Cant find the extension of file name ${newSnap.fileName}";
//        newSnap.fileName =
//            newSnap.fileName.substring(0, lastDot) + 'a' + newSnap.fileName.substring(lastDot);
//      }
//      String myMeta = jsonEncode(jpegLoader.tags);
//      Image thumbnail = copyResize(thisImage, width: (newSnap.width > newSnap.height) ? 640 : 480);
//      await saveWebImage(newSnap.thumbnailURL, image: thumbnail, quality: 50);
//      await saveWebImage(newSnap.fullSizeURL, image: thisImage);
//      await saveWebImage(newSnap.metadataURL, metaData: myMeta);
//      newSnap.metadata = myMeta;
//      await newSnap.save();
//      return true;
//    } catch (ex, st) {
//      Log.error('Failed save for ${thisPicFile.path} \n$ex \n$st');
//      return false;
//    } // of try
//  } // of uploadImage

} // of syncDriver

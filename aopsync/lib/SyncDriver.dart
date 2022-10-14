/*
  Created by chrisreynolds on 2019-09-27
  
  Purpose: This is the actual sync driving engine

*/

import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:meta/meta.dart';
import 'package:image/image.dart';
import 'package:aopcommon/aopcommon.dart';
// import 'package:device_info/device_info.dart';
import 'shared/aopClasses.dart';


class SyncDriver {
  String localFileRoot;
  DateTime fromDate;
  GeocodingSession _geo = GeocodingSession();
  StreamController<String> messageController = StreamController<String>();

  SyncDriver({@required this.localFileRoot, this.fromDate});

  String fileName(String path) => (path.lastIndexOf('/') > 0)
      ? path.substring(path.lastIndexOf('/') + 1)
      : path.substring(path.lastIndexOf('\\') + 1);
  
  Future<List<FileSystemEntity>> loadFileList(DateTime fromDate) async {
//    if (allPhotos) fromDate = DateTime(1900);
    logAndDisplay('Loading from ${formatDate(fromDate)}');
    Stream<FileSystemEntity> origin = Directory(localFileRoot).list(recursive: true);
    List<FileSystemEntity> result = [];
    List<DateTime> resultDates = [];  // parallel array for sorting
    int totalChecked = 0;
    int priorImages = 0;
    await for (var fse in origin) {
      String imageName = fileName(fse.path);
      if (imageName.startsWith('\.'))   continue;  // skip all that start with .
      FileStat stats = fse.statSync();
      // use 'continue' to jump to the end of the loop and not save this file to the list.
      if (stats.modified.isBefore(fromDate)) {
        priorImages += 1;
        continue;
      }
      totalChecked += 1;
      if (fse.path.indexOf('thumbnails') >= 0) continue;
      String thisExt = fse.path.substring(fse.path.length - 3).toLowerCase();
      if (['jpg', 'png'].indexOf(thisExt) < 0) continue;
      //log.message('checking $imageName');
      bool alreadyExists = await AopSnap.nameSameDayExists(stats.modified, imageName );
      if (alreadyExists) {
        log.message('skipping $imageName size=${stats.size} modified=${stats.modified}');
        continue;
      }
      log.message('adding $imageName size=${stats.size} modified=${stats.modified}');
      result.add(fse);
      resultDates.add(stats.modified);
    } //
    logAndDisplay('Sorting ${result.length}');
    DateTime swapDate;
    FileSystemEntity swapFse;
    for (int i=0; i<result.length; i++) {
      for (int j=i+1; j<result.length;j++) {
        if (resultDates[i].isAfter(resultDates[j])) {
          swapDate= resultDates[i]; resultDates[i]=resultDates[j]; resultDates[j]=swapDate;
          swapFse = result[i]; result[i]=result[j]; result[j]=swapFse;
        }
      }
    }
    logAndDisplay('Sorted ${result.length}');
    log.message('Found ${result.length} new pictures, skipped ${totalChecked - result.length}. Prior images=$priorImages ');
    return result; // finished the where filter
  } // loadFileList

  
  void logAndDisplay(String message) {
    messageController.add(message);
    log.message(message);
  } // of logAndDisplay
  

  Future<bool> uploadImageFile(File thisPicFile) async {
    FileStat thisPicStats = thisPicFile.statSync();
    List<int> fileContents = thisPicFile.readAsBytesSync();
    String imageName = fileName(thisPicFile.path);
    return await uploadImage(imageName, thisPicStats.modified, fileContents);
  }

  Future<bool> uploadImage(String imageName, DateTime createdDate, List<int> fileContents, {JpegLoader jpegLoader}) async {
    try {
      log.message('Start processing $imageName ------------------------------------------');
      if (await AopSnap.sizeOrNameOrDeviceAtTimeExists(createdDate, 0, imageName, 'vvvgnv')) {
        log.message('fast dup check - true');
        return null;
      }
      Image thisImage = decodeImage(fileContents);
      log.message('decoded');
      List<int> jpeg = encodeJpg(thisImage, quality: 100);
      int imageSize = jpeg.length; // decode/encode seems to be the only way to get reliable length
      log.message('encoded $imageName');
      if (jpegLoader==null)
        jpegLoader = JpegLoader();
//      JpegLoader jpegLoader = loader ?? JpegLoader();
      if (jpegLoader.tags.isEmpty)   // IOS should have preped these earlier
        await jpegLoader.extractTags(fileContents);
      log.message('extracted tags $imageName }');
      String deviceName = jpegLoader.tag('Model')  ?? config['sesdevice'];
      String importSource = config['sesdevice'] ?? jpegLoader.tag('Model');
//      DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
//
//      if (!Platform.isIOS) {
//        AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
//        deviceName = androidInfo.device;
////      print('Running on ${androidInfo.model}');  // e.g. "Moto G (4)"
//      } else {
//        IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
//        deviceName = iosInfo.name;
////      print('Running on ${iosInfo.utsname.machine}');  // e.g. "iPod7,1"
//      }

      DateTime takenDate = dateTimeFromExif(jpegLoader.tag('dateTimeOriginal')) ?? createdDate;
      log.message('check for dup-1');
      bool alReadyExists =
          await AopSnap.sizeOrNameOrDeviceAtTimeExists(takenDate, imageSize, imageName, deviceName);
      if (alReadyExists) {
        log.message('sizeOrNameOrDeviceAtTimeExists');
        return null;
      }
        AopSnap newSnap = AopSnap()
          ..fileName = imageName
          ..directory = '1982-01'
          ..width = thisImage.width
          ..height = thisImage.height
          ..takenDate = takenDate
          ..modifiedDate = createdDate
          ..deviceName = deviceName
          ..rotation = '0' // todo support enumeration
          ..importSource = importSource
          ..importedDate = DateTime.now();

        if ((jpegLoader.tag('device.software') ?? '').toLowerCase().indexOf('scan') >= 0)
          newSnap.importSource += ' scanned';

        newSnap.originalTakenDate = newSnap.takenDate;
        newSnap.directory = formatDate(newSnap.originalTakenDate, format: 'yyyy-mm');
        // checkl for duplicate
        newSnap.mediaLength = imageSize;
        if (jpegLoader.tag("GPSLatitudeRef") != "null") {
          newSnap.latitude =
              jpegLoader.dmsToDeg(jpegLoader.tag('GPSLatitude'), jpegLoader.tag('GPSLatitudeRef'));
          newSnap.longitude =
              jpegLoader.dmsToDeg(jpegLoader.tag('GPSLongitude'), jpegLoader.tag('GPSLongitudeRef'));
        }
        if (newSnap.latitude != null && newSnap.latitude.abs()>1e-6) {
          String location = await _geo.getLocation(newSnap.longitude, newSnap.latitude);
          if (location != null) newSnap.trimSetLocation(location);
          log.message('found location : ${newSnap.location}');
        }

        if (newSnap.originalTakenDate != null && newSnap.originalTakenDate.year > 1980) {
          if (await AopSnap.dateTimeExists(newSnap.originalTakenDate, newSnap.mediaLength)) {
            log.message('duplicate dateTime+length');
            return null;
          }
        }
          if (await AopSnap.nameExists(newSnap.fileName, newSnap.mediaLength)) {
            log.message('duplicate name+length');
            return null;
          }
        jpegLoader.cleanTags();
        String myMeta = jsonEncode(jpegLoader.tags);
        Image thumbnail = copyResize(thisImage, width: (newSnap.width > newSnap.height) ? 640 : 480);
        log.message('made thumbnail');
        await saveWebImage(newSnap.thumbnailURL, image: thumbnail, quality: 50);
        log.message('-> thumbnail');
        await saveWebImage(newSnap.fullSizeURL, image: thisImage);
        log.message('-> full image');
        await saveWebImage(newSnap.metadataURL, metaData: myMeta);
        log.message('-> meta');
        newSnap.metadata = myMeta;
        await newSnap.save();
      log.message('-> database');

      return true;

    } catch (ex,st) {
      log.error('Failed save for $imageName - $ex \n$st\n\n');
      return false;
    } // of try
  } // of uploadImage

} // of syncDriver

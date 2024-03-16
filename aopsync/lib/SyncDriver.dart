/*
  Created by chrisreynolds on 2019-09-27
  
  Purpose: This is the actual sync driving engine for aopsync

*/

import 'dart:async';
import 'dart:io';
import 'dart:convert';
//import 'dart:js_interop';
// import 'package:meta/meta.dart';
//import 'package:image/image.dart';
import 'package:aopcommon/aopcommon.dart';
// import 'package:device_info/device_info.dart';
import 'package:aopmodel/aopmodel.dart';
import 'package:aopsync/fileFate.dart';
import 'utils/Config.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

class SyncDriver {
  static final supportedMediaTypes = <String, MediaType>{
    'jpg': MediaType('image', 'jpeg'),
    'png': MediaType('image', 'png')
  };
  String localFileRoot;
  DateTime fromDate;
  // final GeocodingSession _geo = GeocodingSession();
  StreamController<String> messageController = StreamController<String>();

  SyncDriver({required this.localFileRoot, required this.fromDate});

  DateTime? dateTimeFromFilename(String filename) {
    RegExp regYymmdd = RegExp(r'\d{8}_\d{6}');
    String? embeddedDate = regYymmdd.stringMatch(filename);
    if (embeddedDate != null) {
      return DateTime.tryParse(embeddedDate.replaceAll('_', 'T'));
    } else {
      return null;
    }
  } // of dateTimeFromFilename

  Future<List<File>> loadFileList(DateTime fromDate) async {
//    if (allPhotos) fromDate = DateTime(1900);
    logAndDisplay(
        'Loading files from $localFileRoot with date after ${formatDate(fromDate)}');
    Stream<FileSystemEntity> origin =
        Directory(localFileRoot).list(recursive: true);
    List<File> result = [];
    List<DateTime> resultDates = []; // parallel array for sorting
    int totalChecked = 0;
    int priorImages = 0;
    await for (var fse in origin) {
      String imageName = onlyFileName(fse.path);
      if (imageName.startsWith('.')) continue; // skip all that start with .
      log.message('checking $imageName');
      DateTime fileDate =
          dateTimeFromFilename(imageName) ?? fse.statSync().modified;
      // use 'continue' to jump to the end of the loop and not save this file to the list.
      if (fileDate.isBefore(fromDate)) {
        priorImages += 1;
        continue;
      }
      if (fse.path.contains('thumbnails')) continue;
      String thisExt = fse.path.split('.').last.toLowerCase();
      if (!supportedMediaTypes.containsKey(thisExt)) continue;
      totalChecked += 1;
      bool alreadyExists =
          (await AopSnap.nameSameDayExists(fileDate, imageName))!;
      if (alreadyExists) {
        log.message('skipping $imageName  date=$fileDate');
        continue;
      }
      log.message('adding $imageName date=$fileDate');
      result.add(fse as File);
      resultDates.add(fileDate);
    } //
//    logAndDisplay('Sorting ${result.length}');
    // don't us sort function because we have a result and a resultDate array to reduce calls to 'stat'
    DateTime swapDate;
    File swapFse;
    for (int i = 0; i < result.length; i++) {
      for (int j = i + 1; j < result.length; j++) {
        if (resultDates[i].isAfter(resultDates[j])) {
          swapDate = resultDates[i];
          resultDates[i] = resultDates[j];
          resultDates[j] = swapDate;
          swapFse = result[i];
          result[i] = result[j];
          result[j] = swapFse;
        }
      }
    }
    logAndDisplay('Sorted ${result.length}');
    log.message(
        'Found ${result.length} new pictures, skipped ${totalChecked - result.length}. Prior images=$priorImages ');
    return result; // finished the where filter
  } // loadFileList

  void logAndDisplay(String message) {
    messageController.add(message);
    log.message(message);
  } // of logAndDisplay

  Future<String> streamToString(Stream stream) async {
    StringBuffer sb = StringBuffer();
    await for (var data in stream.transform(utf8.decoder)) sb.write(data);
    return sb.toString();
  } // of streamToString

  // Future<bool?> uploadImageFile(File thisPicFile) async {
  //   FileStat thisPicStats = thisPicFile.statSync();
  //   List<int> fileContents = thisPicFile.readAsBytesSync();
  //   String imageName = onlyFileName(thisPicFile.path);
  //   return await uploadImage2(
  //       imageName, thisPicStats.modified, thisPicFile.path, fileContents);
  // }

  Future<FileFate> uploadImage2(String imageName, DateTime modifiedDate,
      String filename, List<int> fileContents) async {
    String thisDevice = config['sesdevice'];
    String fileDateStr =
        formatDate(modifiedDate, format: 'yyyy:mm:dd hh:nn:ss');
    var postUrl =
        "http://localhost:8000/upload2/$fileDateStr/$imageName/$thisDevice";
    var request = http.MultipartRequest("POST", Uri.parse(postUrl));
    request.headers.addAll({
      'Accept': 'application/json',
      'Preserve': '{"jam":"$modelSessionid"}'
    });
    // request.files.add(http.MultipartFile.fromBytes('myfile', fileContents,
    //     contentType: MediaType('image', 'jpeg')));
    request.files.add(await http.MultipartFile.fromPath('myfile', filename,
        contentType: MediaType('image', 'jpeg')));
    var response = await request.send();
    if (response.statusCode == 200) {
      log.message("Uploaded $imageName");
      return FileFate(imageName, Fate.Uploaded);
    } else {
      var errorMessage = await streamToString(response.stream);
      log.error(
          'Failed to upload $imageName  - code ${response.statusCode}\n $errorMessage');
      if (errorMessage.contains('Duplicate entry'))
        return FileFate(imageName, Fate.Duplicate,
            reason: errorMessage); // signal dup
      else
        return FileFate(imageName, Fate.Error,
            reason: errorMessage); // signal error
    }
  } //of uploadImageFile
} // of syncDriver

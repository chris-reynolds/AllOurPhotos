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

typedef FileAnDate = ({DateTime date, File file});
typedef ProgressIndicator = void Function(int current, int max);

class SyncDriver {
  static Map<String, MediaType> supportedMediaTypes = {};
  String localFileRoot;
  List<FileAnDate> latestFileList = [];
  StreamController<String> messageStream;
  ProgressIndicator indicateProgress;
  SyncDriver(
      {required this.localFileRoot,
      required this.messageStream,
      required this.indicateProgress}); //, required this.fromDate});

  void clear() {
    latestFileList.clear();
  }

  DateTime? dateTimeFromFilename(String filename) {
    RegExp regYymmdd = RegExp(r'\d{8}_\d{6}');
    String? embeddedDate = regYymmdd.stringMatch(filename);
    if (embeddedDate != null) {
      return DateTime.tryParse(embeddedDate.replaceAll('_', 'T'));
    } else {
      return null;
    }
  } // of dateTimeFromFilename

  DateTime dateTimeFromFile(File file) {
    DateTime? dt = dateTimeFromFilename(file.path);
    DateTime result = dt ?? FileStat.statSync(file.path).modified;
    return result;
  } // of dateTimeFromFile

  Future<void> loadFileList(
      DateTime fromDate, bool wantPhotos, bool wantVideos) async {
    supportedMediaTypes = {};
    if (wantPhotos) {
      supportedMediaTypes['jpg'] = MediaType('image', 'jpeg');
      supportedMediaTypes['png'] = MediaType('image', 'png');
    }
    if (wantVideos) {
      supportedMediaTypes['mp4'] = MediaType('video', 'mp4');
      supportedMediaTypes['mov'] = MediaType('video', 'mov');
    }

    // var processInfo = ProcessInfo.currentRss;
    // logAndDisplay('Memory usage 1: ${processInfo / (1024 * 1024)} MB');
    logAndDisplay(
        'Loading files from $localFileRoot with date after ${formatDate(fromDate)} -${supportedMediaTypes.keys.join(',')}');
    // load only files from
    List<FileSystemEntity> origin =
        await Directory(localFileRoot).list(recursive: true).where((fse) {
      return (fse is File) && dateTimeFromFile(fse).isAfter(fromDate);
    }).toList();
    // .where((fse) => !fse.path.toLowerCase().contains('thumbnail'))
    // .where((fse) => !onlyFileName(fse.path).startsWith('.')) // .trashed
    // .where((fse) => supportedMediaTypes
    //     .containsKey(onlyExtension(fse.path).toLowerCase()))
    // .toList();
    // processInfo = ProcessInfo.currentRss;
    // logAndDisplay('Memory usage 2: ${processInfo / (1024 * 1024)} MB');
    logAndDisplay('${origin.length} files found');
    for (var i = origin.length - 1; i >= 0; i--) {
      if (origin[i].path.toLowerCase().contains('thumbnail') ||
          onlyFileName(origin[i].path).startsWith('.') ||
          !supportedMediaTypes
              .containsKey(onlyExtension(origin[i].path).toLowerCase())) {
        origin.removeAt(i);
      }
    }
    // processInfo = ProcessInfo.currentRss;
    // logAndDisplay('Memory usage 3: ${processInfo / (1024 * 1024)} MB');
    logAndDisplay('${origin.length} files kept');
    List<FileAnDate> results = [];
    for (var fse in origin) {
      String imageName = onlyFileName(fse.path);
      log.debug('checking $imageName');
      DateTime fileDate = dateTimeFromFile(fse as File);
      log.debug('adding $imageName date=$fileDate');
      results.add((date: fileDate, file: fse));
    } //
    // processInfo = ProcessInfo.currentRss;
    // logAndDisplay('Memory usage 4: ${processInfo / (1024 * 1024)} MB');

    results.sort((a, b) => a.date.compareTo(b.date));
    logAndDisplay('Sorted ${results.length}');
    log.debug('Found ${results.length} items ');
    latestFileList = results;
    // processInfo = ProcessInfo.currentRss;
    // logAndDisplay('Memory usage 5: ${processInfo / (1024 * 1024)} MB');
  } // loadFileList

  void logAndDisplay(String message) {
    messageStream.add(message);
    log.message(message);
  } // of logAndDisplay

  int get count => latestFileList.length;

  Future<bool> processFilePhotos() async {
    int errCount = 0, dupCount = 0, upLoadCount = 0;
    String progressMessage = '';
    try {
      fateList.clear(); // clean history
      messageStream.add('File Processing in progress. Please wait...');
      for (int i = 0; i < latestFileList.length; i++) {
        File thisPicFile = latestFileList[i].file;
        logAndDisplay(
            'processing ${latestFileList[i].file.path} len=${latestFileList[i].file.lengthSync()}');
        DateTime thisPicDate = latestFileList[i].date;
        List<int> fileContents = thisPicFile.readAsBytesSync();
        String imageName = onlyFileName(thisPicFile.path);
        FileFate fileFate = await uploadImage2(
            imageName, thisPicDate, thisPicFile.path, fileContents);
        switch (fileFate.fate) {
          case Fate.Uploaded:
            upLoadCount++;
            break;
          case Fate.Error:
            errCount++;
            break;
          case Fate.Duplicate:
            dupCount++;
            break;
          // default: // should never happen
          //   throw Exception('unknown fate for file ${thisPicFile.path}');
        } // of switch
        progressMessage =
            'Uploaded $upLoadCount \nErrors $errCount \nDups $dupCount '
            '\nRemaining ${latestFileList.length - i - 1}';
        messageStream.add(progressMessage);
        indicateProgress(i + 1, latestFileList.length);
        log.debug(thisPicFile.path);
      }
      latestFileList = [];
      log.save();
      return true;
    } catch (ex, st) {
      messageStream.add('Error : $ex \n $st');
      return false;
    }
  } // of processFilePhotos

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
    try {
      bool alreadyExists =
          (await AopSnap.nameSameDayExists(modifiedDate, imageName))!;
      if (alreadyExists) {
        log.debug('sameday exists $imageName  date=$modifiedDate');
        return FileFate(filename, Fate.Duplicate,
            reason: 'same day match for filename');
      }
      String thisDevice = config['sesdevice'];
      String fileDateStr =
          formatDate(modifiedDate, format: 'yyyy:mm:dd hh:nn:ss');
      String fileExt = onlyExtension(filename).toLowerCase();
      MediaType? mediaType = supportedMediaTypes[fileExt];
      if (mediaType == null) {
        log.error('Unsupported media type $fileExt');
        return FileFate(imageName, Fate.Error,
            reason: 'Unsupported media type $fileExt');
      }
      bool isVideo = mediaType.type == 'video';
      String targetRoute = isVideo ? 'upload_video' : 'upload2';
      var postUrl =
          "http://${config['host']}:${config['port']}/$targetRoute/$fileDateStr/$imageName/$thisDevice";
      var request = http.MultipartRequest("POST", Uri.parse(postUrl));
      request.headers.addAll({
        'Accept': 'application/json',
        'Preserve': '{"jam":"$modelSessionid"}'
      });
      // request.files.add(http.MultipartFile.fromBytes('myfile', fileContents,
      //     contentType: MediaType('image', 'jpeg')));
      request.files.add(await http.MultipartFile.fromPath(
          isVideo ? 'video' : 'myfile', filename,
          contentType: mediaType));
      var response = await request.send();
      String responseBody = await response.stream.bytesToString();
//      var responseBody = response.stream.toString();
      if (response.statusCode == 200) {
        log.debug("Uploaded $imageName");
        return FileFate(imageName, Fate.Uploaded);
      } else {
        log.error(
            'Failed to upload $imageName  - code ${response.statusCode}\n $responseBody');
        if (responseBody.contains('Duplicate entry'))
          return FileFate(imageName, Fate.Duplicate,
              reason: responseBody); // signal dup
        else
          return FileFate(imageName, Fate.Error,
              reason: responseBody); // signal error
      }
    } catch (ex, st) {
      log.error('$ex\n$st');
      messageStream.add('$ex\n$st');
      return FileFate(imageName, Fate.Error,
          reason: '$ex\n$st'); // signal error
    }
  } //of uploadImageFile
} // of syncDriver

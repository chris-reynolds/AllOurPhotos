/*
  Created by chrisreynolds on 26/07/21
  
  Purpose: This is to isolate the Exporting logic

*/
import 'dart:io';
import 'package:aopmodel/aop_classes.dart';
import 'package:path_provider/path_provider.dart' as Path;
import 'package:permission_handler/permission_handler.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:aopcommon/aopcommon.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:dio/dio.dart';
import 'dart:html' as html;

class ExportPic {
  static Future<bool> _requestPermission(Permission permission) async {
    if (Platform.isIOS) return true;
    if (await permission.isGranted) {
      return true;
    } else {
      var result = await permission.request();
      if (result == PermissionStatus.granted) {
        return true;
      }
    }
    return false;
  }

  static Future<int> exportSeveral(List<AopSnap> snaps) async {
    int errors = 0;
    for (var snap in snaps) {
      if (!await export(snap, 'xxx')) errors += 1;
    }
    return errors;
  }

  static Future<bool> export(AopSnap snap, String albumName) async {
    Directory? directory;
    String url = snap.fullSizeURL;
    String fileName = snap.fileName ?? 'noname.jpg';
    try {
      if (kIsWeb) {
        String relativeUrl = url;
        log.message('Attrempting to download $relativeUrl');
        html.AnchorElement anchorElement = html.AnchorElement()
          ..href = relativeUrl
          ..setAttribute('download', fileName);
        html.document.body!.append(anchorElement);
        log.message(
            'set anchorelement for $relativeUrl ${anchorElement.download}');
        anchorElement.click();
        return true;
      } else if (Platform.isAndroid) {
        if (await _requestPermission(Permission.storage)) {
          directory = await Path.getExternalStorageDirectory();
          String newPath = "";
          log.message(directory!.path);
          List<String> paths = directory.path.split("/");
          for (int x = 1; x < paths.length; x++) {
            String folder = paths[x];
            if (folder != "Android") {
              newPath += "/$folder";
            } else {
              break;
            }
          }
          newPath = '$newPath/$albumName';
          directory = Directory(newPath);
        } else {
          return false;
        }
      } else if (Platform.isIOS) {
        if (await _requestPermission(Permission.photos)) {
          directory = await Path.getTemporaryDirectory();
        } else {
          return false;
        }
      } else if (Platform.isMacOS) {
        directory = Directory(
            '${(await Path.getDownloadsDirectory())!.path}/$albumName');
      } else
        throw Exception('Platform not supported');

      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }
      if (await directory.exists()) {
        File saveFile = File("${directory.path}/$fileName");
        await Dio().download(url, saveFile.path,
            onReceiveProgress: (value1, value2) {});
        if (Platform.isIOS) {
          await ImageGallerySaver.saveFile(saveFile.path,
              isReturnPathOfIOS: true);
        }
        log.message('Saved to ${saveFile.path}');
        return true;
      }
    } catch (e) {
      var target = fileName;
      if (directory != null) target = '${directory.path}/$fileName';
      log.error('Failed to save $target \n Error is $e');
      rethrow;
    }
    return false;
  } // of save
} // of ExportPic

/*
  Created by chrisreynolds on 26/07/21
  
  Purpose: This is to isolate the Exporting logic

*/
import 'dart:io';
import 'package:path_provider/path_provider.dart' as Path;
import 'package:permission_handler/permission_handler.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:dio/dio.dart';
import 'Logger.dart' as Log;

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

  static Future<bool> save(String url, String fileName, String albumName) async {
    Directory directory;
    try {
      if (Platform.isAndroid) {
        if (await _requestPermission(Permission.storage)) {
          directory = await Path.getExternalStorageDirectory();
          String newPath = "";
          print(directory);
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
        directory = Directory('${(await Path.getDownloadsDirectory()).path}/$albumName');
      } else
        throw Exception('Platform not supported');

      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }
      if (await directory.exists()) {
        File saveFile = File("${directory.path}/$fileName");
        await Dio().download(url, saveFile.path,
            onReceiveProgress: (value1, value2) {
//            setState(() {
//              progress = value1 / value2;
//            });
            });
        if (Platform.isIOS) {
          await ImageGallerySaver.saveFile(saveFile.path,
              isReturnPathOfIOS: true);
        }
        Log.message('Saved to ${saveFile.path}');
        return true;
      }
    } catch (e) {
      var target = fileName;
      if (directory != null && directory is Directory)
        target = '${directory.path}/$fileName';
      Log.error('Failed to save $target \n Error is $e');
      print('Failed to save $target \n Error is $e');
    }
    return false;
  }  // of save

} // of ExportPic

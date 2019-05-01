/**
 * Created by Chris on 25/09/2018.
 */
import 'dart:io';
import 'package:path/path.dart' as Path;
import 'package:image/image.dart';
import './dart_common/Logger.dart' as log;
import './JpegLoader.dart';
import './shared/aopClasses.dart';
import './dart_common/Config.dart';

class FileImporter {
  final String rootDir;
  final DateTime startDate;

  String absPath(String dirName, String filename) =>
      Path.join(rootDir, dirName, filename);
  final WANTED_FILES = ['.jpg', '.mvi', '.png', '.maov']; // todo import movies

  FileImporter(this.rootDir, this.startDate) {
    log.message('Registered root $rootDir starting at $startDate');
  } // of constructor

  void scanAll() async {
    List<String> fileNames = [];
    List<DateTime> modifiedDates = [];
//    Stream<FileSystemEntity> directoryStream = await
//        Directory(rootDir).list(recursive: true);
    List<FileSystemEntity> directoryList = await
    Directory(rootDir).list(recursive: true).toList();
    for (FileSystemEntity fse in directoryList) {
      String thisExtension = Path.extension(fse.path).toLowerCase();
      if (WANTED_FILES.indexOf(thisExtension) >= 0 &&
              fse.path.indexOf('thumbnail') < 0
//          && fse.path.indexOf('1980-01') < 0
          ) {
        var fileStat = fse.statSync();
        if (fileStat.modified.isAfter(startDate)) {
          fileNames.add(fse.path);
          modifiedDates.add(fileStat.modified);
        }
      } else {
//        log.message('skipping ${fse.path} with extension $thisExtension');
      }
    }
    log.message('${fileNames.length} files to load');
    for (int i = 0; i < fileNames.length; i++)
      try {
        bool imported = await AopSnap.exists(fileNames[i]);
        if (!imported)
          await importFile(File(fileNames[i]), modifiedDates[i]);
        else
          log.message(fileNames[i] + ' already imported');
      } catch (ex) {
        log.error(ex);
      }
  } // of scanAll

  void importFile(File thisImageFile, DateTime fileModifiedDate) async {
    Image thumbnailImage;
    try {
      log.message('importing file ' + thisImageFile.path);
      List<int> fileImageContents = thisImageFile.readAsBytesSync();
      if (thisImageFile.path.indexOf('helen') >= 0)
        log.message('checkpoint available');
      AopSnap thisSnap = AopSnap();
      String thisExtension = Path.extension(thisImageFile.path).toLowerCase();
      if (thisExtension == '.jpg') {
        try {
          Image originalImage = decodeImage(fileImageContents);
          thisSnap.width = originalImage.width;
          thisSnap.height = originalImage.height;
          bool isPortrait = (originalImage.height > originalImage.width);
          thumbnailImage = copyResize(originalImage, isPortrait ? 480 : 640);
        } catch (ex) {
          log.error('failed to decode ${thisImageFile.path}');
        }
        var jpegLoader = JpegLoader();
        await jpegLoader.extractTags(fileImageContents);
        if (jpegLoader.tags != null && jpegLoader.tags.length > 0)
          populateSnapFromTags(thisSnap, jpegLoader);
      }
      thisSnap.fileName = Path.basename(thisImageFile.path);
      thisSnap.directory = Path.canonicalize(thisImageFile.path);
      thisSnap.mediaType = thisExtension.substring(1); // chop off the dot
      thisSnap.importedDate = DateTime.now();
      thisSnap.modifiedDate = fileModifiedDate;
      if (thisSnap.takenDate == null ||
          thisSnap.takenDate.isBefore(DateTime(1901)))
        thisSnap.takenDate = thisSnap.modifiedDate;
      thisSnap.importSource = config['importsource'] ?? "FileImporter";
      AopFullImage fullImage = AopFullImage();
      fullImage.contents = fileImageContents;
      int fullImageId = await fullImage.save();
      thisSnap.fullImageId = fullImageId;
      if (thumbnailImage != null) {
        AopThumbnail thumbnail = AopThumbnail();
        thumbnail.contents = encodeJpg(thumbnailImage, quality: 75);
        thisSnap.thumbnailId = await thumbnail.save();
      }
      int snapId = await thisSnap.save();
    } catch (err) {
      throw 'Error on importing ${thisImageFile.path} with exception ${err.message}';
    } // of try/catch
  } // of importFile

  void populateSnapFromTags(AopSnap thisFile, JpegLoader jpl) {
//    int imageWidth = jpl.tag('ImageWidth') ?? jpl.tag('PixelXDimension');
//    int imageHeight = jpl.tag('ImageHeight') ?? jpl.tag('PixelYDimension');
    try {
      thisFile
        ..caption = jpl.cleanString(jpl.tag('ImageDescription') ?? '')
        ..takenDate = jpl.dateTimeFromExif(jpl.tag('DateTime'))
        //      ..width = imageWidth
        //      ..height = imageHeight
        ..takenDate = thisFile.takenDate // default to be overwritten
        ..importedDate = DateTime.now()
        ..ranking = 2
        ..latitude =
            jpl.dmsToDeg(jpl.tag('GPSLatitude'), jpl.tag('GPSLatitudeRef'))
        ..longitude =
            jpl.dmsToDeg(jpl.tag('GPSLongitude'), jpl.tag('GPSLongitudeRef'))
        ..deviceName = jpl.cleanString(jpl.tag('Model') ?? '')
        ..rotation = '0'
        ..userId = 1
        ..tagList = ''
        ..hasThumbnail = false;
    } catch (ex) {
      log.error(ex);
      rethrow;
    }
  } // of populateSnap

} // of FileImporter

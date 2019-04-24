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
  String absPath(String dirName,String filename) => Path.join(rootDir,dirName,filename);
  final WANTED_FILES = ['.jpg','.mvi','.png','.mov'];


  FileImporter(this.rootDir,this.startDate) {
    log.message('Registered root $rootDir starting at $startDate');
  } // of constructor

  void scanAll() async {
    List<String> fileNames = [];
    List<DateTime> modifiedDates = [];
    Stream<FileSystemEntity> directoryStream = Directory(rootDir).list(recursive: true);
    await for (FileSystemEntity fse in directoryStream) {
      String thisExtension =  Path.extension(fse.path);
      if (WANTED_FILES.indexOf(thisExtension)>=0) {
        var fileStat = fse.statSync();
        if (fileStat.modified.isAfter(startDate)) {
          fileNames.add(fse.path);
          modifiedDates.add(fileStat.modified);
        }
      }
    }
    log.message('${fileNames.length} files to load');
    for (int i=0; i<fileNames.length; i++)
      try {
        await importFile(File(fileNames[i]), modifiedDates[i]);
      } catch(ex) {
      log.error(ex);
      }
  } // of scanAll


  void importFile(File thisImageFile,DateTime fileModifiedDate) async {
    try {
      log.message('importing file ' + thisImageFile.path);
      // todo import the file
      List<int> fileImageContents = thisImageFile.readAsBytesSync();
      Image originalImage = decodeImage(fileImageContents);
      bool isPortrait = (originalImage.height>originalImage.width);
      Image thumbnailImage = copyResize(originalImage, isPortrait?480:640);
      AopSnap thisSnap = AopSnap();
      var jpegLoader = JpegLoader();
      await jpegLoader.extractTags(fileImageContents);
      populateSnapFromTags(thisSnap,jpegLoader);
      thisSnap.fileName = Path.basename(thisImageFile.path);
      thisSnap.directory = Path.canonicalize(thisImageFile.path);
      thisSnap.importedDate = DateTime.now();
      thisSnap.modifiedDate = fileModifiedDate;
      thisSnap.importSource = config['importsource']??"FileImporter";
      AopThumbnail thumbnail = AopThumbnail();
      thumbnail.contents = encodeJpg(thumbnailImage,quality:75);
      int thumbnailId = await thumbnail.save();
      AopFullImage fullImage = AopFullImage();
      fullImage.contents = fileImageContents;
      int fullImageId = await fullImage.save();
      thisSnap.fullImageId = fullImageId;
      thisSnap.thumbnailId = thumbnailId;
      int snapId = await thisSnap.save();
    } catch (err) {
      throw 'Error on importing ${thisImageFile.path} with exception ${err.message}';
    } // of try/catch
  } // of importFile

  void populateSnapFromTags(AopSnap thisFile, JpegLoader jpl) {
    int imageWidth = jpl.tag('ImageWidth') ?? jpl.tag('PixelXDimension');
    int imageHeight = jpl.tag('ImageHeight') ?? jpl.tag('PixelYDimension');
    try {
      thisFile
        ..caption = jpl.cleanString(jpl.tag('ImageDescription') ?? '')
        ..takenDate = jpl.dateTimeFromExif(jpl.tag('DateTime'))
        ..width = imageWidth
        ..height = imageHeight
        ..takenDate = thisFile.takenDate // default to be overwritten
        ..importedDate = DateTime.now()
        ..ranking = 2
        ..latitude = jpl.dmsToDeg(jpl.tag('GPSLatitude'), jpl.tag('GPSLatitudeRef'))
        ..longitude = jpl.dmsToDeg(jpl.tag('GPSLongitude'), jpl.tag('GPSLongitudeRef'))
        ..deviceName = jpl.cleanString(jpl.tag('Model') ?? '')
        ..rotation = '0'
        ..userId = 1
        ..mediaType = 'JPG'
        ..tagList = ''
        ..hasThumbnail = false;
    } catch (ex) {
      log.error(ex);
      rethrow;
    }
  } // of populateSnap

} // of FileImporter

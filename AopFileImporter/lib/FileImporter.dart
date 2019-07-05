/**
 * Created by Chris on 25/09/2018.
 */
import 'dart:io';
import 'package:path/path.dart' as Path;
import 'package:image/image.dart';
import './dart_common/Logger.dart' as Log;

import './dart_common/JpegLoader.dart';
import './shared/aopClasses.dart';
import './dart_common/Config.dart';
import './dart_common/Geocoding.dart';
import './dart_common/DateUtil.dart';

class FileImporter {
  final String rootDir;
  final DateTime startDate;
  GeocodingSession _geo = GeocodingSession();
  JpegLoader jpegLoader = JpegLoader();

  String absPath(String dirName, String filename) => Path.join(rootDir, dirName, filename);
  final WANTED_FILES = ['.jpg', '.not-mvi', '.png', '.not-mp4', '.not-mov']; // todo import movies

  FileImporter(this.rootDir, this.startDate) {
    Log.message('Registered root $rootDir starting at $startDate');
  } // of constructor

  void scanAll() async {
    List<String> fileNames = [];
    List<DateTime> modifiedDates = [];
    Stream<FileSystemEntity> directoryStream = await Directory(rootDir).list(recursive: true);
    //    List<FileSystemEntity> directoryList = await
    //    Directory(rootDir).list(recursive: true).toList();
    await for (FileSystemEntity fse in directoryStream) {
      String thisExtension = Path.extension(fse.path).toLowerCase();
      if (WANTED_FILES.indexOf(thisExtension) >= 0 && fse.path.indexOf('thumbnail') < 0
//          && fse.path.indexOf('1980-01') < 0
          ) {
        var fileStat = fse.statSync();
        if (fileStat.modified.isAfter(startDate)) {
          bool alreadyExists = await AopSnap.nameExists(fse.path, fileStat.size);
          if (alreadyExists) {
            if (config['verbose']) Log.message('${fse.path} skipped. Already imported');
          } else {
            fileNames.add(fse.path);
            modifiedDates.add(fileStat.modified);
          }
        }
      } else {
//        log.message('skipping ${fse.path} with extension $thisExtension');
      }
    }
    Log.message('${fileNames.length} files to load');
    for (int i = 0; i < fileNames.length; i++)
      try {
        await makeSnap(File(fileNames[i]));
      } catch (ex, stack) {
        Log.error('$ex  stack $stack');
      }
  } // of scanAll

  void populateSnapFromTags(AopSnap thisSnap, dynamic jpl) {
    try {
      thisSnap
        ..caption = jpl.cleanString(jpl.tag('ImageDescription') ?? '')
        ..originalTakenDate = jpl.dateTimeFromExif(jpl.tag('DateTime'))
        ..latitude = jpl.dmsToDeg(jpl.tag('GPSLatitude'), jpl.tag('GPSLatitudeRef'))
        ..longitude = jpl.dmsToDeg(jpl.tag('GPSLongitude'), jpl.tag('GPSLongitudeRef'))
        ..deviceName = jpl.cleanString(jpl.tag('Model') ?? '');
      if (jpl.tag('DateTimeOriginal')!=null)
        thisSnap.originalTakenDate = jpl.dateTimeFromExif(jpl.tag('DateTimeOriginal'));
    } catch (ex) {
      Log.error('bad exif:' + ex);
      rethrow;
    }
  } // of populateSnap

  Future<void> _uploadJpg(String urlString, List<int> bytes) async {
    var postUri = Uri.parse(urlString);
    HttpClient httpClient = HttpClient();
    var request = await httpClient.putUrl(postUri);
    request.add(bytes);
    var response = await request.close();
    httpClient.close();
    if (response.statusCode == 200)
      Log.message("Uploaded $urlString");
    else
      throw Exception('Failed to upload $urlString with $response');
    ;
  } // of httpPostImage

  Future<AopSnap> makeSnap(File imageFile) async {
    bool success = false;
    bool isDup = false;
    AopSnap thisSnap = AopSnap() // with a few defaults
      ..rotation = '0'
      ..importedDate = DateTime.now()
      ..ranking = 2
      ..userId = 1
      ..importSource = config['importsource'] ?? "FileImporter"
      ..tagList = '';
    try {
      var fileStat = imageFile.statSync();
      thisSnap.fileName = Path.basename(imageFile.path);
      String thisExtension = Path.extension(imageFile.path).toLowerCase();
      thisSnap.mediaType = thisExtension.substring(1); // chop off the dot
      thisSnap.modifiedDate = fileStat.modified;
      thisSnap.mediaLength = fileStat.size;
      List<int> imageData = imageFile.readAsBytesSync();
      var decoder = findDecoderForData(imageData);
      Image thisImage = await decoder?.decodeImage(imageData);
      if (thisImage == null) throw Exception('Failed to decode ${imageFile.path}');
      thisSnap.width = thisImage.width;
      thisSnap.height = thisImage.height;
      await jpegLoader.extractTags(imageFile.readAsBytesSync());
      if (jpegLoader.tags != null && jpegLoader.tags.length > 0)
        populateSnapFromTags(thisSnap, jpegLoader);
      if (thisSnap.latitude != null) {
        String location = await _geo.getLocation(thisSnap.longitude, thisSnap.latitude);
        if (location != null) {
          if (location.length > 200) location = location.substring(location.length - 200);
          thisSnap.location = location;
        }
      }
      if (thisSnap.originalTakenDate == null || thisSnap.originalTakenDate.isBefore(DateTime(1901)))
        thisSnap.originalTakenDate = thisSnap.modifiedDate;
      thisSnap.takenDate = thisSnap.originalTakenDate;
      thisSnap.directory = formatDate(thisSnap.originalTakenDate, format: 'yyyy-mm');
      if (await AopSnap.sizeOrNameAtTimeExists(
          thisSnap.originalTakenDate, thisSnap.mediaLength, thisSnap.fileName)) {
        if (config['verbose'])
          Log.message('sizeOrNameAtTimeExists ${thisSnap.directory}/${thisSnap.fileName} skipped ');
        isDup = true;
        return null;
      }
      if (config['fix']) _uploadSnap(thisSnap, thisImage);
      success = true;
    } catch (ex) {
      Log.error('Failed to make snap for ${imageFile.path}\n $ex');
      rethrow;
    } finally {
      if (!isDup)
        Log.message('${success ? "OK" : "ERROR"} ' +
            '${formatDate(thisSnap.originalTakenDate, format: 'yyyy-mm-dd')} ${imageFile.path}  ');
    } // of try
    return thisSnap;
  } // of makeSnap

  Future<bool> _uploadSnap(AopSnap newSnap, Image fullImage) async {
    try {
      bool isPortrait = (fullImage.height > fullImage.width);
      Image thumbnail = copyResize(fullImage, width: isPortrait ? 480 : 640);
      await _uploadJpg(newSnap.thumbnailURL, thumbnail.data);
      await _uploadJpg(newSnap.fullSizeURL, fullImage.data);
      await newSnap.save();
      return true;
    } catch (ex) {
      Log.message('Failed save for ${newSnap.fileName} - $ex');
      return false;
    } // of try
  }
} // of FileImporter

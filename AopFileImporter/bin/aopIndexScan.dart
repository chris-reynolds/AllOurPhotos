/*
  Created by chrisreynolds on 2019-07-01
  
  Purpose: this scans the current index and makes various fixes.

      The following things need fixing:
      1 - Latitude/Longitude may have the wrong sign
      2 - Date taken may be incorrect
      3 - Thumbnail may be too big.
*/

import 'dart:io';
import 'package:image/image.dart';
import 'package:path/path.dart' as Path;
import '../lib/dart_common/JpegLoader.dart';
import '../lib/dart_common/Geocoding.dart';
// import '../lib/dart_common/DateUtil.dart';
import '../lib/dart_common/Logger.dart' as Log;
import '../lib/dart_common/Config.dart';
import '../lib/shared/dbAllOurPhotos.dart';
import '../lib/shared/AopClasses.dart';

const VERSION = '2019-07-03';

String rootDir;
GeocodingSession _geo = GeocodingSession();
JpegLoader jpegLoader = JpegLoader();

void main(List<String> arguments) async {
  rootDir = (arguments.length > 0) ? arguments[0] : '.'; //default current directory
  try {
    // setup the logger to show the time
    Log.onMessage =
        (String s) => stdout.writeln('${DateTime.now().toString().substring(0, 21)} : $s');
    Log.logLevel = Log.eLogLevel.llMessage; // show messages and errors for now
    Log.message('AllOurPhotos IndexScan $VERSION running ');
    await loadConfig(null); //( configFileName);
    //now connect to the database
    await DbAllOurPhotos().initConnection(config);
    int sessionId = await DbAllOurPhotos().startSession(config);
    if (sessionId <= 0) throw Exception('Failed to login session correctly');
    // now prime the geocoding cache
    dynamic r = await AopSnap.existingLocations;
    for (dynamic row in r) _geo.setLocation(row[1], row[2], row[0]);
    // get all the snaps and start checking one at a time
    List<AopSnap> allSnaps = await snapProvider.getSome("file_name = 'IMG_0001.JPG' ");
    for (int snapIx = 0; snapIx < allSnaps.length; snapIx++) {
      SnapFixer snapFixer = SnapFixer(allSnaps[snapIx]);
      if (await snapFixer.load()) {
        await snapFixer.fixTakenDate();
        await snapFixer.fixLocation();
        if (snapFixer.isDirty) {
          await snapFixer.snap.save();
          Log.message('${snapFixer.imagePath} updated');
        }
        await snapFixer.fixThumbnail();
      }
      if (snapIx % 40 == 0) Log.message('$snapIx');
    }
    Log.message('${allSnaps.length} loaded successfully');
    Log.message('AllOurPhotos IndexScan $VERSION completed successfully ');
    exit(0);
  } catch (ex, stack) {
    Log.error('Failed AllOurPhotos index scan : $ex /n ${stack}');
    exit(16);
  } // of catch
} // of main

class SnapFixer {
  AopSnap snap;
  bool isDirty;

  SnapFixer(this.snap);

  Image fullImage;
  Map<String, dynamic> exifTags = {};

  String get imagePath => Path.join(rootDir, snap.directory, snap.fileName);

  String get thumbnailPath => Path.join(rootDir, snap.directory, 'thumbnails', snap.fileName);

  Future<bool> load() async {
    isDirty = false;
    try {
      List<int> imageData = File(imagePath).readAsBytesSync();
      fullImage = decodeImage(imageData);
      await jpegLoader.extractTags(imageData);
      exifTags = jpegLoader.tags ?? {};
      return true;
    } catch (ex, stack) {
      Log.error('${imagePath} failed to load $ex /n $stack');
      return false;
    }
  } // of load

  Future<bool> fixLocation() async {
    if (exifTags['GPSLatitude'] != null)
      try {
        double newLatitude =
            jpegLoader.dmsToDeg(exifTags['GPSLatitude'], exifTags['GPSLatitudeRef']);
        double newLongitude =
            jpegLoader.dmsToDeg(exifTags['GPSLongitude'], exifTags['GPSLongitudeRef']);
        // change if different
        if ((newLatitude - snap.latitude).abs() > 0.01 ||
            (newLongitude - snap.longitude).abs() > 0.01) {
          isDirty = true;
          snap.latitude = newLatitude;
          snap.longitude = newLongitude;
          if (snap.latitude != null) {
            String location = await _geo.getLocation(snap.longitude, snap.latitude);
            if (location != null) {
              if (location.length > 200) location = location.substring(location.length - 200);
              snap.location = location;
            }
          }
        }
        return true;
      } catch (ex, stack) {
        Log.error('${imagePath} failed to fix location $ex /n $stack');
        return false;
      } else
        return true; // nothing to do
  } // of fixLocation

  Future<bool> fixTakenDate() async {
    try {
      DateTime newTakenDate = jpegLoader.dateTimeFromExif(exifTags['DateTime']);
      if (exifTags['DateTimeOriginal'] != null)
        newTakenDate = jpegLoader.dateTimeFromExif(exifTags['DateTimeOriginal']);
      // change if different
      if (newTakenDate!= null && newTakenDate.difference(snap.takenDate).inSeconds.abs() > 1) {
        isDirty = true;
        snap.takenDate = newTakenDate;
        snap.originalTakenDate = newTakenDate;
      }
      return true;
    } catch (ex,stack) {
      Log.error('${imagePath} failed to fix taken date $ex /n $stack');
      return false;
    }
  } // of fixTakenDate

  Future<bool> fixThumbnail({int newQuality: 30}) async {
    try {
      File thumbnailFile = File(thumbnailPath);
      int oldFileLength = await thumbnailFile.length();
      if (oldFileLength > 150000) {
        bool isPortrait = (fullImage.height > fullImage.width);
        Image thumbnail = copyResize(fullImage, width: isPortrait ? 480 : 640);
        thumbnailFile.writeAsBytesSync(encodeJpg(thumbnail,quality:newQuality));
        int newLength = await thumbnailFile.length();
        Log.message('new thumbail for length $oldFileLength to $newLength on file $thumbnailPath');
      }
      return true;
    } catch (ex,stack) {
      Log.error('${imagePath} failed to fix thumbnail $ex /n $stack');
      return false;
    }
  } // of fixThumbnail

} // of SnapFixer

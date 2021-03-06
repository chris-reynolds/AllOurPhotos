/**
 * Created by Chris on 06/02/2020.
 */

import 'dart:io';
import 'dart:convert';
import 'package:image/image.dart';
import '../shared/aopClasses.dart';
import 'Config.dart';
import 'DateUtil.dart';
import 'JpegLoader.dart';
import 'Geocoding.dart';
import 'WebFile.dart';
import './Logger.dart' as Log;

String _fileName(String path) => (path.lastIndexOf('/') > 0)
    ? path.substring(path.lastIndexOf('/') + 1)
    : path.substring(path.lastIndexOf('\\') + 1);


Image makeThumbnail(Image fromImage) {
  bool isWider = fromImage.width>fromImage.height;
  if (fromImage.exif.hasOrientation && (fromImage.exif.orientation==6 || fromImage.exif.orientation==8))
    isWider = !isWider;
  Image toImage = copyResize(fromImage,width:isWider?640:480);
  // now strip some exif
  Image threeImage = Image.fromBytes(toImage.width, toImage.height,toImage.data);
  return threeImage;
} // make thumbnail

Future<bool> uploadFile(File thisPicFile) async {
  FileStat thisPicStats = thisPicFile.statSync();
  List<int> fileContents = thisPicFile.readAsBytesSync();
  String imageName = _fileName(thisPicFile.path);
  return await uploadImage(fileContents, imageName, fileModified: thisPicStats.modified);
}

Future<bool> uploadImage(List<int> imageContents, String imageName,
    {DateTime fileModified,String device}) async {
  try {
    Log.message('uploading $imageName');
    Image thisImage = decodeImage(imageContents);

    GeocodingSession _geo = GeocodingSession();
    JpegLoader jpegLoader = JpegLoader();
    await jpegLoader.extractTags(imageContents);
    Log.message(jpegLoader.tags.length==0?'NO TAGS !!!!!!!!!!!!!':'Tag count is ${jpegLoader.tags.length}');
    String _deviceName = device ?? jpegLoader.tag('Model') ?? config['sesdevice'];
    DateTime takenDate = dateTimeFromExif(jpegLoader.tag('dateTimeOriginal')) ??
        jpegLoader.tag('dateTime') ??
        fileModified ??
        DateTime(1982,1,1);

    bool alReadyExists = await AopSnap.sizeOrNameOrDeviceAtTimeExists(
        takenDate, imageContents.length, imageName, _deviceName);
    if (alReadyExists) return false;
    AopSnap newSnap = AopSnap()
      ..fileName = imageName
      ..directory = '1982-01'
      ..width = thisImage.width
      ..height = thisImage.height
      ..takenDate = takenDate
      ..modifiedDate = fileModified
      ..deviceName = _deviceName
      ..rotation = '0' // todo support enumeration
      ..importSource = _deviceName
      ..importedDate = DateTime.now();

    bool isScanned = ((jpegLoader.tag('device.software') ?? '').toLowerCase().indexOf('scan') >= 0);
    newSnap.importSource += isScanned ? ' scanned' : ' camera roll';

    newSnap.originalTakenDate = newSnap.takenDate;
    newSnap.directory = formatDate(newSnap.originalTakenDate, format: 'yyyy-mm');
    // checkl for duplicate
    newSnap.mediaLength = imageContents.length;
    if (jpegLoader.tag("GPSLatitudeRef") != null) {
      newSnap.latitude =
          jpegLoader.dmsToDeg(jpegLoader.tag('GPSLatitude'), jpegLoader.tag('GPSLatitudeRef'));
      newSnap.longitude =
          jpegLoader.dmsToDeg(jpegLoader.tag('GPSLongitude'), jpegLoader.tag('GPSLongitudeRef'));
    }
    if (newSnap.latitude != null) {
      String location = await _geo.getLocation(newSnap.longitude, newSnap.latitude);
      if (location != null) newSnap.trimSetLocation(location);
    }

    if (newSnap.originalTakenDate != null && newSnap.originalTakenDate.year > 1980) {
      if (await AopSnap.dateTimeExists(newSnap.originalTakenDate, newSnap.mediaLength))
        return false;
    } else {
      if (await AopSnap.nameExists(newSnap.fileName, newSnap.mediaLength)) return false;
    }
    // all looks good to upload but it might be a different picture with the same name and month
    if (await newSnap.nameClashButDifferentSize()) {
      int lastDot = newSnap.fileName.lastIndexOf('.');
      if (lastDot < 0) throw "Cant find the extension of file name ${newSnap.fileName}";
      newSnap.fileName =
          newSnap.fileName.substring(0, lastDot) + 'a' + newSnap.fileName.substring(lastDot);
    }
    String myMeta = jsonEncode(jpegLoader.tags);
    Image thumbnail =  makeThumbnail(thisImage); //copyResize(thisImage, width: (newSnap.width > newSnap.height) ? 640 : 480);
    await saveWebImage(newSnap.thumbnailURL, image: thumbnail, quality: 50);
    await saveWebImage(newSnap.fullSizeURL, image: thisImage);
    await saveWebImage(newSnap.metadataURL, metaData: myMeta);
    newSnap.metadata = myMeta;
    await newSnap.save();
    return true;
  } catch (ex, st) {
    Log.error('Failed save for ${imageName} \n$ex \n$st');
    return false;
  } // of try
} // of uploadImage

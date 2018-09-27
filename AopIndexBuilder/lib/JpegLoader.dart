/**
 * Created by Chris on 21/09/2018.
 */
import 'package:exif/exif.dart';
import './ImgFile.dart';
import 'Logger.dart' as log;

class JpegLoader {
   List<int> _buffer;
//   File _baseFile;
   Map<String, IfdTag> tags = null;


   void loadBuffer(List<int> newBuffer) async {
     _buffer = newBuffer;
  //   _baseFile =  File(path);
 //    _buffer = _baseFile.readAsBytesSync();
     tags = await readExifFromBytes(_buffer);
     log.message('read tags');
   }

   static double dmsToDeg(List dms, String direction) {
     if (dms==null)  return null;
     double result = 0.0;
     for (int ix in [2,1,0]) {
       result = result / 60 + (dms[ix].numerator / dms[ix].denominator);
     }
     if ('sSeE'.indexOf(direction)>=0)
       result = -result;
     return result;
   } // of dmsToDeg

   static DateTime dateTimeFromExif(String exifString)  {
     try {
       String tmp = exifString.substring(0,4)+'-'+exifString.substring(5,7)+
           '-'+exifString.substring(8);
       return DateTime.parse(tmp);
     } catch(ex) {
       return null;
     } // of try catch
   }  // dateTimeFromExit
   void saveToImgFile( ImgFile thisFile) {
     thisFile
       ..caption = tag('Image ImageDescription')?.toString()
       ..dateTaken = dateTimeFromExif(tag('Image DateTime')?.toString())
       ..byteCount = _buffer.length
       ..width = int.parse(tag('EXIF ExifImageWidth')?.toString())
       ..height = int.parse(tag('EXIF ExifImageLength')?.toString())
       ..lastModifiedDate = thisFile.dateTaken   // default to be overwritten
       ..rank = 2
       ..latitude = dmsToDeg(tag('GPS GPSLatitude')?.values, tag('GPS GPSLatitudeRef')?.toString())
       ..longitude = dmsToDeg(tag('GPS GPSLongitude')?.values, tag('GPS GPSLongitudeRef')?.toString())
       ..camera = tag('Image Model')?.toString()
       ..rotation = 0
       ..owner = 'All'
       ..imageType = 'JPEG'
       ..hasThumbnail = false
       ..contentHash = thisFile.calcContentHash();
   }  // of saveToImgFile
   IfdTag tag(String tagName) {
     try {
       return tags[tagName];
     } catch (ex) {
       log.message('++++++++++++++++tag $tagName not found');
       return null;
     }
   }
} // of JpegLoader
/**
 * Created by Chris on 21/09/2018.
 */
import 'package:exifdart/exifdart.dart' as exif;
import './ImgFile.dart';
import 'utils/Logger.dart' as log;

class JpegLoader {
   List<int> _buffer;
//   File _baseFile;
   Map<String, dynamic> tags = null;


   void loadBuffer(List<int> newBuffer) async {
     _buffer = newBuffer;
     exif.MemoryBlobReader mbr = exif.MemoryBlobReader(newBuffer);
     tags = await exif.readExif(mbr);
     log.message('read tags');
   }

   String cleanString(String s) {
      RegExp nullMask = RegExp(r"[\0|\00]");
      String result = s.replaceAll(nullMask, '');
      return result.trim();
   } // of cleanString

   static double dmsToDeg(List dms, String direction) {
     if (dms==null)  return ImgFile.UNKNOWN_LONGLAT;
     double result = 0.0;
     for (int ix in [2,1,0]) {
       result = result / 60 + (dms[ix].numerator / dms[ix].denominator);
     }
     if ('sSwW'.indexOf(direction)>=0)
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
     int imageWidth = tag('ImageWidth')  ?? tag('PixelXDimension');
     int imageHeight = tag('ImageHeight')  ?? tag('PixelYDimension');
     try {
       thisFile
         ..caption = cleanString(tag('ImageDescription')??'')
         ..takenDate = dateTimeFromExif(tag('DateTime'))
         ..byteCount = _buffer.length
         ..width = imageWidth
         ..height = imageHeight
         ..lastModifiedDate = thisFile.takenDate // default to be overwritten
         ..rank = 2
         ..latitude = dmsToDeg(tag('GPSLatitude'),
             tag('GPSLatitudeRef'))
         ..longitude = dmsToDeg(tag('GPSLongitude'),
             tag('GPSLongitudeRef'))
         ..camera = cleanString(tag('Model')??'')
         ..rotation = 0
         ..owner = 'All'
         ..imageType = 'JPEG'
         ..hasThumbnail = false
         ..contentHash = thisFile.calcContentHash();
     } catch(ex) {
       log.error(ex);
       rethrow;
     }
   }  // of saveToImgFile
   dynamic tag(String tagName) {
     try {
       return tags[tagName];
     } catch (ex) {
       log.message('++++++++++++++++tag $tagName not found');
       return null;
     }
   }
} // of JpegLoader
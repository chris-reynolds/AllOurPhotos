/**
 * Created by Chris on 21/09/2018.
 */
import 'package:exifdart/exifdart.dart' as exif;
//import './shared/aopClasses.dart';
import './dart_common/Logger.dart' as log;

class JpegLoader {
  static const UNKNOWN_LONGLAT = null;
//  List<int> _buffer;
  Map<String, dynamic> tags = null;

  Future<void> extractTags(List<int> newBuffer) async {
//    _buffer = newBuffer;
    exif.MemoryBlobReader mbr = exif.MemoryBlobReader(newBuffer);
    tags = await exif.readExif(mbr);
//    log.message('read tags');
  }

  String cleanString(String s) {
    RegExp nullMask = RegExp(r"[\0|\00]");
    String result = s.replaceAll(nullMask, '');
    return result.trim();
  } // of cleanString

  double dmsToDeg(List dms, String direction) {
    if (dms == null) return UNKNOWN_LONGLAT;
    double result = 0.0;
    for (int ix in [2, 1, 0]) {
      result = result / 60 + (dms[ix].numerator / dms[ix].denominator);
    }
    if ('sSwW'.indexOf(direction) >= 0) result = -result;
    return result;
  } // of dmsToDeg

  DateTime dateTimeFromExif(String exifString) {
    try {
      String tmp = exifString.substring(0, 4) +
          '-' +
          exifString.substring(5, 7) +
          '-' +
          exifString.substring(8);
      return DateTime.parse(tmp);
    } catch (ex) {
      return null;
    } // of try catch
  } // dateTimeFromExit


  dynamic tag(String tagName) {
    try {
      return tags[tagName];
    } catch (ex) {
      log.message('++++++++++++++++tag $tagName not found');
      return null;
    }
  }
} // of JpegLoader

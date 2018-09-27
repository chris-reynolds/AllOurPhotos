/**
 * Created by Chris on 21/09/2018.
 */
import 'dart:io';
import 'package:AopIndexBuilder/ImgFile.dart';
import 'package:path/path.dart' as path;
import './logger.dart' as log;
import './JpegLoader.dart';


class FilenameHelper {


  static String directoryForDate(DateTime aDate) {
    int yy = aDate.year;
    int mm = aDate.month;
    return '$yy-${(mm <= 9) ? "0" : ""}$mm';
  }
} // of filenameHelper


void importTempFile (String originalFilename, String tempPath) {
  log.message('import temp file ' + originalFilename);
  try {
    ImgFile newImage = new ImgFile(tempPath, originalFilename);
    String tempFilename = path.join(tempPath, originalFilename);
    File newFile = File(tempFilename);
    JpegLoader()
        ..loadBuffer(newFile.readAsBytesSync())
        ..saveToImgFile(newImage);
    String newDirectoryName = FilenameHelper.directoryForDate(newImage.dateTaken);
    log.message('Import into directory :' + newDirectoryName);
    // let fullDirectoryName = FilenameHelper.calcFilename(newDirectoryName)
    ImgDirectory imgDirectory = ImgCatalog.getDirectory(newDirectoryName);
// now move file to correct directory
    String targetName = path.join(newDirectoryName,originalFilename);
    int tries = 0;
    while (tries < 10) {
      tries += 1;
      ImgFile previousFile = imgDirectory.getFile(originalFilename);
      if (previousFile == null) { // not found
        newFile.renameSync(targetName);
        imgDirectory.files.add(newImage);
      } else if (previousFile.contentHash != newImage.contentHash) {
        targetName = originalFilename + '_c$tries'; // try a new target name
      } else {
        log.message('skipped importing as a duplicate of ' + targetName);
        break;
      }
    } // of while loop
  } catch (err) {
    err.message += ': Error on importing ' + originalFilename;
    throw err;
/**/
  } // of try/catch
} // of importTempFile

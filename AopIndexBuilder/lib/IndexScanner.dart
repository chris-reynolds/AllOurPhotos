/**
 * Created by Chris on 28/09/2018.
 */

import 'dart:io';
import 'ImgFile.dart';
import 'Logger.dart' as log;
import 'IndexBuilder.dart' as IB;
import 'package:path/path.dart' as path;
import 'package:image/image.dart';

DateTime _cutOffDate = DateTime.now().add(Duration(days:-365)); // last year
bool deleteOldDebrisAction(ImgFile imgFile) {
  if (imgFile.deletedDate != null && imgFile.deletedDate.isBefore(_cutOffDate)) {
    imgFile.directory
      ..files.remove(imgFile)
      ..dirty = true;
  }
} // of deleteOldDebrisAction

bool fixDirectoryAction(ImgFile imgFile) {
  // TODO : fixDirectoryAction
  throw("todo fixDirectoryAction()");
} // of fixDirectoryAction

bool geocodingAction(ImgFile imgFile) {
  // TODO : geocodingAction
  throw("todo geocodingAction()");
} // of geocodingAction

bool missingWidthAction(ImgFile thisFile) {
  bool result = true;
  if (thisFile.width == null && thisFile.deletedDate == null
      && path.extension(thisFile.filename).toLowerCase() == '.jpg') {
    Image image = decodeJpg(File(IB.absPath(thisFile.dirname, thisFile.filename)).readAsBytesSync());
    thisFile.width = image.width;
    thisFile.height = image.height;
    result = ImgFile.save(thisFile);
    log.message('fix width for ${thisFile.filename}');
  }
  return result;
} // of missingWidthAction

bool thumbnailAction(ImgFile thisFile) {
   log.message('Considering thumbnail action for ${thisFile.dirname}/${thisFile.filename}');
   bool result = false;
   bool saveRequired = true;
   try {
     String bigPicFilename = IB.absPath(thisFile.dirname, thisFile.filename);
     String thumbnailFilename = IB.absPath(path.join(thisFile.dirname,'thumbnails'), thisFile.filename);
     File thumbnailFile = File(thumbnailFilename);
     if (thumbnailFile.existsSync()) {
       log.message('Skipping thumbnail action for ${thisFile.dirname}/${thisFile.filename}');
       saveRequired = !thisFile.hasThumbnail;
       thisFile.hasThumbnail = true;
       result = true;
     } else {
       log.message('Starting thumbnail action for ${thisFile.dirname}/${thisFile.filename}');
       File bigPicFile = File(bigPicFilename);
       if (!bigPicFile.existsSync()) {
         thisFile.deletedDate = DateTime.now();
   // TODO      throw "Fullsize file not found";
       } else { // bigfile found - thumbnail missing
         if (thisFile.deletedDate != null)
           thisFile.deletedDate = null;
         String thumbnailPath = path.dirname(thumbnailFilename);
         if (!FileSystemEntity.isDirectorySync(thumbnailPath))
           Directory(thumbnailPath).createSync();
         // try and load it from the metadata
         Image image = decodeImage(bigPicFile.readAsBytesSync());
         int bigEdge = image.height > image.width ? image.height : image.width;
         if (bigEdge<=0)
           throw "Invalid picture size";
         double scale = bigEdge<640 ? 1 : 640/bigEdge;
         // Resize the image to a 640x480 or 480x640 thumbnail (maintaining the aspect ratio).
         Image thumbnail = copyResize(image, (image.width*scale).round());
         var buffer = encodeJpg(thumbnail,quality:70); // high quality maybe
         thumbnailFile.writeAsBytesSync(buffer, mode:FileMode.writeOnly,flush:true);
         log.message('Written thumbnail action for ${thisFile.dirname}/${thisFile.filename}');
         thisFile.hasThumbnail = true;
         result = true;
         saveRequired = true;
       }
     } // of thumbnail file not found
   } catch (ex) {
     log.error('Fail thumbnail action for ${thisFile.dirname}/${thisFile.filename} : $ex');
   } finally {
      if (saveRequired)
        ImgFile.save(thisFile);
   }
   return result;
} // of thumbnail Action


bool justdoit() {
  ImgCatalog.actOnAll(missingWidthAction);
  ImgCatalog.actOnAll(deleteOldDebrisAction);
  ImgCatalog.actOnAll(thumbnailAction);
  ImgCatalog.actOnAll(fixDirectoryAction);
  ImgCatalog.actOnAll(geocodingAction);
}
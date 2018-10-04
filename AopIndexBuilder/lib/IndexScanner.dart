/**
 * Created by Chris on 28/09/2018.
 */

import 'dart:io';
import 'ImgFile.dart';
import 'Logger.dart' as log;
import 'IndexBuilder.dart' as IB;
import 'package:path/path.dart' as path;

//typedef ImgAction = void Function(ImgFile thisFile);

bool thumbnailAction(ImgFile thisFile) {
   log.message('Starting thumbnail action for ${thisFile.dirname}/${thisFile.filename}');
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
         throw "Fullsize file not found";
       } else { // bigfile found - thumbnail missing
         // try and load it from the metadata
         log.message('TODO thumbnail action for ${thisFile.dirname}/${thisFile.filename}');
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
  ImgCatalog.actOnAll(thumbnailAction);
}
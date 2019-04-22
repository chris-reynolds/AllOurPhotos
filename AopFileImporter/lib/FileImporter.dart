/**
 * Created by Chris on 25/09/2018.
 */
import 'dart:io';
import 'package:path/path.dart' as Path;
import './dart_common/Logger.dart' as log;
import './dart_common/StringUtils.dart';
import './JpegLoader.dart';




class FileImporter {
  final String rootDir;
  final DateTime startDate;
  String absPath(String dirName,String filename) => Path.join(rootDir,dirName,filename);
  final WANTED_FILES = ['.jpg','.mvi','.png','.mov'];


  FileImporter(this.rootDir,this.startDate) {
    log.message('Registered root $rootDir starting at $startDate');
  } // of constructor

  void scanAll() async {
    Directory(rootDir).list(recursive: true).listen((fse) {
      String thisExtension =  Path.extension(fse.path);
      if (WANTED_FILES.indexOf(thisExtension)>=0)
       fse.stat().then((fileStat){
         if (fileStat.modified.isAfter(startDate)) {
           importFile((fse as File));
         }
       }); // of stat
    }); // of listen

  } // of buildAll


  void importFile(File thisImage) async {
    try {
      log.message('importing file ' + thisImage.path);
      // todo import the file
    } catch (err) {
      err.message += ': Error on importing ${thisImage.path}';
      rethrow;
    } // of try/catch
  } // of importTempFile
} // of FileImporter

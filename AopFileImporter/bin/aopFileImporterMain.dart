
import 'dart:io';
import '../lib/FileImporter.dart';
import '../lib/dart_common/Logger.dart' as log;
import '../lib/dart_common/Config.dart';


const VERSION = '2019-04-22';
const DAYS_AGO = 10000;  // todo change to 90



void main(List<String> arguments) async {
//final photoDir = 'C:\\projects\\AllOurPhotos\\testdata\\';
  String photoRootDir = (arguments.length > 0)? arguments[0] : null;
  String configFileName = (arguments.length > 2)? arguments[2] : null;
  DateTime startDate = (arguments.length > 1)? DateTime.parse(arguments[1]) :
                DateTime.now().add(Duration( days:-DAYS_AGO));
  try {
    if (arguments.length < 1) throw 'Invalid Usage: AopFileImport rootdir startDate [configFileName]';
    if (!Directory(photoRootDir).existsSync())
      throw 'rootDir ($photoRootDir) does not exist';
    await loadConfig(configFileName);
    // setup the logger to show the time
    log.onMessage = (String s) => stdout.writeln('${DateTime.now().toString().substring(0,21)} : $s');
    log.logLevel = log.eLogLevel.llMessage; // show messages and errors for now
    FileImporter fImporter = FileImporter(photoRootDir,startDate);
    await fImporter.scanAll();
    log.message('AllOurPhotos file importer $VERSION running ');
    return;
  } catch (ex) {
    log.error('Failed to load AllOurPhotos file importer : $ex');
    exit(16);
  } // of catch

} // of main


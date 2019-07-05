
import 'dart:io';
import '../lib/FileImporter.dart';
import '../lib/dart_common/Logger.dart' as log;
import '../lib/dart_common/Config.dart';
import '../lib/shared/dbAllOurPhotos.dart';


const VERSION = '2019-07-02';
const DAYS_AGO = 100000;  // todo change to 90

void main(List<String> arguments) async {
//final photoDir = 'C:\\projects\\AllOurPhotos\\testdata\\';
  String photoRootDir = (arguments.length > 0)? arguments[0] : null;
//  String configFileName = (arguments.length > 2)? arguments[2] : null;
  DateTime startDate = DateTime.now().add(Duration( days:-DAYS_AGO));

  try {
    log.onMessage = (String s) => stdout.writeln('${DateTime.now().toString().substring(0,21)} : $s');
    log.logLevel = log.eLogLevel.llMessage; // show messages and errors for now
    log.message('AllOurPhotos file importer $VERSION running ');
    if (arguments.length < 1) throw 'Invalid Usage: AopFileImport rootdir startDate [configFileName]';
    if (!Directory(photoRootDir).existsSync())
      throw 'rootDir ($photoRootDir) does not exist';
    await loadConfig(null); //( configFileName);
    //add commandline options to loaded config
    config['verbose'] = arguments.indexOf('-v')>0;
    config['fix'] = arguments.indexOf('-f')>0;
    // setup the logger to show the time
    //now connect to the database
    await DbAllOurPhotos().initConnection(config);
    int sessionId = await DbAllOurPhotos().startSession(config);
    if (sessionId<=0)
      throw Exception('Failed to login session correctly');
    FileImporter fImporter = FileImporter(photoRootDir,startDate);
    await fImporter.scanAll();
    log.message('AllOurPhotos file importer $VERSION completed successfully ');
    exit(0);
  } catch (ex) {
    log.error('Failed to load AllOurPhotos file importer : $ex');
    exit(16);
  } // of catch

} // of main


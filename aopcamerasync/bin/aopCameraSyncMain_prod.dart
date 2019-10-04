/*
  Created by chrisreynolds on 2019-10-01

  Purpose: Driver for the Camera sync utility

*/
import 'dart:io';
import '../lib/dart_common/Config.dart';
import '../lib/dart_common/Logger.dart' as Log;
import '../lib/shared/dbAllOurPhotos.dart';
import '../lib/SyncDriver.dart';


const LAST_RUN = 'last_run';

bool checkAllPhotos = false;
bool checkTesting = false;

main(List<String> arguments) async {
//  tryLogin().then((xx) async {await processImages();});
  arguments.forEach((arg){
    if (arg.toLowerCase().indexOf('all')>=0) checkAllPhotos = true;
    if (arg.toLowerCase().indexOf('test')>=0) checkTesting = true;
  });
  if (arguments.length>0  && arguments[0].toLowerCase().indexOf('all')>=0)
    checkAllPhotos = true;
  await tryLogin();
  await processImages();
  exit(0);
}

Future<void> tryLogin() async {
  try {
    await loadConfig();
    var db = DbAllOurPhotos();
    await db.initConnection(config);
    await db.startSession(config);
  } catch(ex,st) {
    Log.error('Failed to start aopCameraSync - $ex \n $st');
    exit(16);
  }

} // of tryLogin

void processImages () async {
  Log.message('process images');
  DateTime thisRunTime = DateTime.now();
  DateTime lastRunTime;
  try {
    lastRunTime = DateTime.parse(config[LAST_RUN]);
  } catch (ex) {
    lastRunTime = DateTime(1900, 1, 1);
  }
  String localPath = config['photoRootDir'];
  if (!Directory(localPath).existsSync()) {
    Log.error('Failed to find image directory - $localPath');
    exit(16);
  }
  var syncDriver = SyncDriver(localFileRoot: localPath, fromDate: lastRunTime);
  List<FileSystemEntity> fileList = await syncDriver.loadFileList(allPhotos: checkAllPhotos);
  if (checkTesting)
    Log.message('Just testing the file scan');
  else {
    await syncDriver.processList(fileList);
    config[LAST_RUN] = thisRunTime.toString();
    await saveConfig();
    Log.message('processing complete');
  }
} // of process images

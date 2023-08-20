/*
  Created by chrisreynolds on 2019-09-26
  
  Purpose: 

*/

//import 'dart:io';
import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:aopcommon/aopcommon.dart';

import '../SyncDriver.dart';
import '../IosGallery.dart';
import 'scLogger.dart';

//import 'MultiGallerySelectPage.dart';

const LAST_RUN = 'last_run';
const APP_VERSION ='AOP Sync 24 July 23';

class HomePage extends StatefulWidget {
  final Function tryLogout;
  const HomePage(this.tryLogout, {Key? key}) : super(key: key); // of constructor

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static List<FileSystemEntity> latestFileList = [];
  DateTime lastRunTime = DateTime(1980);
  late DateTime thisRunTime;
  bool _inProgress = false;
  bool _hasWebServer = false;
  double _progressValue = 0.0;
  var iosGallery = IosGallery(); // do nothing yet
  late SyncDriver syncDriver;

  int get photoCount {
    if (Platform.isIOS)
      return iosGallery.count;
    else
      return latestFileList.length;
  } // of photoCount

  void setInProgress(bool value) {
    setState(() {
      _inProgress = value;
    });
  } // of setInProgress

  void updateProgressVar(int current, int max) {
    setState(() {
      _progressValue = max > 0 ? current / max : 0;
    });
  }

  String prettyDate(DateTime aDate) {
    if (aDate.isAfter(DateTime(1900, 0, 0)))
      return formatDate(aDate, format: 'dd mmm yyyy hh:nn');
    else
      return 'Never';
  }

  StreamController<String> get messages => syncDriver.messageController;

  void _showLogger(BuildContext context) {
     Navigator.push(context, MaterialPageRoute(builder:(context)=>LoggerList(),fullscreenDialog: true));
  }
  @override
  Widget build(BuildContext context) {
    return
        Scaffold(
            appBar: AppBar(title: Text(APP_VERSION), actions: <IconButton>[
              IconButton(
                icon: Icon(Icons.list),
                onPressed: ()=>_showLogger(context),
              ),
              IconButton(
                icon: Icon(Icons.exit_to_app),
                onPressed: widget.tryLogout as void Function()?,
              ),
            ]),
            body: Stack(children: [
              StreamBuilder<String>(
                  stream: syncDriver.messageController.stream,
                  initialData: '',
                  builder: (BuildContext context, AsyncSnapshot<String> messageSnapshot) {
                   // log.message('building inprogress $_inProgress');
                    return Center(
                      child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Spacer(),
                            Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Spacer(flex:3),
                                    dateAdjustmentArrow('<Y',-365),
                                    dateAdjustmentArrow('<M',-30),
                                    dateAdjustmentArrow('<D',-1),
                                    dateAdjustmentArrow('>D',1),
                                    dateAdjustmentArrow('>M',30),
                                    dateAdjustmentArrow('>Y',365),
                                    const Spacer(flex:3),
                                  ],
                                ),
                            Spacer(),
                            Text(
                                'Last run: ${prettyDate(lastRunTime)}  '),
                            Spacer(flex:3),

                            if (!_inProgress)
                              ElevatedButton(
                                child: Text('Check for Photos'),
                                onPressed: () {
                                  setInProgress(true);
                                  outStandingPhotoCheck();
                                },
                              ), // of raisedButton
                            Spacer(),
                            if (messageSnapshot.data!.isNotEmpty)
                              Container(
                                margin: const EdgeInsets.all(15.0),
                                padding: const EdgeInsets.all(15.0),
                                decoration:
                                    BoxDecoration(border: Border.all(color: Colors.blueAccent)),
                                child: Text(
                                  messageSnapshot.data!,
                                  maxLines: 6,
                                ),
                              ),
                            Spacer(),
                            if (photoCount > 0 && !_inProgress && _hasWebServer)
                              ElevatedButton(
                                  child: Text('Process Photos'),
                                  onPressed: processPhotos), // of raisedButton
                            if (_inProgress)
                              Padding(
                                padding: const EdgeInsets.all(20.0),
                                child: LinearProgressIndicator(value: _progressValue),
                              ),
                            Spacer(
                              flex: 3,
                            ),

                          ]),
                    ); // of column
                  } // of builder
                  ),
              if (_inProgress)
                Center(
                  child: CircularProgressIndicator(),
                )
            ]) // of StreamBuilder
            ); // of scaffold
  } // of build

  Widget dateAdjustmentArrow(String label,int days) {
    return Padding(
      padding: const EdgeInsets.all(2.0),
      child: TextButton(
        style: ButtonStyle(// padding:MaterialStateProperty.all(EdgeInsets.zero),
          visualDensity: VisualDensity.compact,), //fixedSize: MaterialStateProperty.all(Size(50,18))),
        onPressed: () {moveDate(days);},
        child: Text(label,), //Icon(iconData),
      ),
    );
  }
  // Widget dateAdjustmentArrow(String label,int days) {
  //   return Padding(
  //     padding: const EdgeInsets.all(2.0),
  //       child: ElevatedButton(
  //         style: ButtonStyle(// padding:MaterialStateProperty.all(EdgeInsets.zero),
  //             visualDensity: VisualDensity.compact,), //fixedSize: MaterialStateProperty.all(Size(50,18))),
  //         onPressed: () {moveDate(days);},
  //         child: Text(label,), //Icon(iconData),
  //       ),
  //   );
  // }
  @override
  void initState() {
    try {
      lastRunTime = DateTime.parse(config[LAST_RUN]);
    } catch (ex) {
      lastRunTime = DateTime(1930, 1, 1);
    }
    WebFile.hasWebServer.then((result){_hasWebServer=result;});
//    if (!Platform.isIOS) {
    syncDriver = SyncDriver(localFileRoot: config['lcldirectory'] ?? '.',  fromDate: lastRunTime);
//    }
    super.initState();
  }
  void moveDate(int direction) {
    setState(() {
      lastRunTime = lastRunTime.add(Duration(days:direction));
    });
  }
  void outStandingPhotoCheck() async {
    try {
      messages.add('loading photos...');
      thisRunTime = DateTime.now();
      setInProgress(true);
      if (Platform.isIOS) {
        await iosGallery.loadFrom(lastRunTime);
      } else {
        syncDriver.fromDate = lastRunTime;
        latestFileList = await syncDriver.loadFileList(lastRunTime);
      }
      messages.add('I found $photoCount photos  ${_hasWebServer?"":" BUT NO SERVER"}');
    } catch (ex) {
      latestFileList = [];
      syncDriver.messageController.add('Error : $ex');
    }
    setInProgress(false);
  } // of outStandingPhotoCheck

  Future<void> processPhotos() async {
    if (Platform.isIOS)
      await processIOSImages();
    else
      await processFilePhotos();
  }

  Future<void> processFilePhotos() async {
    int errCount = 0, dupCount = 0, upLoadCount = 0;
    String progressMessage = '';
    try {
      setInProgress(true);
      messages.add('File Processing in progress. Please wait...');
      for (int i = 0; i < latestFileList.length; i++) {
        FileSystemEntity item = latestFileList[i];
        switch (await syncDriver.uploadImageFile(item as File)) {
          case true:
            upLoadCount++;
            break;
          case false:
            errCount++;
            break;
          default:
            dupCount++;
            break;
        } // of switch
        progressMessage = 'Uploaded $upLoadCount \nErrors $errCount \nDups $dupCount '
            '\nRemaining ${latestFileList.length - i - 1}';
        messages.add(progressMessage);
        updateProgressVar(i + 1, latestFileList.length);
        log.message(item.path);
      }
      iosGallery.clearCollection();
      messages.add('$progressMessage \n\nProcessing completed');
      config[LAST_RUN] = formatDate(thisRunTime, format: 'yyyy-mm-dd hh:nn:ss');
      await saveConfig(); // persist this run time so that we know how far back to go next time},
      latestFileList = [];
      log.save();
    } catch (ex) {
      syncDriver.messageController.add('Error : $ex');
    }
    setInProgress(false);
  } // of processFilePhotos

  Future<void> processIOSImages() async {
    int errCount = 0, dupCount = 0, upLoadCount = 0;
    String progressMessage = '';
    try {
      setInProgress(true);
      messages.add('IOS Processing in progress. Please wait...');
      for (int i = 0; i < iosGallery.count; i++) {
        GalleryItem item = (await iosGallery[i])!;
        switch (await syncDriver.uploadImage(item.safeFilename, item.createdDate, item.data, jpegLoader: item.loader)) {
          case true:
            upLoadCount++;
            break;
          case false:
            errCount++;
            break;
          default:
            dupCount++;
            break;
        } // of switch
        progressMessage = 'Uploaded $upLoadCount \nErrors $errCount \nDups $dupCount '
            '\nRemaining ${iosGallery.count - i - 1}';
        messages.add(progressMessage);
        updateProgressVar(i + 1, iosGallery.count);
        log.message(item.safeFilename);
      }
      iosGallery.clearCollection();
      messages.add('$progressMessage \n\nProcessing completed');
      config[LAST_RUN] = formatDate(thisRunTime, format: 'yyyy-mm-dd hh:nn:ss');
      await saveConfig(); // persist this run time so that we know how far back to go next time},
      latestFileList = [];
    } catch (ex) {
      syncDriver.messageController.add('Error : $ex');
    }
    setInProgress(false);
  } // of processIOSImages

} // of _HomePageState

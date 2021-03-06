/*
  Created by chrisreynolds on 2019-09-26
  
  Purpose: 

*/

//import 'dart:io';
import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:aopcommon/aopcommon.dart';

import '../SyncDriver.dart';
import '../IosGallery.dart';
import 'scLogger.dart';

//import 'MultiGallerySelectPage.dart';

const LAST_RUN = 'last_run';

class HomePage extends StatefulWidget {
  final Function tryLogout;
  HomePage(this.tryLogout) : super(); // of constructor

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static List<FileSystemEntity> latestFileList = [];
  DateTime lastRunTime;
  DateTime thisRunTime;
  int _selectAll = 0;   // 0=normal, 1= show buttons, 2 = fix date
  bool _inProgress = false;
  bool _hasWebServer = false;
  double _progressValue = 0.0;
  var iosGallery = IosGallery(); // do nothing yet
  SyncDriver syncDriver;

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

  void _toogleSelectAll() {
    _selectAll = (_selectAll+1) % 3;  //rotate around 0,1,2,
    setState(() {});
  } // _toggleSelectAll

  void _showLogger(BuildContext context) {
     Navigator.push(context, MaterialPageRoute(builder:(context)=>LoggerList(),fullscreenDialog: true));
  }
  @override
  Widget build(BuildContext context) {
    return
        Scaffold(
            appBar: AppBar(title: Text('AOP Sync 18May21'), actions: <IconButton>[
              IconButton(
                icon: Icon(Icons.select_all),
                onPressed: _toogleSelectAll,
              ),
              IconButton(
                icon: Icon(Icons.list),
                onPressed: ()=>_showLogger(context),
              ),
              IconButton(
                icon: Icon(Icons.close),
                onPressed: widget.tryLogout,
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
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Spacer(),

                            if (_selectAll==1) Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  dateAdjustmentArrow(Icons.chevron_left,-30),
                                  dateAdjustmentArrow(Icons.chevron_left,-1),
                                  dateAdjustmentArrow(Icons.chevron_right,1),
                                  dateAdjustmentArrow(Icons.double_arrow,30),
                                ],
                              ),
                            Text(
                                'Last run: ${prettyDate(lastRunTime)}   ${_selectAll==2 ? 'but all Selected' : ''}'),
                            Spacer(),

                            if (!_inProgress)
                              ElevatedButton(
                                child: Text('Check for Photos'),
                                onPressed: () {
                                  setInProgress(true);
                                  outStandingPhotoCheck();
                                },
                              ), // of raisedButton
                            Spacer(),
                            if (messageSnapshot.data.length > 0)
                              Container(
                                margin: const EdgeInsets.all(15.0),
                                padding: const EdgeInsets.all(15.0),
                                decoration:
                                    BoxDecoration(border: Border.all(color: Colors.blueAccent)),
                                child: Text(
                                  messageSnapshot.data,
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

  Widget dateAdjustmentArrow(IconData iconData,int days) {
    return ButtonTheme(
      minWidth: 50.0,
      height: 100.0,
      child: ElevatedButton(
        onPressed: () {moveDate(days);},
        child: Icon(iconData),
      ),
    );
  }
  @override
  void initState() {
    try {
      lastRunTime = DateTime.parse(config[LAST_RUN]);
    } catch (ex) {
      lastRunTime = DateTime(1900, 1, 1);
      _selectAll = 1;  // show arrows
    }
    WebFile.hasWebServer.then((result){_hasWebServer=result;});
//    if (!Platform.isIOS) {
    syncDriver = SyncDriver(localFileRoot: config['lcldirectory'], fromDate: lastRunTime);
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
        await iosGallery.loadFrom((_selectAll!=2) ? lastRunTime : DateTime(1900, 1, 1));
      } else {
        syncDriver.fromDate = lastRunTime;
        latestFileList = await syncDriver.loadFileList((_selectAll!=2) ? lastRunTime : DateTime(1900, 1, 1));
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
    try {
      setInProgress(true);
      messages.add('File Processing in progress. Please wait...');
      for (int i = 0; i < latestFileList.length; i++) {
        FileSystemEntity item = latestFileList[i];
        switch (await syncDriver.uploadImageFile(item)) {
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
        messages.add('Uploaded $upLoadCount \nErrors $errCount \nDups $dupCount ' +
            '\nRemaining ${latestFileList.length - i - 1}');
        updateProgressVar(i + 1, latestFileList.length);
        print(item.path);
      }
      iosGallery.clearCollection();
      messages.add('Processing completed \n Uploaded $upLoadCount \n Errors $errCount \n Dups $dupCount');
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
    try {
      setInProgress(true);
      messages.add('IOS Processing in progress. Please wait...');
      for (int i = 0; i < iosGallery.count; i++) {
        GalleryItem item = await iosGallery[i];
        switch (await syncDriver.uploadImage(item.safeFilename, item.createdDate, item.data)) {
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
        messages.add('Uploaded $upLoadCount \nErrors $errCount \nDups $dupCount ' +
            '\nRemaining ${iosGallery.count - i - 1}');
        updateProgressVar(i + 1, iosGallery.count);
        print(item.safeFilename);
      }
      iosGallery.clearCollection();
      messages.add('Processing completed');
      config[LAST_RUN] = formatDate(thisRunTime, format: 'yyyy-mm-dd hh:nn:ss');
      await saveConfig(); // persist this run time so that we know how far back to go next time},
      latestFileList = [];
    } catch (ex) {
      syncDriver.messageController.add('Error : $ex');
    }
    setInProgress(false);
  } // of processIOSImages

} // of _HomePageState

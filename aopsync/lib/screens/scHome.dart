/*
  Created by chrisreynolds on 2019-09-26
  
  Purpose: 

*/

//import 'dart:io';
import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

//import 'package:path_provider/path_provider.dart';
import '../dart_common/Config.dart';
import '../dart_common/Logger.dart' as Log;
import '../SyncDriver.dart';
import '../dart_common/DateUtil.dart';
import '../IosGallery.dart';
import 'MultiGallerySelectPage.dart';

const LAST_RUN = 'last_run';

class HomePage extends StatefulWidget {
  Function tryLogout;

  HomePage(this.tryLogout) : super() {} // of constructor

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static List<FileSystemEntity> latestFileList = [];
  DateTime lastRunTime;
  DateTime thisRunTime;
  bool _selectAll = false;
  bool _inProgress = false;
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

  String prettyDate(DateTime aDate) {
    if (aDate.isAfter(DateTime(1900,0,0)))
      return formatDate(aDate,format:'dd mmm yyyy');
    else
      return 'Never';
  }
  StreamController<String> get messages => syncDriver.messageController;

  void _toogleSelectAll() {
    _selectAll = !_selectAll;
    setState(() {});
  } // _toggleSelectAll

  @override
  Widget build(BuildContext context) {
    Log.message('Home builder');
    return //(1==1)?ProgressForm():
        Scaffold(
            appBar: AppBar(title: Text('AllOurPhoto Upload 28Feb'), actions: <IconButton>[
              IconButton(
                icon: Icon(Icons.select_all),
                onPressed: _toogleSelectAll,
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
                    Log.message('building with $_selectAll and $_inProgress');
                    return Center(
                      child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Spacer(),
                            Text(
                                'Last run: ${prettyDate(lastRunTime)}   ${_selectAll ? 'but all Selected' : ''}'),
                            Spacer(),

 //                           if (!_inProgress)
                              RaisedButton(
                                child: Text('Check for Photos'),
                                onPressed: () {
                                  setInProgress(true);
                                  outStandingPhotoCheck();
                                },
                              ), // of raisedButton
                            Spacer(),
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
                            if (photoCount > 0 && !_inProgress)
                              RaisedButton(
                                  child: Text('Process Photos'),
                                  onPressed: processPhotos), // of raisedButton

                            Spacer(
                              flex: 3,
                            )
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

  @override
  void initState() {
    try {
      lastRunTime = DateTime.parse(config[LAST_RUN]);
    } catch (ex) {
      lastRunTime = DateTime(1900, 1, 1);
      _selectAll = true;
    }
    if (!Platform.isIOS) {
      syncDriver = SyncDriver(localFileRoot: config['lcldirectory'], fromDate: lastRunTime);
    }
    super.initState();
  }

  void outStandingPhotoCheck() async {
    try {
      messages.add('loading photos...');
      thisRunTime = DateTime.now();
      setInProgress(true);
      if (Platform.isIOS) {
        await iosGallery.loadFrom(!_selectAll ? lastRunTime : DateTime(1900, 1, 1));
      } else {
        latestFileList = await syncDriver.loadFileList(allPhotos: _selectAll);
      }
      messages.add('I found ${photoCount} photos');
    } catch (ex) {
      latestFileList = [];
      syncDriver.messageController.add('Error : $ex');
    }
    setInProgress(false);
  } // of outStandingPhotoCheck

  void processPhotos() async {
    try {
      setInProgress(true);
      messages.add('Processing in progress. Please wait...');
      if (Platform.isIOS) {
        for (int i=0;i<iosGallery.count;i++) {
          GalleryItem item = await iosGallery[i];
          print(item.safeFilename);
        }
      } else {
        await syncDriver.processList(latestFileList);
      }
      config[LAST_RUN] = formatDate(thisRunTime, format: 'yyyy-mm-dd hh:nn:ss');
      await saveConfig(); // persist this run time so that we know how far back to go next time},
      latestFileList = [];
    } catch (ex) {
      syncDriver.messageController.add('Error : $ex');
    }
    setInProgress(false);
  } // of processPhotos

} // of _HomePageState



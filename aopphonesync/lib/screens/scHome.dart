/*
  Created by chrisreynolds on 2019-09-26
  
  Purpose: 

*/

//import 'dart:io';
import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:image_gallery/image_gallery.dart';

//import 'package:path_provider/path_provider.dart';
import '../dart_common/Config.dart';
import '../dart_common/Logger.dart' as Log;
import '../SyncDriver.dart';
import '../dart_common/DateUtil.dart';

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
  SyncDriver syncDriver;

  void setInProgress(bool value) {
    _inProgress = value;
//    messages.add('');
    setState(() {});
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
            appBar: AppBar(title: Text('AllOurPhoto Upload 9Nov'), actions: <IconButton>[
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
                            if (latestFileList.length > 0 && !_inProgress)
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
    syncDriver = SyncDriver(localFileRoot: config['lcldirectory'], fromDate: lastRunTime);
    super.initState();
  }

  void outStandingPhotoCheck() async {
    try {
      messages.add('loading photos...');
      thisRunTime = DateTime.now();
      setInProgress(true);
      latestFileList = await syncDriver.loadFileList(allPhotos: _selectAll);
      messages.add('I found ${latestFileList.length} photos');
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
      await syncDriver.processList(latestFileList);
      config[LAST_RUN] = formatDate(thisRunTime, format: 'yyyy-mm-dd hh:nn:ss');
      await saveConfig(); // persist this run time so that we know how far back to go next time},
      latestFileList = [];
    } catch (ex) {
      syncDriver.messageController.add('Error : $ex');
    }
    setInProgress(false);
  } // of processPhotos

} // of _HomePageState

class ProgressForm2 extends StatefulWidget {
  @override
  _ProgressFormState createState() => _ProgressFormState();
}

class _ProgressFormState extends State<ProgressForm2> {
  List<Object> allImage = new List();

  @override
  void initState() {
    super.initState();
    loadImageList();
  }

  Future<void> loadImageList() async {
    List allImageTemp;
    allImageTemp = await FlutterGallaryPlugin.getAllImages;
    for (String fileName in allImageTemp) {
      File aFile = File(fileName);
      FileStat stat = aFile.statSync();
      print(stat.modified);
    }
    setState(() {
      this.allImage = allImageTemp;
    });
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      appBar: new AppBar(
        title: Text('AOP PhoneSync'),
      ),
      body: _buildGrid(),
    );
  }

  Widget _buildGrid() {
    return GridView.extent(
        maxCrossAxisExtent: 150.0,
        // padding: const EdgeInsets.all(4.0),
        mainAxisSpacing: 4.0,
        crossAxisSpacing: 4.0,
        children: _buildGridTileList(allImage.length));
  }

  List<Container> _buildGridTileList(int count) {
    return List<Container>.generate(
        count,
        (int index) => Container(
                child: Image.file(
              File(allImage[index].toString()),
              width: 96.0,
              height: 96.0,
              fit: BoxFit.contain,
            )));
  }
}

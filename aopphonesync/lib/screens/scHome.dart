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

class HomePage extends StatelessWidget {
  static List<FileSystemEntity> latestFileList = [];
  DateTime thisRunTime;
  final Function tryLogout;
  SyncDriver syncDriver;

  StreamController<String> get messages => syncDriver.messageController;

  HomePage(this.tryLogout) : super() {
    DateTime lastRunTime;
    try {
      lastRunTime = DateTime.parse(config[LAST_RUN]);
    } catch (ex) {
      lastRunTime = DateTime(1900, 1, 1);
    }
    syncDriver = SyncDriver(localFileRoot: config['lcldirectory'], fromDate: lastRunTime);
  } // of constructor

  void outStandingPhotoCheck({bool allPhotos: false}) async {
    try {
      messages.add('loading photos...');
      thisRunTime = DateTime.now();
      latestFileList = await syncDriver.loadFileList(allPhotos: allPhotos);
      messages.add('Ive got ${latestFileList.length} photos');
    } catch (ex) {
      latestFileList = [];
      syncDriver.messageController.add('Error : $ex');
    }
  } // of outStandingPhotoCheck

  @override
  Widget build(BuildContext context) {
    Log.message('Home builder');
    return //(1==1)?ProgressForm():
        Scaffold(
            appBar: AppBar(title: Text('AllOurPhoto Phone Upload 30Sep')),
            body: StreamBuilder<String>(
                stream: syncDriver.messageController.stream,
                initialData: '',
                builder: (BuildContext context, AsyncSnapshot<String> messageSnapshot) {
                  return Center(
                    child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Spacer(),
                          Container(
                            margin: const EdgeInsets.all(15.0),
                            padding: const EdgeInsets.all(15.0),
                            decoration: BoxDecoration(
                                border: Border.all(color: Colors.blueAccent)
                            ),
                            child: Text(
                              messageSnapshot.data,
                              maxLines: 4,
                            ),
                          ),
                          Spacer(),
                          RaisedButton(
                            child: Text('Check for photos'),
                            onPressed: () {outStandingPhotoCheck(allPhotos: false);},
                          ), // of raisedButton
                          RaisedButton(
                            child: Text('or Gather ALL photos'),
                            onPressed: () {outStandingPhotoCheck(allPhotos: true);},
                          ), // of raisedButton
                          Spacer(),
                          RaisedButton(
                              child: Text('Process photos'),
                              onPressed: () {
                                syncDriver.processList(latestFileList);
                                config[LAST_RUN] =
                                    formatDate(thisRunTime, format: 'yyyy-mm-d hh:nn:ss');
                                saveConfig(); // persist this run time so that we know how far back to go next time},
                              }), // of raisedButton
                          Spacer(),
                          RaisedButton(
                            child: Text('Sign Out'),
                            onPressed: tryLogout,
                          ), // of raisedButton
                          Spacer(
                            flex: 3,
                          )
                        ]),
                  ); // of column
                } // of builder
                ) // of StreamBuilder
            ); // of scaffold
  } // of build

} // of class scHome

//typedef MessageCallback = void Function(String mess);
//typedef ProgressCallback = void Function(int sofar, int max);
//
//class PhoneSyncDriver {
//  MessageCallback messCB;
//  ProgressCallback progCB;
//
//  PhoneSyncDriver(this.messCB, this.progCB);
//
//
//} // of PhoneSyncDriver

class ProgressForm extends StatefulWidget {
  @override
  _ProgressFormState createState() => _ProgressFormState();
}

class _ProgressFormState extends State<ProgressForm> {
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

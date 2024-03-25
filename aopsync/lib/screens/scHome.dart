/*
  Created by chrisreynolds on 2019-09-26
  
  Purpose: 

*/

import 'dart:async';
//import 'dart:io';
import 'package:flutter/material.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:aopcommon/aopcommon.dart';
import '../utils/Config.dart';
import '../SyncDriver.dart';
import 'scLogger.dart';
//import 'package:aopsync/fileFate.dart';

const LAST_RUN = 'last_run';

class HomePage extends StatefulWidget {
  final Function tryLogout;
  final String title;
  const HomePage(
      {required this.tryLogout,
      required this.title,
      super.key}); // of constructor

  @override
  HomePageState createState() => HomePageState();
}

class HomePageState extends State<HomePage> {
  DateTime lastRunTime = DateTime(1980);
  late DateTime thisRunTime;
  bool _inProgress = false;
  bool _hasWebServer = false;
  double _progressValue = 0.0;
//  var iosGallery = IosGallery(); // do nothing yet
  late SyncDriver syncDriver;

  void setInProgress(bool value) {
    setState(() {
      _inProgress = value;
      if (_inProgress)
        WakelockPlus.enable();
      else
        WakelockPlus.disable();
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

  StreamController<String> messages = StreamController<String>();
//  StreamController<String> get messages => syncDriver.messageController;

  void _showLogger(BuildContext context) {
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => LoggerList(), fullscreenDialog: true));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: Text(widget.title), actions: <IconButton>[
          IconButton(
            icon: Icon(Icons.list),
            onPressed: () => _showLogger(context),
          ),
          IconButton(
            icon: Icon(Icons.exit_to_app),
            onPressed: widget.tryLogout as void Function()?,
          ),
        ]),
        body: Stack(children: [
          StreamBuilder<String>(
              stream: messages.stream,
              initialData: '',
              builder: (BuildContext context,
                  AsyncSnapshot<String> messageSnapshot) {
                // log.debug('building inprogress $_inProgress');
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
                            const Spacer(flex: 3),
                            dateAdjustmentArrow('<Y', -365),
                            dateAdjustmentArrow('<M', -30),
                            dateAdjustmentArrow('<D', -1),
                            dateAdjustmentArrow('>D', 1),
                            dateAdjustmentArrow('>M', 30),
                            dateAdjustmentArrow('>Y', 365),
                            const Spacer(flex: 3),
                          ],
                        ),
                        Spacer(),
                        Text('Last run: ${prettyDate(lastRunTime)}  '),
                        Spacer(flex: 3),

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
                            decoration: BoxDecoration(
                                border: Border.all(color: Colors.blueAccent)),
                            child: Text(
                              messageSnapshot.data!,
                              maxLines: 6,
                            ),
                          ),
                        Spacer(),
                        if (syncDriver.count > 0 &&
                            !_inProgress &&
                            _hasWebServer)
                          ElevatedButton(
                            onPressed: processPhotos,
                            child: Text('Process Photos'),
                          ),
                        if (_inProgress)
                          Padding(
                            padding: const EdgeInsets.all(20.0),
                            child:
                                LinearProgressIndicator(value: _progressValue),
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

  Widget dateAdjustmentArrow(String label, int days) {
    return Padding(
      padding: const EdgeInsets.all(2.0),
      child: TextButton(
        style: ButtonStyle(
          // padding:MaterialStateProperty.all(EdgeInsets.zero),
          visualDensity: VisualDensity.compact,
        ), //fixedSize: MaterialStateProperty.all(Size(50,18))),
        onPressed: () {
          moveDate(days);
        },
        child: Text(
          label,
        ), //Icon(iconData),
      ),
    );
  }

  @override
  void initState() {
    try {
      lastRunTime = DateTime.parse(config[LAST_RUN]);
    } catch (ex) {
      lastRunTime = DateTime(1980, 1, 1);
    }
    WebFile.hasWebServer.then((result) {
      _hasWebServer = result;
    });
    syncDriver = SyncDriver(
        localFileRoot: config['lclDirectory'] ?? '.',
        messageStream: messages,
        indicateProgress: updateProgressVar);
//    }
    super.initState();
  }

  void moveDate(int direction) {
    setState(() {
      lastRunTime = lastRunTime.add(Duration(days: direction));
    });
  }

  void outStandingPhotoCheck() async {
    try {
      messages.add('loading photos...');
      thisRunTime = DateTime.now();
      setInProgress(true);
      await syncDriver.loadFileList(lastRunTime);
      messages.add(
          'I found ${syncDriver.count} photos  ${_hasWebServer ? "" : " BUT NO SERVER"}');
    } catch (ex) {
      messages.add('Error : $ex');
      log.error('$ex');
    }
    setInProgress(false);
  } // of outStandingPhotoCheck

  Future<void> processPhotos() async {
    setInProgress(true);
    try {
      bool result = await syncDriver.processFilePhotos();
      if (result) {
//        messages.add('Processing finished');
        config[LAST_RUN] =
            formatDate(thisRunTime, format: 'yyyy-mm-dd hh:nn:ss');
        // persist this run time so that we know how far back to go next time}
        await config.save();
      }
    } catch (ex) {
      log.error('$ex');
      messages.add('ERROR! $ex');
    }
    setInProgress(false);
    setState(() {});
    return;
  }
} // of _HomePageState

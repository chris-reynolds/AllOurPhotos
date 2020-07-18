/*
  Created by chrisreynolds on 2019-10-18
  
  Purpose: Stateful DbFixFormWidget
*/

import 'dart:convert';

import 'package:all_our_photos_app/shared/aopClasses.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as IM;
import '../dart_common/Logger.dart' as Log;
import '../dart_common/DateUtil.dart';
import '../dart_common/WebFile.dart';
import '../dart_common/ImageUploader.dart';
import '../flutter_common/WidgetSupport.dart';

class DbFixFormWidget extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return new DbFixFormWidgetState();
  }
}

typedef SnapProcessor = Function(AopSnap snap);

class DbFixFormWidgetState extends State<DbFixFormWidget> {
  bool inProgress = false;
  String runType = '----';
  String groupQuery;
  String detailQuery;
  SnapProcessor snapProcessor;
  String inputWhere = '';
  String fullWhere = '';
  List<String> groups = [];
  List<AopSnap> snapList = [];
  int snapIdx = -1;
  int groupIdx = -1;

  String get currentGroupName =>
      (groupIdx >= 0 && groupIdx < groups.length) ? groups[groupIdx] : 'Current group not ready';

  AopSnap get currentSnap => (snapIdx >= 0 && snapIdx < snapList.length) ? snapList[snapIdx] : null;

  void fixTakenDateDriver() async {
    runType = 'Restore Taken Date from metaData';
    if (await confirmYesNo(context, runType)) {
      groupQuery =
      'select distinct directory from aopsnaps where ${(inputWhere.isNotEmpty)
          ? inputWhere
          : '1=1'} order by 1';
      detailQuery = "directory='GROUP'";
      await processGroups(fixSingleTakenDate);
    }
  }

  Future<void> fixSingleTakenDate(AopSnap snap) async {
    Log.message('Processing ${snap.fileName}');
    dynamic meta = jsonDecode(snap.metadata ?? '{}');
    String origDateStr = meta['DateTimeOriginal'] ?? meta['DateTime'];
    if (origDateStr != null)
      try {
        DateTime origDate = dateTimeFromExif(origDateStr);
        int secsDiff = origDate
            .difference(snap.takenDate)
            .inSeconds
            .abs();
        if (secsDiff > 120) {
          // acouple of minuts is not rounding
          Log.message('taken date needs fixing*** ${snap.ranking}');
          snap.takenDate = origDate;
          snap.originalTakenDate = origDate;
          await snap.save();
        }
      } catch (ex) {
        Log.error('Invalid date $origDateStr');
      }
  } // of fixSingleTakenDate

  void fixThumbnailDriver() async {
    if (inputWhere.isEmpty) {
      showMessage(context, 'Please enter a camera model');
      return;
    }
    runType = 'Fix Thumbnail for orientation 6';
    if (await confirmYesNo(context, runType)) {
      fullWhere =
      ' (metadata like \'%Orientation":6%\' or metadata like \'%Orientation":8%\') and device_name like \'%$inputWhere%\' ';
      groupQuery = 'select distinct directory from aopsnaps where $fullWhere order by 1';
      detailQuery = "directory='GROUP' ";
      await processGroups(fixSingleThumbnail);
    }
  } // of fixThumbnailDriver

  Future<void> fixSingleThumbnail(AopSnap snap) async {
    Log.message('Processing ${snap.fileName}');
    dynamic meta = jsonDecode(snap.metadata ?? '{}');
    try {
      IM.Image fullPic = await loadWebImage(snap.fullSizeURL);
      IM.Image thumbnail = makeThumbnail(fullPic);
//      IM.Image thumbnail = IM.copyResize( fullPic, width: 480); // you know it is portrait from orientation
      await saveWebImage(snap.thumbnailURL, image: thumbnail, quality: 50);
      Log.message(' to fix ${snap.thumbnailURL}');
    } catch (ex) {
      Log.error('Failed to fix thumbnail $ex');
    }
  } // of fixSingleThumbnail

  Future<void> processGroups(SnapProcessor snapFn) async {
    var r = await snapProvider.rawExecute(groupQuery);
    groups = [];
    for (var row in r)
      groups.add(row[0]);
    snapList = [];
    snapIdx = 0;
    groupIdx = -1; // it is going to be incremented and we want to start at zero
    inProgress = true;
    while (inProgress = await processNextSnap()) {
      setState(() {});
      await snapFn(currentSnap);
    }
    inProgress = false;
    setState(() {}); // extra setstate cleans up after run is finished
  } //

  Future<bool> processNextSnap() async {
    ++snapIdx; // dont put into while as difficult to understand
    while (snapIdx >= snapList.length) {
      // time to get another group
      groupIdx++;
      if (groupIdx >= groups.length) {
        //exit if no more groups
        return false;
      }
      String thisWhereClause = detailQuery.replaceAll('GROUP', currentGroupName);
      if (fullWhere.isNotEmpty)
        thisWhereClause += ' and ' + fullWhere;
      else if (inputWhere.isNotEmpty)
        thisWhereClause += ' and ' + inputWhere;
      snapList = await snapProvider.getSome(thisWhereClause, orderBy: 'id');
      snapIdx = 0;
    }
    return true;
  } // of processNextSnap

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      appBar: AppBar(
        title: Text('DB Fix'),
        actions: <Widget>[
          IconButton(icon: Icon(Icons.date_range), onPressed: fixTakenDateDriver),
          IconButton(icon: Icon(Icons.thumb_up), onPressed: fixThumbnailDriver),
        ],
      ),
      body:
      Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: <Widget>[
          Text(runType, style: Theme
              .of(context)
              .textTheme
              .headline4),
          //Spacer(),
          TextField(
            decoration: InputDecoration(
              labelText: 'filter',
            ),
            onChanged: (txt) => inputWhere = txt,
          ),
          if (groupIdx >= 0)
            Text(
              '$currentGroupName',
              style: Theme
                  .of(context)
                  .textTheme
                  .bodyText1,
            ),
          if (currentSnap != null)
            Text('${currentSnap.fileName}  - $snapIdx of ${snapList.length}',
                style: Theme
                    .of(context)
                    .textTheme
                    .bodyText1),
          if (inProgress)
            Center(
              child: CircularProgressIndicator(),
            )
        ],
      ), //front column
    );
  }
}

/*
  Created by chrisreynolds on 2019-10-18
  
  Purpose: Stateful DbFixFormWidget
*/

import 'dart:convert';
import 'dart:io';

import 'package:aopmodel/aopClasses.dart';
import 'package:aopcommon/aopcommon.dart';
import 'package:flutter/material.dart';
//import 'package:image/image.dart' as IM;
//import '../dart_common/ImageUploader.dart';
import '../flutter_common/WidgetSupport.dart';

class DbFixFormWidget extends StatefulWidget {
  const DbFixFormWidget({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return DbFixFormWidgetState();
  }
}

typedef SnapProcessor = Function(AopSnap? snap);

class DbFixFormWidgetState extends State<DbFixFormWidget> {
  bool inProgress = false;
  String runType = '----';
  late String groupQuery;
  late String detailQuery;
  SnapProcessor? snapProcessor;
  String inputWhere = '';
  String fullWhere = '';
  List<String?> groups = [];
  List<AopSnap> snapList = [];
  int snapIdx = -1;
  int groupIdx = -1;

  String? get currentGroupName => (groupIdx >= 0 && groupIdx < groups.length)
      ? groups[groupIdx]
      : 'Current group not ready';

  AopSnap? get currentSnap =>
      (snapIdx >= 0 && snapIdx < snapList.length) ? snapList[snapIdx] : null;

  void fixTakenDateDriver() async {
    runType = 'Restore Taken Date from metaData';
    if ((await confirmYesNo(context, runType))!) {
      groupQuery =
          'select distinct directory from aopsnaps where ${(inputWhere.isNotEmpty) ? inputWhere : '1=1'} order by 1';
      detailQuery = "directory='GROUP'";
      await processGroups(fixSingleTakenDate);
    }
  }

  Future<void> fixSingleTakenDate(AopSnap? snap) async {
    log.message('Processing ${snap!.fileName}');
    dynamic meta = jsonDecode(snap.metadata ?? '{}');
    String? origDateStr = meta['DateTimeOriginal'] ?? meta['DateTime'];
    if (origDateStr != null)
      try {
        DateTime origDate = dateTimeFromExif(origDateStr)!;
        int secsDiff = origDate.difference(snap.takenDate!).inSeconds.abs();
        if (secsDiff > 120) {
          // acouple of minuts is not rounding
          log.message('taken date needs fixing*** ${snap.ranking}');
          snap.takenDate = origDate;
          snap.originalTakenDate = origDate;
          await snap.save();
        }
      } catch (ex) {
        log.error('Invalid date $origDateStr');
      }
  } // of fixSingleTakenDate

  void fixThumbnailDriver() async {
    if (inputWhere.isEmpty) {
      showMessage(context, 'Please enter a camera model');
      return;
    }
    runType = 'Fix Thumbnail for orientation 6';
    if ((await confirmYesNo(context, runType))!) {
      fullWhere =
          ' (metadata like \'%Orientation":6%\' or metadata like \'%Orientation":8%\') and device_name like \'%$inputWhere%\' ';
      groupQuery =
          'select distinct directory from aopsnaps where $fullWhere order by 1';
      detailQuery = "directory='GROUP' ";
      await processGroups(fixSingleThumbnail);
    }
  } // of fixThumbnailDriver

  Future<void> fixSingleThumbnail(AopSnap? snap) async {
    throw ('fix single thumbnail');
    // log.message('Processing ${snap!.fileName}');
    // dynamic meta = jsonDecode(snap.metadata ?? '{}');
    // try {
    //   IM.Image fullPic = (await loadWebImage(snap.fullSizeURL))!;
    //   IM.Image thumbnail = makeThumbnail(fullPic);
    //   await saveWebImage(snap.thumbnailURL, image: thumbnail, quality: 50);
    //   log.message(' to fix ${snap.thumbnailURL}');
    // } catch (ex) {
    //   log.error('Failed to fix thumbnail $ex');
    // }
  } // of fixSingleThumbnail

  Future<void> importMacAlbums(BuildContext context) async {
    const PHOTOID_SQL = "select id from aopsnaps where metadata like '%xxxx%'";
    String filename = '';
    var jpegLoader = JpegLoader();
    try {
      Directory importDir = Directory(
          '/Users/chrisreynolds/Desktop/projects/AllOurPhotos/photos_albums/janets_albums');
      var fseList = importDir.listSync();
      fseList.sort((f1, f2) => f1.path.compareTo(f2.path));
      var workList = [];
      for (var fse in fseList) {
        filename = fse.path.split('/').last;
        var delimPos = filename.indexOf(' - ');
        assert(delimPos > 0, 'no delimiter');
        var album = filename.substring(0, delimPos).trimRight();
        List<int> contents = File(fse.path).readAsBytesSync();
        await jpegLoader.extractTags(contents);
        var dto =
            jpegLoader.tags['DateTimeOriginal'] ?? jpegLoader.tags['DateTime'];
        if (dto != null) {
          var photoList = await snapProvider
              .rawExecute(PHOTOID_SQL.replaceAll('xxxx', dto));
          int? photoId = -1;
          if (photoList != null && photoList.isNotEmpty)
            photoId = photoList.first['id'];
          var item = {
            'name': filename,
            'album': album,
            'dto': dto,
            'photoid': photoId,
            'count': photoList.length ?? 0,
            'path': fse.path
          };
          workList.add(item);
          log.message('$item');
        } else
          log.message('skipped $filename lacked date');
      }
      String? currentAlbum = '';
      int? albumId = -1;
      for (var item in workList) {
        String? thisAlbum = item['album'];
        if (currentAlbum != item['album']) {
          var albumList = await albumProvider.rawExecute(
              'select * from aopalbums where name like \'%$thisAlbum%\'');
          if (albumList.isEmpty) {
            log.message('!!!!!!! CREATE ALBUM $thisAlbum');
            currentAlbum = thisAlbum;
            var newAlbum = AopAlbum(data: {'name': '2025 $thisAlbum'});
            var result = (await newAlbum.save())!;
            if (result > 0)
              albumId = result;
            else
              throw 'bad result on album save $result';
          } else
            albumId = albumList.first['id'];
        } // of newAlbum
        int? photoId = item['photoid'];
        var existingItems = await albumItemProvider.rawExecute(
            'select * from aopalbum_items where album_id=$albumId and snap_id=$photoId');
        if (existingItems.isEmpty && albumId! > 0 && photoId! > 0) {
          log.message('creating ${item['name']}');
          var albumItem = AopAlbumItem(data: {})
            ..snapId = photoId
            ..albumId = albumId;
          var result = (await albumItem.save())!;
          if (result <= 0)
            log.error('cant save item');
          else
            log.message('created');
        } // make new albumItem
        else
          log.message('skip ${item['name']}');
      } // of item loop
      log.message('Length is ${workList.length}');
      filename = 'done2';
      throw 'not implemented';
    } catch (e, s) {
      //log.error('Exception: $e\n$s\n');
      showMessage(context, 'Exception: $e\n$s\n $filename ');
    }
  }

  Future<void> processGroups(SnapProcessor snapFn) async {
    var r = await snapProvider.rawExecute(groupQuery);
    groups = [];
    for (var row in r) groups.add(row[0]);
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
      String thisWhereClause =
          detailQuery.replaceAll('GROUP', currentGroupName!);
      if (fullWhere.isNotEmpty)
        thisWhereClause += ' and $fullWhere';
      else if (inputWhere.isNotEmpty) thisWhereClause += ' and $inputWhere';
      snapList = await snapProvider.getSome(thisWhereClause, orderBy: 'id');
      snapIdx = 0;
    }
    return true;
  } // of processNextSnap

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('DB Fix'),
        actions: <Widget>[
          IconButton(
              icon: Icon(Icons.date_range), onPressed: fixTakenDateDriver),
          IconButton(icon: Icon(Icons.thumb_up), onPressed: fixThumbnailDriver),
          IconButton(
              icon: Icon(Icons.photo_album),
              onPressed: () {
                importMacAlbums(context);
              }),
        ],
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: <Widget>[
          Text(runType, style: Theme.of(context).textTheme.headlineMedium),
          //Spacer(),
          TextField(
            decoration: InputDecoration(
              labelText: 'filter',
            ),
            onChanged: (txt) => inputWhere = txt,
          ),
          if (groupIdx >= 0)
            Text(
              currentGroupName!,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          if (currentSnap != null)
            Text('${currentSnap!.fileName}  - $snapIdx of ${snapList.length}',
                style: Theme.of(context).textTheme.bodyLarge),
          if (inProgress)
            Center(
              child: CircularProgressIndicator(),
            )
        ],
      ), //front column
    );
  }
}

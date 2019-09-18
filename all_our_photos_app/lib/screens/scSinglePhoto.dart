/*
  Created by chrisreynolds on 2019-09-18
  
  Purpose: Stateful SinglePhotoWidget
*/

import 'dart:convert';
import 'package:all_our_photos_app/widgets/PhotoViewWithRectWidget.dart';
import 'package:flutter/material.dart';
import '../shared/aopClasses.dart';
import '../dart_common/Logger.dart' as Log;
import '../flutter_common/WidgetSupport.dart';

class SinglePhotoWidget extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return new SinglePhotoWidgetState();
  }
}

class SinglePhotoWidgetState extends State<SinglePhotoWidget> {
  List<AopSnap> snapList;
  int _snapIndex = -1;
  AopSnap currentSnap;
  final GlobalKey pvKey = GlobalKey();

  void _initParams() {
    List params = ModalRoute.of(context).settings.arguments;
    snapList = params[0];
    _snapIndex = params[1];
  } // of initParams

  void set snapIndex(int newIndex) {
    if (newIndex >= 0 && newIndex < snapList.length)
      setState(() {
        _snapIndex = newIndex;
      });
  }

  Widget buildAppBar(BuildContext context) {
    return AppBar(
      title: new Text(currentSnap.fileName + ' ' + currentSnap.caption),
      actions: <Widget>[

          IconButton(
            icon: Icon(Icons.arrow_upward),
            onPressed: (_snapIndex == 0)? null : () {
              snapIndex = _snapIndex - 1;
            },
          ),

          IconButton(
              icon: Icon(Icons.arrow_downward),
              onPressed: (_snapIndex >= snapList.length - 1)?null :  () {
                snapIndex = _snapIndex + 1;
              }),
        IconButton(
            icon: Icon(Icons.edit),
              onPressed: () {
              Navigator.of(context).pushNamed('MetaEditor', arguments: currentSnap);
            }),
        IconButton(icon: Icon(Icons.rotate_90_degrees_ccw),onPressed: null,),
        IconButton(
            icon: Icon(Icons.crop),
            onPressed: () {
              cropMe(context, currentSnap);
            }),
        IconButton(icon: Icon(Icons.palette), onPressed: (_snapIndex==1)?(){} : null),
        PopupMenuButton<String>(
          onSelected: (String result) {
            if (result == 'exif') {
              showExif(context, currentSnap);
            }
          },
          itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
            PopupMenuItem<String>(
              value: 'exif',
              child: Text('exif Data'),
              enabled: (currentSnap.metadata != null),
            ),
          ],
        ),
      ], // of actions
    );
  } // of buildAppbar

  @override
  Widget build(BuildContext context) {
    if (snapList == null) _initParams(); // can't get params until we have a context!!!!
    currentSnap = snapList[_snapIndex];

    return Scaffold(
      appBar: buildAppBar(context),
      body: Center(
        child: PhotoViewerWithRect(key: pvKey, url: currentSnap.fullSizeURL),
      ),
    );
  } // of build

  void cropMe(BuildContext context, AopSnap snap) async {
    Log.message('cropme ${snap.fileName}');
  } // of cropMe

  void showExif(BuildContext context, AopSnap thisSnap) {
    Map<String, dynamic> tags = jsonDecode(thisSnap.metadata);
    String tagResult = '';
    tags.forEach((k, v) => tagResult += '$k = $v \n');
    showMessage(context, tagResult, title: 'Exif for ${thisSnap.fileName}');
  } // of showExif

}

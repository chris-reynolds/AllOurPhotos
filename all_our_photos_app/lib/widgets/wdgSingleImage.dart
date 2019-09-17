import 'package:flutter/material.dart';
import 'dart:convert';
import '../dart_common/Logger.dart' as Log;
import '../shared/aopClasses.dart';
import '../widgets/PhotoViewWithRect.dart';
import '../flutter_common/WidgetSupport.dart';

void showExif(BuildContext context, AopSnap thisSnap) {
  Map<String, dynamic> tags = jsonDecode(thisSnap.metadata);
  String tagResult = '';
  tags.forEach((k, v) => tagResult += '$k = $v \n');
  showMessage(context, tagResult, title: 'Exif for ${thisSnap.fileName}');
} // of showExif


void showPhoto(BuildContext context, List<AopSnap> snapList, int index) {
  final AopSnap snap = snapList[index];
  final bool hasMetadata = (snap.metadata != null && snap.metadata.length > 0);
  Navigator.push(context, new MaterialPageRoute<void>(builder: (BuildContext context) {
    return new Scaffold(
      appBar: new AppBar(
        title: new Text(snap.fileName + ' ' + snap.caption),
        actions: <Widget>[
          IconButton(icon: Icon(Icons.edit), onPressed: () {
            Navigator.of(context).pushNamed('MetaEditor',arguments:snap);
          }),
          IconButton(icon: Icon(Icons.rotate_90_degrees_ccw), onPressed: () {}),
          IconButton(
              icon: Icon(Icons.crop),
              onPressed: () {
                cropMe(context, snapList[index]);
              }),
          IconButton(icon: Icon(Icons.palette), onPressed: () {}),
          PopupMenuButton<String>(
            onSelected: (String result) {
              if (result == 'exif') {
                showExif(context, snap);
              }
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              PopupMenuItem<String>(
                value: 'exif',
                child: Text('exif Data'),
                enabled: hasMetadata,
              ),
              const PopupMenuItem<String>(
                value: 'smarter',
                child: Text('Being a lot smarter'),
              ),
              const PopupMenuItem<String>(
                value: 'selfStarter',
                child: Text('Being a self-starter'),
              ),
              const PopupMenuItem<String>(
                value: 'tradingCharter',
                child: Text('Placed in charge of trading charter'),
              ),
            ],
          ),
        ], // of actions
      ), // of appBar
      body: GestureDetector(
        child: MyView(snap),
        onPanUpdate: (details) {
          if (details.delta.dx > 0) {
            Log.message('right $details pos=${details.localPosition}');
          }
          if (details.delta.dx < 0) {
            Log.message('left $details pos=${details.localPosition}');
          }
        },
//        onScaleUpdate: (details){
//          Log.message('scaleUpdate $details');
//        },
      ),
    );
  }));
}

class MyView extends StatelessWidget {
  final AopSnap snap;
  final GlobalKey pvKey = GlobalKey();
  MyView(this.snap);

  @override
  Widget build(BuildContext context) {
    return PhotoViewerWithRect(key:pvKey, url:snap.fullSizeURL);
//    return SizedBox.expand(
//      child: Hero(
//        tag: snap.fileName,
//        child: new PhotoViewerWithRect(key:pvKey, url:snap.fullSizeURL),
//      ),
//    );
  }
}


void cropMe(BuildContext context, AopSnap snap) async {
  Log.message('cropme ${snap.fileName}');
} // of cropMe





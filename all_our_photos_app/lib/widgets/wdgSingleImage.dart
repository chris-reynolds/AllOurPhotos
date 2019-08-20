import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as Ui;
import 'dart:io';
import '../dart_common/Logger.dart' as Log;
import '../shared/aopClasses.dart';
import '../dart_common/WidgetSupport.dart';
import 'package:http/http.dart' as Http;
import 'package:path/path.dart' as Path;
import '../JpegLoader.dart';
import 'package:photo_view/photo_view.dart';
import 'package:image/image.dart' as Image2;
import '../appNavigator.dart';


void showExif(BuildContext context, AopSnap thisSnap) {
//  await showMessage(context,'Just me\n and me\nand me\n\nJust me\n and me\nand me\n\nJust me\n and me\nand me\n\nJust me\n and me\nand me\n\nJust me\n and me\nand me\n\n');
//  if (thisSnap.metadata == null || thisSnap.metadata.length == 0 ) {
//    showMessage(context, 'No Exif data', title: 'No Exif for ${thisSnap.fileName}');
//  } else {
  Map<String, dynamic> tags = jsonDecode(thisSnap.metadata);
  String tagResult = '';
  tags.forEach((k, v) => tagResult += '$k = $v \n');
  showMessage(context, tagResult, title: 'Exif for ${thisSnap.fileName}');
//  }
}


void showPhoto(BuildContext context, List<AopSnap> snapList, int index) {
  AopSnap snap = snapList[index];
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
//        onPanUpdate: (details) {
//          if (details.delta.dx > 0) {
//            Log.message('right $details pos=${details.localPosition}');
//          }
//          if (details.delta.dx < 0) {
//            Log.message('left $details pos=${details.localPosition}');
//          }
//        },
        onScaleUpdate: (details){
          Log.message('scaleUpdate $details');
        },
      ),
    );
  }));
}

class MyView extends StatelessWidget {
  AopSnap snap;

  MyView(this.snap);

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: Hero(
        tag: snap.fileName,
//        child: new ExSingleImage(url:snap.fullSizeURL),
        child: new SingleImageWidget(snap),
//        child: Image.network(snap.thumbnailURL),
//          child: Image2.Image()
      ),
    );
  }
}

PhotoView photoView; // todo fix global scope

Future<List<int>> getBytes(String url) async {
  final uri = Uri.parse(url);
  var httpClient = HttpClient();
  HttpClientRequest request;
  try {
    request = await httpClient.openUrl('GET',uri);
  } catch (ex) {
    Log.error(ex);
  }
  HttpClientResponse response = await request.close();
//  HttpResponse responseBody = await response.transform(utf8.decoder).join();
  //   print("Received $responseBody...");
  httpClient.close();
  List<List<int>> chunks = await response.toList();
  return chunks.expand((x) => x).toList();
}

void cropMe(BuildContext context, AopSnap snap) async {
//  PhotoView pv = photoView;
//  NetworkImage old = pv.imageProvider;
  List<int> oldBytes = await getBytes(snap.thumbnailURL);
  Image2.Image yy = Image2.decodeImage(oldBytes);
  Log.message('cropme ${snap.fileName}');
} // of cropMe

class SingleImageWidget extends StatefulWidget {
  const SingleImageWidget(this._snap);

  final AopSnap _snap;

  @override
  _SingleImageWidgetState createState() => new _SingleImageWidgetState();
}

class _SingleImageWidgetState extends State<SingleImageWidget> {
  PhotoViewControllerValue scaleValue;
  GlobalKey _globalKey = GlobalKey();
  PhotoViewController pvController;

  dynamic _tapdown(BuildContext context, TapDownDetails tdd, PhotoViewControllerValue pvcv) async {
    Log.message('tap down ${pvcv}');
    return null; // await _capturePng();
  }

//  Future<Uint8List> _capturePng() async {
//    try {
//      print('inside');
////      RenderRepaintBoundary boundary =
//      dynamic fred =_globalKey.currentContext.findRenderObject();
//      ui.Image image = await fred.toImage(pixelRatio: 3.0);
//      var bill = _currentBC.findRenderObject();
//      ByteData byteData =
//      await image.toByteData(format: ui.ImageByteFormat.png);
//      var pngBytes = byteData.buffer.asUint8List();
//      var bs64 = base64Encode(pngBytes);
//      print(pngBytes);
//      print(bs64);
//      setState(() {});
//      return pngBytes;
//    } catch (e) {
//      print(e);
//    }
//  }

  @override
  void initState() {
    super.initState();
    if (pvController ==null) {
      pvController = PhotoViewController()
        ..outputStateStream.listen(listener);
    }
    Log.message('singleImage initState ${widget._snap.fileName}');
  }

  @override
  void dispose() {
    pvController.dispose();
    super.dispose();
  }

  void listener(PhotoViewControllerValue value) {
    scaleValue = value;
    Log.message('listener ${scaleValue}');
    setState(() {});
  }

  BuildContext _currentBC;

  @override
  Widget build(BuildContext context) {
    _currentBC = context;
    photoView = PhotoView(
      key: Key('fullImage'),
      imageProvider: NetworkImage(widget._snap.fullSizeURL),
//      controller: pvController,
      enableRotation: false,
      onTapDown: _tapdown,
    );
    return ClipRect(child: photoView);
  }
}



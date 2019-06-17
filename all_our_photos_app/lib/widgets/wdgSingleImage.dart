import 'package:flutter/material.dart';
import '../dart_common/Logger.dart' as Log;
import '../shared/aopClasses.dart';
import '../dart_common/WidgetSupport.dart';
import 'package:http/http.dart' as Http;
import 'package:path/path.dart' as Path;
import '../JpegLoader.dart';
import 'package:photo_view/photo_view.dart';

void showExif(BuildContext context,AopSnap thisSnap) async {
//  await showMessage(context,'Just me\n and me\nand me\n\nJust me\n and me\nand me\n\nJust me\n and me\nand me\n\nJust me\n and me\nand me\n\nJust me\n and me\nand me\n\n');
  if (thisSnap.fileName.indexOf('helen') >= 0)
    Log.message('checkpoint available');
  String thisExtension = Path.extension(thisSnap.fileName).toLowerCase();
  if (thisExtension == '.jpg') {
//    try {
//      Image originalImage = decodeImage(fileImageContents);
//      thisSnap.width = originalImage.width;
//      thisSnap.height = originalImage.height;
//      //         bool isPortrait = (originalImage.height > originalImage.width);
//      //  thumbnailImage = copyResize(originalImage, isPortrait ? 480 : 640);
//    } catch (ex) {
//      Log.error('failed to decode ${thisImageFile.path}');
//      exit;
//    }
    Http.Response hr = await Http.get(thisSnap.fullSizeURL);
    List<int> fileImageContents = hr.bodyBytes;
    var jpegLoader = JpegLoader();
    await jpegLoader.loadBuffer(fileImageContents);
    if (jpegLoader.tags != null && jpegLoader.tags.length > 0) {
      String tagResult = '';
      jpegLoader.tags.forEach((k,v)=> tagResult+= '$k = $v \n');
      showMessage(context, tagResult,
          title: 'Exif for ${thisSnap.fileName}');
    }
  }

}
void showPhoto(BuildContext context, List<AopSnap> snapList, int index) {
  AopSnap snap = snapList[index];
  Navigator.push(context,
      new MaterialPageRoute<void>(builder: (BuildContext context) {
    return new Scaffold(
      appBar: new AppBar(
        title: new Text(snap.fileName + ' ' + snap.caption),
        actions: <Widget>[
          IconButton(icon: Icon(Icons.edit), onPressed: () {}),
          IconButton(icon: Icon(Icons.rotate_90_degrees_ccw), onPressed: () {}),
          IconButton(icon: Icon(Icons.crop), onPressed: () {}),
          IconButton(icon: Icon(Icons.palette), onPressed: () {}),
          PopupMenuButton<String>(
            onSelected: (String result) {
              if (result == 'exif') {
                showExif(context,snap);
              }
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                  const PopupMenuItem<String>(
                    value: 'exif',
                    child: Text('exif Data'),
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
      body: new SizedBox.expand(
        child: new Hero(
          tag: snap.fileName,
          child: new SingleImageWidget(snap),
        ),
      ),
    );
  }));
}

class SingleImageWidget extends StatefulWidget {
  const SingleImageWidget(this._snap);

  final AopSnap _snap;

  @override
  _SingleImageWidgetState createState() => new _SingleImageWidgetState();
}

class _SingleImageWidgetState extends State<SingleImageWidget> {
  @override
  Widget build(BuildContext context) {
    return new ClipRect(
//      child: new Image.network(
//        widget._snap.fullSizeURL,
//        fit: BoxFit.scaleDown,
//      ),
      child: PhotoView(
          imageProvider: NetworkImage(widget._snap.fullSizeURL),

      ),
    );
  }
}

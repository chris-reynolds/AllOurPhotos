import 'package:flutter/material.dart';
import 'package:all_our_photos_app/ImgFile.dart';
import 'package:all_our_photos_app/srvCatalogueLoader.dart';


void showPhoto(BuildContext context, ImgFile imgFile) {
  Navigator.push(context, new MaterialPageRoute<void>(
      builder: (BuildContext context) {
        return new Scaffold(
          appBar: new AppBar(
              title: new Text(imgFile.filename+' '+imgFile.caption)
          ),
          body: new SizedBox.expand(
            child: new Hero(
              tag: imgFile.fullFilename,
              child: new SingleImageWidget(imgFile),
            ),
          ),
        );
      }
  ));
}

class SingleImageWidget extends StatefulWidget {
  const SingleImageWidget(this._imgFile);
  final ImgFile _imgFile;

  @override
  _SingleImageWidgetState createState() => new _SingleImageWidgetState();
}

class _SingleImageWidgetState extends State<SingleImageWidget>  {

  @override
  Widget build(BuildContext context) {
    return new ClipRect(
      child: new Image.network(fullsizeURL(widget._imgFile),
        fit: BoxFit.scaleDown,
      ),
    );
  }
}

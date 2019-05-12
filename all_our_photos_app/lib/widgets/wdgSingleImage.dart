import 'package:flutter/material.dart';
import '../shared/aopClasses.dart';


void showPhoto(BuildContext context, AopSnap snap) {
  Navigator.push(context, new MaterialPageRoute<void>(
      builder: (BuildContext context) {
        return new Scaffold(
          appBar: new AppBar(
              title: new Text(snap.fileName+' '+snap.caption)
          ),
          body: new SizedBox.expand(
            child: new Hero(
              tag: snap.fileName,
              child: new SingleImageWidget(snap),
            ),
          ),
        );
      }
  ));
}

class SingleImageWidget extends StatefulWidget {
  const SingleImageWidget(this._snap);
  final AopSnap _snap;

  @override
  _SingleImageWidgetState createState() => new _SingleImageWidgetState();
}

class _SingleImageWidgetState extends State<SingleImageWidget>  {

  @override
  Widget build(BuildContext context) {
    return new ClipRect(
      child: new Image.network(widget._snap.fullSizeURL,
        fit: BoxFit.scaleDown,
      ),
    );
  }
}

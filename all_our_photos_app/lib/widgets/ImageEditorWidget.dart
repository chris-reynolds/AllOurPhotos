/*
  Created by Chris on 18th Oct 2018
  
  Purpose: Stateful ImageEditorWidget widget
*/


import 'package:flutter/material.dart';

class ImageEditorWidget extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return new ImageEditorWidgetState();
  }
}

class ImageEditorWidgetState extends State<ImageEditorWidget> {
  @override
  Widget build(BuildContext context) {
    return new Center(
      child: new Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
//          new ImageFilterWidget(widget._imageFilter),
          new Text(
            'Image editor Panel',
            style: Theme.of(context).textTheme.display1,
          ),
        ],
      ),
    );
  }
}
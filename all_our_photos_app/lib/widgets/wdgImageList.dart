/*
  Created by Chris on 20th Oct 2018
  
  Purpose: Stateful ImageList widget
*/


import 'package:flutter/material.dart';
import 'package:all_our_photos_app/ImageFilter.dart';
import 'package:all_our_photos_app/widgets/wdgImageFilter.dart';

class ImageListWidget extends StatefulWidget {
  ImageFilter _imageFilter;

  ImageListWidget(this._imageFilter);

  @override
  State<StatefulWidget> createState() {
    return new ImageListWidgetState();
  }
}

class ImageListWidgetState extends State<ImageListWidget> {
  @override
  Widget build(BuildContext context) {
    return new Center(
      child: new Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
//          new ImageFilterWidget(widget._imageFilter),
          new Text(
            'Image list blah',
            style: Theme.of(context).textTheme.display1,
          ),
        ],
      ),
    );
  }
}
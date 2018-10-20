/*
  Created by Chris on 18th Oct 2018
  
  Purpose: Stateful ImageFilter widget
*/


import 'package:flutter/material.dart';
import 'package:all_our_photos_app/ImageFilter.dart';

class ImageFilterWidget extends StatefulWidget {
  ImageFilter _imageFilter;

  ImageFilterWidget(this._imageFilter);

  @override
  State<StatefulWidget> createState() {
    return new ImageFilterWidgetState();
  }
}

class ImageFilterWidgetState extends State<ImageFilterWidget> {
  @override
  Widget build(BuildContext context) {
    return new Center(
      child: new Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          new Text(
            'Image Filter ${widget._imageFilter.fromDate}',
            style: Theme.of(context).textTheme.display1,
          ),
        ],
      ),
    );
  }
}
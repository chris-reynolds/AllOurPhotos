/*
  Created by Chris on 18th Oct 2018
  
  Purpose: Stateful ImageFilter widget
*/


import 'package:flutter/material.dart';
import 'package:all_our_photos_app/ImageFilter.dart';
import 'package:all_our_photos_app/widgets/wdgTapDate.dart';
import 'package:all_our_photos_app/utils.dart' as Utils;

class ImageFilterWidget extends StatefulWidget {
  ImageFilter _imageFilter;
  bool changeMode = false;
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
      child: !widget.changeMode ?
      FlatButton(
        child: Text(
          'Image Filter ${Utils.formatDate(widget._imageFilter.fromDate,format:'d-mmm-yyyy')}'+
              ' upto ${Utils.formatDate(widget._imageFilter.toDate,format:'d-mmm-yyyy')}',
          style: Theme.of(context).textTheme.display1,
        ),
        onPressed: () {setState(() {
          widget.changeMode = true;
        }); // of setState
        }, // of onPressed
      )
      : new Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('From ',style: Theme.of(context).textTheme.body2),
              TapDateWidget(widget._imageFilter.fromDate,(changedDate) {
                setState( (){widget._imageFilter.fromDate = changedDate;});
              }), // of TapDateWidget
              Text('To ',style: Theme.of(context).textTheme.body2),
              TapDateWidget(widget._imageFilter.toDate,(changedDate) {
                setState( (){widget._imageFilter.toDate = changedDate;});
              }), // of TapDateWidget

            ]), // Date filter
          Row(
//            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextField(  <-----------------------------
//                    decoration: InputDecoration(
//                        labelText: 'Enter your username'
//                    ),
              )
            ]
          )
        ],
      )
    );
  }
}
/*
  Created by Chris on 18th Oct 2018
  
  Purpose: Stateful ImageFilter widget
*/


import 'package:flutter/material.dart';
import 'package:all_our_photos_app/ImageFilter.dart';
import 'package:all_our_photos_app/widgets/wdgTapDate.dart';
import 'package:all_our_photos_app/utils.dart' as Utils;

const  filterColors = <Color>[null,Colors.red,Colors.amber,Colors.green];

IconData _rankIcon(bool selected) => selected ? Icons.star : Icons.star_border;

class ImageFilterWidget extends StatefulWidget {
  ImageFilter _imageFilter;

  ImageFilterWidget(this._imageFilter);

  @override
  State<StatefulWidget> createState() {
    return new ImageFilterWidgetState();
  }
}


class ImageFilterWidgetState extends State<ImageFilterWidget> {

  bool _changeMode = false;
  bool get changeMode => _changeMode;
  void set changeMode(bool value) {
    _changeMode = value;
  }

  Widget Text2(String s) {
    return Text(s,style:Theme.of(context).textTheme.body2);
  } // of Text2

  void toggleRank(int rankNo) {
    setState(() {
      widget._imageFilter.rank[rankNo] = !widget._imageFilter.rank[rankNo];
    });
  } // of toggleRank

  onSearchTextChanged(String value) {
    widget._imageFilter.searchText = value;
  } // of onSearchTextChanged

  //  @override
  Widget build(BuildContext context) {
    print('building ImageFilter with ${changeMode} and ${widget._imageFilter.refreshRequired}');
    return new Center(
      child: !changeMode ?
      FlatButton(
        child: Text(
          'Image Filter ${Utils.formatDate(widget._imageFilter.fromDate,format:'d-mmm-yyyy')}'+
              ' upto ${Utils.formatDate(widget._imageFilter.toDate,format:'d-mmm-yyyy')}',
          style: Theme.of(context).textTheme.display1,
        ),
        onPressed: () {setState(() {
          if (changeMode == false)
            changeMode = true;
        }); // of setState
        }, // of onPressed
      )
      : new Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Row(
//            mainAxisAlignment: MainAxisAlignment.
            children: [
              Text2('From '),
              TapDateWidget(widget._imageFilter.fromDate,(changedDate) {
                setState( (){widget._imageFilter.fromDate = changedDate;});
              }), // of TapDateWidget
              Text2('To '),
              TapDateWidget(widget._imageFilter.toDate,(changedDate) {
                setState( (){widget._imageFilter.toDate = changedDate;});
              }), // of TapDateWidget
              widget._imageFilter.refreshRequired ? Expanded(

                child: Row(
                  mainAxisAlignment : MainAxisAlignment.end,
                  children: [Icon(Icons.refresh,size:40.0)],
                ),
              ) : Container(),
            ]), // Date filter
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [

              Text2('Search:'),
              Flexible(
                child:  TextField(
                  onChanged: onSearchTextChanged,
                  decoration: InputDecoration(
 //                     border: InputBorder.none,
                      hintText: 'Please enter a search term'
                  ),
                )
              ),
              Text2('Rank:'),
              IconButton(icon: Icon(_rankIcon(widget._imageFilter.rank[1]),color:filterColors[1],size:40.0),
                  onPressed: () {toggleRank(1);}),
              IconButton(icon: Icon(_rankIcon(widget._imageFilter.rank[2]),color:filterColors[2],size:40.0),
                  onPressed: () {toggleRank(2);}),
              IconButton(icon: Icon(_rankIcon(widget._imageFilter.rank[3]),color:filterColors[3],size:40.0),
                  onPressed: () {toggleRank(3);}),
            ]
          )
        ],
      )
    );
  }
}
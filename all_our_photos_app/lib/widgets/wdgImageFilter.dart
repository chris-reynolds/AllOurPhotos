/*
  Created by Chris on 18th Oct 2018
  
  Purpose: Stateful ImageFilter widget
*/


import 'package:flutter/material.dart';
import 'package:all_our_photos_app/ImageFilter.dart';
import 'package:all_our_photos_app/widgets/wdgTapDate.dart';
import 'package:all_our_photos_app/utils.dart' as Utils;

const  filterColors = <Color>[null,Colors.red,Colors.orange,Colors.green];

IconData _rankIcon(bool selected) => selected ? Icons.star : Icons.star_border;

class ImageFilterWidget extends StatefulWidget {
  final ImageFilter _initImageFilter;
  final VoidCallback _onRefresh;

  ImageFilterWidget(this._initImageFilter,this._onRefresh);

  @override
  State<StatefulWidget> createState() {
    return new ImageFilterWidgetState();
  }
}


class ImageFilterWidgetState extends State<ImageFilterWidget> {

  ImageFilter _imageFilter;
  bool _changeMode = false;
  bool get changeMode => _changeMode;
  set changeMode(bool value) {
    _changeMode = value;
  }


  @override
  void initState() {
    super.initState();
    _imageFilter = widget._initImageFilter;
  } // initState

  Widget Text2(String s) {
    return Text(s,style:Theme.of(context).textTheme.body2);
  } // of Text2

  void toggleRank(int rankNo) {
    setState(() {
      _imageFilter.setRank(rankNo,!_imageFilter.getRank(rankNo));
    });
  } // of toggleRank

  void onRefresh() {
    setState(() {
      changeMode = false;
      _imageFilter.checkImages();
    });
  } // onRefresh

  void onSearchTextChanged(String value) {
    setState(() {
      _imageFilter.searchText = value;
    });
  } // of onSearchTextChanged

  //  @override
  Widget build(BuildContext context) {
    print('building ImageFilter with changeMode=$changeMode and refreshRequired=${_imageFilter.refreshRequired}');
    return new Center(
      child: !changeMode ?
      FlatButton(
        child: Text(
          '${_imageFilter.searchText} ${Utils.formatDate(_imageFilter.fromDate,format:'d-mmm-yyyy')}'+
              ' upto ${Utils.formatDate(_imageFilter.toDate,format:'d-mmm-yyyy')}',
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
            mainAxisAlignment: MainAxisAlignment.center,
            children: [

              Text2('Search:'),
              Flexible(
                child:  TextField(
                  onChanged: onSearchTextChanged,
                  style:Theme.of(context).textTheme.body2,
                  decoration: InputDecoration(
 //                     border: InputBorder.none,
                      hintText: 'Please enter a search term'
                  ),
                )
              ),
              Text2('Rank:'),
              IconButton(icon: Icon(_rankIcon(_imageFilter.getRank(1)),color:filterColors[1],size:40.0),
                  onPressed: () {toggleRank(1);}),
              IconButton(icon: Icon(_rankIcon(_imageFilter.getRank(2)),color:filterColors[2],size:40.0),
                  onPressed: () {toggleRank(2);}),
              IconButton(icon: Icon(_rankIcon(_imageFilter.getRank(3)),color:filterColors[3],size:40.0),
                  onPressed: () {toggleRank(3);}),
            ]
          ),
          Row(
//            mainAxisAlignment: MainAxisAlignment.
              children: [
                Text2('From '),
                TapDateWidget(_imageFilter.fromDate,(changedDate) {
                  setState( (){_imageFilter.fromDate = changedDate;});
                }), // of TapDateWidget
                Text2('To '),
                TapDateWidget(_imageFilter.toDate,(changedDate) {
                  setState( (){_imageFilter.toDate = changedDate;});
                }), // of TapDateWidget
                Expanded(
                  child: Row(
                    mainAxisAlignment : MainAxisAlignment.end,
                    children: [
                      IconButton(icon:Icon(Icons.refresh,size:40.0),onPressed:onRefresh),
                    ],
                  ),
                )
              ]), // Date filter
        ],
      )
    );
  }
}
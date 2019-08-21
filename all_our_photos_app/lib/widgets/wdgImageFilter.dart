/*
  Created by Chris on 18th Oct 2018
  
  Purpose: Stateful ImageFilter widget
*/

import 'package:flutter/material.dart';
import '../ImageFilter.dart';
import 'wdgTapDate.dart';
import '../dart_common/DateUtil.dart' as Utils;

const filterColors = <Color>[null, Colors.red, Colors.orange, Colors.green];

IconData _rankIcon(bool selected) => selected ? Icons.star : Icons.star_border;

class ImageFilterWidget extends StatefulWidget {
  final ImageFilter _initImageFilter;
  final VoidCallback onRefresh;

  ImageFilterWidget(this._initImageFilter, {this.onRefresh});

  @override
  State<StatefulWidget> createState() {
    return new ImageFilterWidgetState();
  }
}

class ImageFilterWidgetState extends State<ImageFilterWidget> {
  ImageFilter _imageFilter;
  TextEditingController textController = TextEditingController();
  bool _changeMode = false;

  bool get changeMode => _changeMode;

  set changeMode(bool value) {
    // try and fool the compiler
    print('change to $value');
    _changeMode = value;
  }

  @override
  void initState() {
    super.initState();
    _imageFilter = widget._initImageFilter;
  } // initState

  Widget qText(String s) {
    return Text(s, style: Theme.of(context).textTheme.body2);
  } // of Text2

  void toggleRank(int rankNo) {
    setState(() {
      _imageFilter.setRank(rankNo, !_imageFilter.getRank(rankNo));
    });
  } // of toggleRank

  void onRefresh() {
    _imageFilter.searchText = textController.value.text;
    _imageFilter.checkImages().then((dummy) {
      setState(() {
        changeMode = false;
      });
    });
    //just added this cos of Dart analysis. Not sure if it used.
//    if (widget.onRefresh != null) widget.onRefresh();
  } // onRefresh

  void onSearchTextChanged(String value) {
    setState(() {
//      _imageFilter.searchText = value;
    });
  } // of onSearchTextChanged

  //  @override
  Widget build(BuildContext context) {
//    print('building ImageFilter with changeMode=$changeMode and refreshRequired=${_imageFilter.refreshRequired}');
    return new Center(
        child: !changeMode
            ? FlatButton(
                child: Text(
                  '${_imageFilter.searchText} ${Utils.formatDate(_imageFilter.fromDate, format: 'd-mmm-yyyy')}' +
                      ' upto ${Utils.formatDate(_imageFilter.toDate, format: 'd-mmm-yyyy')}',
                //  style: Theme.of(context).textTheme.display1,
                ),
                onPressed: () {
                  setState(() {
                    if (changeMode == false) changeMode = true;
                  }); // of setState
                }, // of onPressed
              )
            : new Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    qText('Search:'),
                    Flexible(
                        child: TextField(
                      controller: textController,
//                  onChanged: onSearchTextChanged,
                      style: Theme.of(context).textTheme.body2,
                    )),
                    qText('Rank:'),
                    IconButton(
                        icon: Icon(_rankIcon(_imageFilter.getRank(1)),
                            color: filterColors[1], size: 40.0),
                        onPressed: () {
                          toggleRank(1);
                        }),
                    IconButton(
                        icon: Icon(_rankIcon(_imageFilter.getRank(2)),
                            color: filterColors[2], size: 40.0),
                        onPressed: () {
                          toggleRank(2);
                        }),
                    IconButton(
                        icon: Icon(_rankIcon(_imageFilter.getRank(3)),
                            color: filterColors[3], size: 40.0),
                        onPressed: () {
                          toggleRank(3);
                        }),
                  ]),
                  Row(
//            mainAxisAlignment: MainAxisAlignment.
                      children: [
                        qText('From '),
                        TapDateWidget(_imageFilter.fromDate, (changedDate) {
                          setState(() {
                            _imageFilter.fromDate = changedDate;
                          });
                        }), // of TapDateWidget
                        qText('upto '),
                        TapDateWidget(_imageFilter.toDate, (changedDate) {
                          setState(() {
                            _imageFilter.toDate = changedDate;
                          });
                        }), // of TapDateWidget
                        Expanded(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              IconButton(
                                  icon: Icon(Icons.refresh, size: 40.0),
                                  onPressed: onRefresh),
                            ],
                          ),
                        )
                      ]), // Date filter
                ],
              ));
  }
}

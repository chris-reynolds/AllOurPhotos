/*
  Created by Chris on 18th Oct 2018
  
  Purpose: Stateful ImageFilter widget
*/

import 'package:flutter/material.dart';
import 'package:aopcommon/aopcommon.dart';
import '../ImageFilter.dart';
import 'wdgTapDate.dart';

// blue gray not actually used. just holding the zero position
const filterColors = <Color>[
  Colors.blueGrey,
  Colors.red,
  Colors.orange,
  Colors.green,
  Colors.pink
];

IconData _rankIcon(bool selected) => selected ? Icons.star : Icons.star_border;

class ImageFilterWidget extends StatefulWidget {
  final ImageFilter _initImageFilter;
  final VoidCallback onRefresh;

  const ImageFilterWidget(this._initImageFilter,
      {required this.onRefresh, super.key});

  @override
  State<StatefulWidget> createState() {
    return ImageFilterWidgetState();
  }
}

class ImageFilterWidgetState extends State<ImageFilterWidget> {
  late ImageFilter _imageFilter;
  TextEditingController textController = TextEditingController();
  bool _changeMode = false;

  bool get changeMode => _changeMode;

  set changeMode(bool value) {
    // try and fool the compiler
    log.message('change to $value');
    _changeMode = value;
  }

  @override
  void initState() {
    super.initState();
    _imageFilter = widget._initImageFilter;
  } // initState

  Widget qText(String s) {
    return Text(s, style: Theme.of(context).textTheme.bodyMedium);
  } // of Text2

  void toggleRank(int rankNo) {
    setState(() {
      _imageFilter.setRank(rankNo, !_imageFilter.getRank(rankNo));
    });
  } // of toggleRank

  void onMonthMove(int increment) async {
    _imageFilter.moveMonth(increment);
    await _imageFilter.checkImages();
    setState(() {});
  } // on MonthMove

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
  @override
  Widget build(BuildContext context) {
//    print('building ImageFilter with changeMode=$changeMode and refreshRequired=${_imageFilter.refreshRequired}');
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () {
        setState(() {
          if (changeMode == false) changeMode = true;
        }); // of setState
      },
      child: Center(
          child: !changeMode
              ? Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.first_page),
                      onPressed: () {
                        onMonthMove(-1);
                      },
                      tooltip: 'Back 1 month',
                      iconSize: 36,
                    ),
                    Text(
                      '${_imageFilter.searchText} ${formatDate(_imageFilter.fromDate, format: 'd-mmm-yyyy')}'
                      ' upto ${formatDate(_imageFilter.toDate, format: 'd-mmm-yyyy')}',
                    ),
                    IconButton(
                      icon: Icon(Icons.last_page),
                      onPressed: () {
                        onMonthMove(1);
                      },
                      tooltip: 'Advance 1 month',
                      iconSize: 36,
                    ),
                    Expanded(child: Text('')),
                    IconButton(
                      icon: Icon(Icons.search),
                      onPressed: () {
                        setState(() {
                          if (changeMode == false) changeMode = true;
                        }); // of setState
                      }, // of onPressed
                      tooltip: 'change search criteria',
                    ),
                  ],
                )
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      qText('Search:'),
                      Flexible(
                          child: TextField(
                        controller: textController,
//                  onChanged: onSearchTextChanged,
                        style: Theme.of(context).textTheme.bodyMedium,
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
                )),
    );
  }
}

/*
  Created by chrisreynolds on 2019-05-27
  
  Purpose: The purpose of this screen is allow the user to add photos to an album

*/

import 'package:flutter/material.dart';
import '../shared/aopClasses.dart';
import '../widgets/wdgMonthSelector.dart';

//import '../widgets/wdgSelectionBar.dart';
import '../ImageFilter.dart';
import '../dart_common/DateUtil.dart';
import '../dart_common/ListUtils.dart';
import '../dart_common/Logger.dart' as Log;
import '../widgets/wdgSnapGrid.dart';

class AlbumAddPhoto extends StatefulWidget {
  @override
  _AlbumAddPhotoState createState() => _AlbumAddPhotoState();
}

class _AlbumAddPhotoState extends State<AlbumAddPhoto> with Selection<int> {
  AopAlbum album;
  ImageFilter imgFilter;
  int yearNo = DateTime.now().year;
  List<AopSnap> _list;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: buildBar(context),
      body: SsSnapGrid(_list, this,album),
    );
  } // of build

  Widget buildBar(BuildContext context) {
    if (selectionList.isEmpty)
      return AppBar(
        actions: <Widget>[
          MonthSelector(
            onPressed: setQuarter,
          ),
          IconButton(
              icon: Icon(Icons.timelapse), onPressed: extendEndDate,tooltip: 'Extend a month',),
          IconButton(
              icon: Icon(
                imgFilter.getRank(2) ? Icons.star : Icons.star_border,
                color: Colors.orange,
              ),
              tooltip: imgFilter.getRank(2)?'Hide amber photos':'Show amber photos',
              onPressed: () {
                imgFilter.setRank(2, !imgFilter.getRank(2)); // toggle.
                refreshList();
              }),
        ],
      );
    else
      return AppBar(
        title: Text('${selectionList.length} items selected'),
        actions: <Widget>[
          IconButton(
              icon: Icon(Icons.check),
              tooltip: 'Add selection to album',
              onPressed: () {
                saveSelectedToAlbum(context);
              }),
          IconButton(
              icon: Icon(Icons.undo),
              tooltip: 'Clear selection',
              onPressed: () {
                clearSelected();
                setState(() {});
              }),
        ],
      ); // of row
  } // of buildBar

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (album == null) {
      album = ModalRoute.of(context).settings.arguments;
      yearNo = int.tryParse(album.name.substring(0, 4));
      yearNo ??= DateTime.now().year;
      DateTime startDate = DateTime(yearNo, 1, 1);
      imgFilter = ImageFilter.yearMonth(yearNo, 1, refresh: refreshList);
      imgFilter.toDate = addMonths(startDate, 3).add(Duration(seconds:-1));
      Log.message('Album assigned');
      imgFilter.setRank(2, false);
      refreshList();
    }
  } // of didChangeDependencies

  void extendEndDate() {
    imgFilter.toDate = addMonths(imgFilter.toDate, 1);
    refreshList();
  } // extendEndDate

  @override
  void initState() {
    super.initState();
    Log.message('I was here without a list = ${_list == null}');
  }

  Future<void> refreshList() async {
    await imgFilter.checkImages();
    setState(() {
      _list = imgFilter.items;
    });
  } // refreshList

  void saveSelectedToAlbum(BuildContext context) {
    Navigator.pop(context, selectionList);
  } // of saveSelectedToAlbum

  void setQuarter(int quarter) {
    imgFilter.fromDate = DateTime(yearNo, 3 * quarter + 1, 1);
    imgFilter.toDate = addMonths(imgFilter.fromDate, 3).add(Duration(seconds:-1));
    refreshList();
  } // of setQuarter

  Widget snapCell(AopSnap snap) {
    return InkWell(
      child: Text(
          '${formatDate(snap.takenDate, format: 'dd-mmm-yy hh:nn:ss')} ' '   ${snap.fullSizeURL}      ',
          style: TextStyle(
              color: isSelected(snap.id) ? Colors.red : Colors.blueAccent)),
      onTap: () {
        toggleSelected(snap.id);
        setState(() {});
      },
    );
  } // of snapCell

} // of AlbumAddPhotoState

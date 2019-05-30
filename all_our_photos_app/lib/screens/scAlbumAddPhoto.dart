/*
  Created by chrisreynolds on 2019-05-27
  
  Purpose: The purpose of this screen is allow the user to add photos to an album

*/

import 'package:flutter/material.dart';
import '../shared/aopClasses.dart';
import '../widgets/wdgMonthSelector.dart';
import '../ImageFilter.dart';
import '../dart_common/DateUtil.dart';
import '../dart_common/ListUtils.dart';
import '../dart_common/Logger.dart' as Log;

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
      body: new ListView(
        padding: new EdgeInsets.symmetric(vertical: 8.0),
        children: <Widget>[
          if (_list != null)
            for (AopSnap snap in _list)
              Text('${formatDate(snap.takenDate,format:'dd-mmm-yy hh:nn:ss')}    ${snap.fullSizeURL}      '),
        ],
      ),
    );
  } // of build

  Widget buildBar(BuildContext context) {
    return AppBar(
      actions: <Widget>[
        MonthSelector(onPressed: setQuarter,),
      ],
    );
  } // of buildBar

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    album = ModalRoute.of(context).settings.arguments;
    yearNo = int.tryParse(album.name.substring(0, 4));
    if (yearNo == null) yearNo = DateTime.now().year;
    DateTime startDate = DateTime(yearNo, 1, 1);
    DateTime endDate = addMonths(startDate, 3);
    imgFilter = ImageFilter.yearMonth(yearNo,1,refresh: refreshList);
    Log.message('Album assigned');
 //   imgFilter.setRank(2, false);
    refreshList();
  } // of didChangeDependencies

  void extendEndDate() {
    imgFilter.toDate = addMonths(imgFilter.toDate, 1);
    refreshList();
  } // extendEndDate
  @override
  void initState() {
    super.initState();
    Log.message('I was here without a list = ${_list==null}');
  }

  Future<void> refreshList() async {
    await imgFilter.checkImages();
    setState(() {
      _list = imgFilter.images;
    });
  } // refreshList

  void setQuarter(int quarter) {
    imgFilter.fromDate = DateTime(yearNo, 3 * quarter + 1, 1);
    imgFilter.toDate = addMonths(imgFilter.fromDate, 3);
    refreshList();
  } // of setQuarter

} // of AlbumAddPhotoState

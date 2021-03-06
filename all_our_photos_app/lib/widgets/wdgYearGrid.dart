//import 'package:flutter/cupertino.dart';
//import 'dart:convert';
import 'package:flutter/material.dart';

//import 'package:all_our_photos_app/ImgFile.dart';
import '../ImageFilter.dart';
import '../widgets/wdgPhotoGrid.dart';
import '../dart_common/Logger.dart' as log;
import '../shared/aopClasses.dart';

// Note there is a blank month name in entry 0 for the year column
final List<String> monthNames =
    'Year/Jan/Feb/Mar/Apr/May/Jun/Jul/Aug/Sep/Oct/Nov/Dec'.split('/');

class YearEntry {
  final int yearno;

  // zeroth item not used - just makes coding cleaner
  List<int> months = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0];

  YearEntry(this.yearno);
} // of yearEntry

class YearGrid extends StatefulWidget {
  @override
  _YearGridState createState() => _YearGridState();
}

class _YearGridState extends State<YearGrid> {
  final Map<String, TextStyle> gridStyles = {
    'monthNames': TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold),
    'yearNos': TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold),
    'monthCell': TextStyle(),
  };
  List<YearEntry> yearList = [];
  BuildContext currentContext;

  int _currentYear = 0;
  int _currentMonth = 0;
  void setCurrent(int year,int month) {_currentYear=year; _currentMonth = month;}
  bool isCurrent(int year,int month) => (_currentYear==year && _currentMonth == month);

  @override
  initState() {
    super.initState();
    buildYears().then((newYearList) {
      setState(() => yearList = newYearList);
    }); // of then
  } // of initState

  Future<List<YearEntry>> buildYears() async {
    List<YearEntry> result = [];
    for (var row in await AopSnap.monthGrid) {
      YearEntry newYear = YearEntry(row[0]);
      for (int monthIx = 1; monthIx <= 12; monthIx++)
        newYear.months[monthIx] = (row[monthIx]).round();
      result.add(newYear);
    }
    result.sort((YearEntry y1, YearEntry y2) => (y2.yearno - y1.yearno));
    if (result.length > 0)
      log.message('${result.length} years loaded ${result[0].yearno}');
    return result;
  } // of buildYears

  void handleMonthClick(int yearNo, int monthNo) {
    if (monthNo > 0) { // dont navigate if clicking on yearNo
      setCurrent(yearNo, monthNo);
      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) =>
                  PhotoGrid(ImageFilter.yearMonth(yearNo, monthNo),album: null))).then((value)
                  {setState(() {});}
                  );
    }
  } // handleMonthClick

  Row yearRowBuilder(YearEntry thisYear) {
    IconData isCurrentIcon(bool current)=> current ? Icons.ac_unit : Icons.image;
    return Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
      Text('${thisYear.yearno}', style: gridStyles['yearNos']),
      for (int monthIx = 1; monthIx <= 12; monthIx++)
        if (thisYear.months[monthIx] > 0)
          IconButton(
            icon: Icon(isCurrentIcon(isCurrent(thisYear.yearno,monthIx)), size: 36.0,
                color: isCurrent(thisYear.yearno,monthIx) ? Colors.red : Colors.amber),
            // tooltip: 'Todo: Maybe location info',
            onPressed: () {
              handleMonthClick(thisYear.yearno, monthIx);
            },
          )
        else
          IconButton(
            icon: Icon(Icons.radio_button_unchecked, size: 12.0),
            onPressed: () {},
          ),
    ]);
  } // of yearRowBuilder

  @override
  Widget build(BuildContext context) {
    List<Widget> monthNamesHeader = [
      new InkWell(
        child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: monthNames
                .map((monthName) => Text(
                      monthName,
                      style: gridStyles['monthNames'],
                    ))
                .toList()),
        onTap: () {
          print('resetting yearlist');
          yearList = [];
        },
      )
    ];
    return new ListView(
      children: [
        ...monthNamesHeader,
        for (var thisYear in yearList) yearRowBuilder(thisYear)
      ],
    ); // of ListView
  }
}


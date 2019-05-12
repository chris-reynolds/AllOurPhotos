//import 'package:flutter/cupertino.dart';
//import 'dart:convert';
import 'package:flutter/material.dart';

//import 'package:all_our_photos_app/ImgFile.dart';
import '../ImageFilter.dart';
import '../widgets/wdgPhotoGrid.dart';
import '../dart_common/Logger.dart' as log;
import '../shared/aopClasses.dart';

// Note there is a blank month name in entry 0 for the year column
final List<
    String> monthNames = 'Year/Jan/Feb/Mar/Apr/May/Jun/Jul/Aug/Sep/Oct/Nov/Dec'
    .split('/');

class YearEntry {
  final int yearno;

  // zeroth item not used - just makes coding cleaner
  List<int> month = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0];

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

  @override
  initState()  {
    super.initState();
    buildYears().then((newYearList) {
      setState(()=> yearList = newYearList);
    }); // of then
  } // of initState

  Future<List<YearEntry>> buildYears() async {
    List<YearEntry> result = [];
    for (var row in await AopSnap.monthGrid) {
      YearEntry newYear = YearEntry(row[0]);
      for (int monthIx = 1; monthIx <= 12; monthIx++)
        newYear.month[monthIx] = (row[monthIx]).round();
      result.add(newYear);
    }
    result.sort((YearEntry y1, YearEntry y2) => (y2.yearno - y1.yearno));
    if (result.length > 0)
      log.message('${result.length} years loaded ${result[0].yearno}');
    return result;
  } // of buildYears

  void handleMonthClick(int yearNo, int monthNo) {
    if (monthNo > 0) // dont navigate if clicking on yearNo
      Navigator.push(context, MaterialPageRoute(
          builder: (context) =>
              PhotoGrid(ImageFilter.yearMonth(yearNo, monthNo))));
  } // handleMonthClick

  Row yearRowBuilder(YearEntry thisYear) {
    return Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Text('${thisYear.yearno}', style: gridStyles['yearNos']),
          for (int monthIx = 1; monthIx <= 12; monthIx++)
            IconButton(
              icon: Icon(Icons.image, size: 36.0),
              tooltip: 'Todo: Maybe location info',
              onPressed: () {
                handleMonthClick(thisYear.yearno, monthIx);
              },
            )
        ]
    );
  } // of yearRowBuilder
  @override
  Widget build(BuildContext context) {
    List<Widget> monthNamesHeader = [
      new InkWell(
        child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: monthNames.map((monthName) =>
                Text(monthName, style: gridStyles['monthNames'],)).toList()
        ),
        onTap: () {
          print('resetting yearlist');
          yearList = [];
        },
      )

    ];
    return new ListView(
      children: [
        ... monthNamesHeader,
        for (var thisYear in yearList)
          yearRowBuilder(thisYear)
      ],
    ); // of ListView
  }
}


/*
create view vwmonthgrid as
select year(`taken_date`),
	sum(if(month(taken_date)=1,1,0)) as Jan,
	sum(if(month(taken_date)=2,1,0)) as Feb,
	sum(if(month(taken_date)=3,1,0)) as Mar,
	sum(if(month(taken_date)=4,1,0)) as Apr,
	sum(if(month(taken_date)=5,1,0)) as May,
	sum(if(month(taken_date)=6,1,0)) as Jun,
	sum(if(month(taken_date)=7,1,0)) as Jul,
	sum(if(month(taken_date)=8,1,0)) as Aug,
	sum(if(month(taken_date)=9,1,0)) as Sep,
	sum(if(month(taken_date)=10,1,0)) as Oct,
	sum(if(month(taken_date)=11,1,0)) as Nov,
	sum(if(month(taken_date)=12,1,0)) as `Dec`,
	count(*) as Total from aopsnaps
group by 1
 */
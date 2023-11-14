import 'package:flutter/material.dart';
import 'package:aopcommon/aopcommon.dart';
import '../ImageFilter.dart';
import '../widgets/wdgPhotoGrid.dart';
import 'package:aopmodel/aop_classes.dart';
import '../MonthlyStatus.dart';
import '../flutter_common/WidgetSupport.dart';

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
  const YearGrid({Key? key}) : super(key: key);

  @override
  YearGridState createState() => YearGridState();
}

class YearGridState extends State<YearGrid> {
  late Future<List<YearEntry>> yearList = buildYears();
  late Future<int> monthlyStatusIndic = MonthlyStatus.init();
  double gridFontSize = 20.0;
  double gridIconSize = 20.0;
  int _currentYear = 0;
  int _currentMonth = 0;
  void setCurrent(int year, int month) {
    _currentYear = year;
    _currentMonth = month;
  }

  bool isCurrent(int year, int month) =>
      (_currentYear == year && _currentMonth == month);

  Future<List<YearEntry>> buildYears() async {
    List<YearEntry> result = [];
    try {
      for (var row in (await AopSnap.monthGrid) as Iterable<dynamic>) {
        YearEntry newYear = YearEntry(row[0]);
        for (int monthIx = 1; monthIx <= 12; monthIx++)
          newYear.months[monthIx] = (row[monthIx]).round();
        result.add(newYear);
      }
      result.sort((YearEntry y1, YearEntry y2) => (y2.yearno - y1.yearno));
      if (result.isNotEmpty)
        log.message('${result.length} years loaded ${result[0].yearno}');
      return result;
    } catch (ex) {
      log.error('failed to build years: $ex');
      rethrow;
    }
  } // of buildYears

  void handleMonthClick(int yearNo, int monthNo) {
    if (monthNo > 0) {
      // dont navigate if clicking on yearNo
      setCurrent(yearNo, monthNo);
      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => PhotoGrid(
                  ImageFilter.yearMonth(yearNo, monthNo, refresh: () {}),
                  album: null))).then((value) {
        setState(() {});
      });
    }
  } // handleMonthClick

  Color monthProgressColor(int yearNo, int monthNo) {
    return MonthlyStatus.read(yearNo, monthNo)
        ? Colors.blue
        : Colors.amber; // todo
  }

  Row yearRowBuilder(YearEntry thisYear) {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
      Text('${thisYear.yearno}',
          style:
              TextStyle(fontSize: gridFontSize, fontWeight: FontWeight.bold)),
      for (int monthIx = 1; monthIx <= 12; monthIx++)
        if (thisYear.months[monthIx] > 0)
          IconButton(
            padding: EdgeInsets.all(4),
            icon: Icon(
                isCurrent(thisYear.yearno, monthIx)
                    ? Icons.ac_unit
                    : MonthlyStatus.icon(thisYear.yearno, monthIx),
                size: gridIconSize,
                color: monthProgressColor(thisYear.yearno, monthIx)),
            // tooltip: 'Todo: Maybe location info',
            onPressed: () {
              handleMonthClick(thisYear.yearno, monthIx);
            },
          )
        else
          IconButton(
            icon: Icon(Icons.radio_button_unchecked, size: gridIconSize),
            onPressed: () {},
          ),
    ]);
  } // of yearRowBuilder

  @override
  Widget build(BuildContext context) {
    bool smallScreen = (MediaQuery.of(context).size.width < 800);
    gridFontSize = smallScreen ? 12 : 24;
    gridIconSize = smallScreen ? 32 : 32;
    List<Widget> monthNamesHeader = [
      InkWell(
        child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: monthNames
                .map((monthName) => Text(
                      monthName,
                      style: TextStyle(
                          fontSize: gridFontSize, fontWeight: FontWeight.bold),
                    ))
                .toList()),
        onTap: () {
          log.message('resetting yearlist');
          yearList = Future.value(<YearEntry>[]);
        },
      )
    ];
    // return FutureBuilder(
    //   future: Future.wait([monthlyStatusIndic, yearList]),
    //   builder: (context, snapshot) {
    //     switch (snapshot.connectionState) {
    //       case ConnectionState.waiting:
    //         return Center(child: CircularProgressIndicator());
    //       case ConnectionState.done:
    //         if (snapshot.hasError)
    //           return Center(child: Text('${snapshot.error}'));
    //         if (!snapshot.hasData)
    //           return Center(child: Text('todo has no data'));
    //         // we are finally done with good data
    //         var myYearList = (snapshot.data! as List)[1] as List<YearEntry>;
    //         return ListView(
    //           children: [
    //             ...monthNamesHeader,
    //             for (var thisYear in myYearList) yearRowBuilder(thisYear)
    //           ],
    //         );
    //       default:
    //         return Text('State: ${snapshot.connectionState}');
    //     }
    //   },
    // );
    return aFutureBuilder(
        future: Future.wait([monthlyStatusIndic, yearList]),
        builder: (context, snapshot) {
          var myYearList = (snapshot.data!)[1] as List<YearEntry>;
          return ListView(
            children: [
              ...monthNamesHeader,
              for (var thisYear in myYearList) yearRowBuilder(thisYear)
            ],
          );
        }); // of aFuture builder
  }
}

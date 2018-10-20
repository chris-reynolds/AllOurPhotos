
//import 'package:flutter/cupertino.dart';
//import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:all_our_photos_app/ImgFile.dart';
import 'package:all_our_photos_app/ImageFilter.dart';
import 'package:all_our_photos_app/widgets/wdgPhotoGrid.dart';
import 'package:all_our_photos_app/widgets/wdgImageList.dart';
import 'package:all_our_photos_app/Logger.dart' as log;

// Note there is a blank month name in entry 0 for the year column
final List<String> monthNames = 'Year/Jan/Feb/Mar/Apr/May/Jun/Jul/Aug/Sep/Oct/Nov/Dec'.split('/');

class YearEntry {
  final int yearno;
  List<int> month = [0,0,0,0,0,0,0,0,0,0,0,0,0];
  YearEntry(this.yearno);
} // of yearEntry

List<YearEntry> yearList = [];
BuildContext lastContext; // TODO sus out about contexts

class MonthGrid extends StatelessWidget {
  MonthGrid() {
    buildYears();
  }

  @override
  Widget build(BuildContext context) {
    lastContext = context;
    TextStyle myTextStyle = TextStyle(fontSize: 20.0,fontWeight: FontWeight.bold);
    List<Widget> gridItems = [];
    for (YearEntry thisYear in yearList) {
      gridItems.add(Text('${thisYear.yearno}',style:myTextStyle));
    }
    List<Row> yearRows = yearList.map(
            (thisYear)=> yearRowBuilder(thisYear,myTextStyle)).toList();
    List<Widget> header = [
    Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: monthNames.map((monthName) =>
            Text(monthName,style:myTextStyle)).toList()
    )

    ];
    header.addAll(yearRows);
    return new Center(
      child: new Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: header

      ),
    );
  }
}

void buildYears() {
  if (yearList.length>0) {
    log.message('trying to rebuild yearlist!!!');
    return;
  }
  log.message('Building years grid');
  yearList.length = 0;
  log.message('Building each of ${ImgCatalog.length} directories');
  ImgCatalog.forEachDir((thisDirectory) {
    log.message('building [${thisDirectory.directoryName}]');
    int thisYearNo = int.parse(thisDirectory.directoryName.substring(0,4));
    int thisMonthNo = int.parse(thisDirectory.directoryName.substring(5,7));
    YearEntry thisYear;
    try {
      thisYear = yearList.firstWhere((year) {
        return year.yearno == thisYearNo;
      });
    } catch(ex) {
        thisYear = YearEntry(thisYearNo);
        yearList.add(thisYear);
    }
      thisYear.month[thisMonthNo] = thisDirectory.length;
      return true;
  }); // of directory loop
  yearList.sort((YearEntry y1,YearEntry y2)=> (y2.yearno-y1.yearno));
  log.message('${yearList.length} years loaded ${yearList[0].yearno}');
} // of buildYears

Row yearRowBuilder(YearEntry thisYear,TextStyle style) {
  List<Widget> cellList = [Text('${thisYear.yearno}',style:style)];
  for (int monthIx=1; monthIx<=12; monthIx++) {
    if (thisYear.month[monthIx] == 0)
      cellList.add(IconButton(
        icon: Icon(Icons.radio_button_unchecked,size: 12.0),
        onPressed: () {},
      ));
    else {
      cellList.add(IconButton(
        icon: Icon(Icons.image,size: 36.0),
        tooltip: 'Todo: Maybe location info',
        onPressed: () { lookAtMonth(thisYear.yearno, monthIx); },
      ));
    }
  }  // of month loop
  return Row (
    mainAxisAlignment: MainAxisAlignment.spaceEvenly,

    children: cellList
  );
} // of yearRowBuilder

void lookAtMonth(int yearNo,int monthNo) {
  log.message('look at ${monthNames[monthNo]} $yearNo ');
//  Navigator.push(lastContext, MaterialPageRoute(
//      builder: (context) =>ImageListWidget(ImageFilter.yearMonth(yearNo,monthNo))));
  Navigator.push(lastContext, MaterialPageRoute(
      builder: (context) =>GridListDemo.byFilter(ImageFilter.yearMonth(yearNo,monthNo))));
  log.message('fred was hear');
 // Navigator.of(context).
} // lookAtMonth

class YearGrid {
  Card makeCell(YearEntry thisYear, int monthNo) {
    if (monthNo == 0 ) {
      return Card(
        elevation: 0.0,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [Text('${thisYear.yearno}')]
      )
        );
    } else {  // return button
      return Card(
        elevation: 2.0,
        child : Center(
          child: Text('$monthNo', style:TextStyle(color:Colors.redAccent))
        )
      );
    } // of return month
  } // of makeCell
}
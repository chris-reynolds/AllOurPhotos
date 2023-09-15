// Created by Chris on 13/10/2018.

import 'package:aopcommon/aopcommon.dart';
import 'package:aopmodel/aopClasses.dart';

class ImageFilter
    with Selection<AopSnap>
    implements SelectableListProvider<AopSnap> {
  DateTime _fromDate = DateTime(1900);
  DateTime _toDate = DateTime(2030);
  @override
  late CallBack onRefreshed;
  // by default only show ranks 2 and 3
  final List<bool> _rank = <bool>[
    false,
    false,
    true,
    true
  ]; // ignore entry zero
  String _searchText = '';
  List<AopSnap> _images = [];
  @override
  List<AopSnap> get items {
    checkImages();
    return _images;
  }

  bool _refreshRequired = true;
  bool get refreshRequired => _refreshRequired;

  // two constructors
  ImageFilter.dateRange(this._fromDate, this._toDate,
      {required CallBack refresh}) {
    onRefreshed = refresh;
    log.message('Image Filter - Date constructor $searchText');
  } // create with dateRange

  ImageFilter.yearMonth(int year, int month, {required CallBack refresh}) {
    _fromDate = DateTime(year, month, 1);
    _toDate = monthEnd(_fromDate);
    _toDate = _toDate.subtract(Duration(seconds: 1));
    onRefreshed = refresh;
    log.message('Image Filter - yearmonth constructor $searchText');
  } // create with yearMonth

  ImageFilter.searchText(String searchText) {
    this.searchText = searchText; // force lowercase
    log.message('Image Filter - Search Text constructor $searchText');
  }

  DateTime get fromDate => _fromDate;
  set fromDate(DateTime newValue) {
    _fromDate = newValue;
    _refreshRequired = true;
  } // of set fromDate

  DateTime get toDate => _toDate;
  set toDate(DateTime newValue) {
    _toDate = newValue;
    _refreshRequired = true;
  } // of set fromDate

  String get searchText => _searchText;

  set searchText(String value) {
    _searchText = value.toLowerCase();
    _refreshRequired = true;
    log.message('searchText set to ($_searchText)');
  }

  bool getRank(int rankNo) => _rank[rankNo];

  setRank(int rankNo, bool value) {
    if (_rank[rankNo] != value) _refreshRequired = true;
    _rank[rankNo] = value;
  } // of setRank

  Future<void> checkImages() async {
//    print('checking images with refreshRequired set to $_refreshRequired');
    if (!_refreshRequired) return;
    _images = await snapProvider.getSome(whereClause(),
        orderBy: 'taken_date,id'); //todo: reverse order
    clearSelected();
    // todo check ascending or descending date sort
    //   _images.sort((img1,img2) => img1.takenDate.difference(img2.takenDate).inMinutes);
    _refreshRequired = false;
    log.message('returning ${_images.length} images');
    //if (onRefreshed != null)
    onRefreshed(); // alert listen of changes
  } // of calcImages

  String whereClause() {
    String result =
        ' taken_date between \'${dbDate(_fromDate)}\' and \'${dbDate(_toDate.add(Duration(seconds: -1)))}\'';
    if (searchText != '') {
      result +=
          "and ((location) like '%$searchText%' or caption like '%$searchText%' or file_name like '%$searchText%' or device_name like '%$searchText%' or tag_list like '%$searchText%')";
    }
    result += ' and ranking in (';
    for (int rankNo = 1; rankNo <= 3; rankNo++)
      if (_rank[rankNo]) result += '$rankNo,';
    result += '-999) ';
    // todo string search criteria
    return result;
  } // of whereClause

  void extendDateRange({int days = 7}) {
    _toDate = _toDate.add(Duration(days: days));
    _refreshRequired = true;
  } //

  void moveMonth(int increment) {
    _fromDate = addMonths(_fromDate, increment);
    _toDate = monthEnd(_fromDate);
    _refreshRequired = true;
  } // of moveMonth
} // of ImageFilter


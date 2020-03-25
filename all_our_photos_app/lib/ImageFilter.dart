import 'package:all_our_photos_app/dart_common/ListUtils.dart';

/**
 * Created by Chris on 13/10/2018.
 */

import 'shared/aopClasses.dart';
import 'dart_common/DateUtil.dart';
import 'dart_common/Logger.dart' as Log;
import 'dart_common/ListProvider.dart';


class ImageFilter with Selection<AopSnap> implements SelectableListProvider<AopSnap> {

  DateTime _fromDate = DateTime(1900);
  DateTime _toDate = DateTime(2030);
  CallBack onRefreshed;
  // by default only show ranks 2 and 3
  List<bool> _rank = <bool>[null,false,true,true];  // ignore entry zero
  String _searchText = '';
  List<AopSnap> _images;
  List<AopSnap> get items {
    checkImages();
    return _images;
  }

  bool _refreshRequired = true;
  bool get refreshRequired => _refreshRequired;

  // two constructors
  ImageFilter.dateRange(this._fromDate, this._toDate,{CallBack refresh}) {
    onRefreshed = refresh;
    print('Image Filter - Date constructor $searchText');
  } // create with dateRange

  ImageFilter.yearMonth(int year,int month,{CallBack refresh}) {
    _fromDate = DateTime(year,month,1);
    _toDate = addMonths(_fromDate,1);
    _toDate = _toDate.subtract(Duration(seconds: 1));
    onRefreshed = refresh;
    print('Image Filter - yearmonth constructor $searchText');
  }  // create with yearMonth

  ImageFilter.searchText(String searchText) {
    this.searchText = searchText;  // force lowercase
    print('Image Filter - Search Text constructor $searchText');
  }

  get fromDate => _fromDate;
  set fromDate(newValue) {
    _fromDate = newValue;
    _refreshRequired = true;
  } // of set fromDate

  get toDate => _toDate;
  set toDate(newValue) {
    _toDate = newValue;
    _refreshRequired = true;
  } // of set fromDate

  get searchText => _searchText;

  set searchText(String value) {
    _searchText = value.toLowerCase();
    _refreshRequired = true;
    print('searchText set to ($_searchText)');
  }
  bool getRank(int rankNo) => _rank[rankNo];

  setRank(int rankNo,bool value) {
    if (_rank[rankNo] != value)
      _refreshRequired = true;
    _rank[rankNo] = value;
  } // of setRank

  Future<void> checkImages() async {
//    print('checking images with refreshRequired set to $_refreshRequired');
    if (!_refreshRequired) return;
    _images = await snapProvider.getSome(whereClause(),orderBy: 'taken_date');
    // todo check ascending or descending date sort
    _images.sort((img1,img2) => img1.takenDate.difference(img2.takenDate).inMinutes);
    _refreshRequired = false;
    Log.message('returning ${_images.length} images');
    if (onRefreshed != null)  // alert listen of changes
      onRefreshed();
  } // of calcImages

  String whereClause() {
    String result = ' taken_date between \'${dbDate(_fromDate)}\' and \'${dbDate(_toDate)}\'';
     if (searchText != '') {
       result += "and ((location) like '%$searchText%' or caption like '%$searchText%' or file_name like '%$searchText%' or device_name like '%$searchText%')";
     }
     result += ' and ranking in (';
     for (int rankNo=1;rankNo<=3;rankNo++)
       if (_rank[rankNo])
         result +='$rankNo,';
     result += '-999) ';
     // todo string search criteria
     return result;
  } // of whereClause

  void extendDateRange({int days = 7}) {
    _toDate = _toDate.add(Duration(days:days));
    _refreshRequired = true;
  } //
} // of ImageFilter


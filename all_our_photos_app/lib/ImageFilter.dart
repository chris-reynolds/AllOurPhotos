/**
 * Created by Chris on 13/10/2018.
 */

import 'shared/aopClasses.dart';
import 'dart_common/DateUtil.dart';
import 'dart_common/Logger.dart' as Log;

typedef ImageFilterAction = void Function();
class ImageFilter {

  DateTime _fromDate = DateTime(1900);
  DateTime _toDate = DateTime(2030);
  ImageFilterAction onRefresh;
  // by default only show ranks 2 and 3
  List<bool> _rank = <bool>[null,false,true,true];  // ignore entry zero
  String _searchText = '';
  List<AopSnap> _images;
  get images {
    checkImages();
    return _images;
  }

  bool _refreshRequired = true;
  bool get refreshRequired => _refreshRequired;

  // two constructors
  ImageFilter.dateRange(this._fromDate, this._toDate,{ImageFilterAction refresh}) {
    onRefresh = refresh;
    print('Image Filter - Date constructor $searchText');
  } // create with dateRange

  ImageFilter.yearMonth(int year,int month,{ImageFilterAction refresh}) {
    _fromDate = DateTime(year,month,1);
    _toDate = addMonths(_fromDate,1);
    onRefresh = refresh;
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

//  bool isWanted(AopSnap thisImage) {
//    try {
////      if (thisImage.deletedDate != null) return false;
//      if (!_rank[thisImage.ranking]) return false;
//      if (thisImage.takenDate == null || thisImage.takenDate.isBefore(_fromDate)) return false;
//      if (thisImage.takenDate == null || thisImage.takenDate.isAfter(_toDate)) return false;
//      if (_searchText.length > 0 )
//        if ((thisImage.caption+' '+thisImage.location+' '+
//            thisImage.tagList).toLowerCase().indexOf(_searchText)<0) return false;
//      return true;
//    } catch(ex) {
//      return true;
//    }
//  } // isWanted
  Future<void> checkImages() async {
//    print('checking images with refreshRequired set to $_refreshRequired');
    if (!_refreshRequired) return;
    _images = await snapProvider.getSome(whereClause());
    // todo check ascending or descending date sort
    _images.sort((img1,img2) => img1.takenDate.difference(img2.takenDate).inMinutes);
    _refreshRequired = false;
    Log.message('returning ${_images.length} images');
    if (onRefresh != null)  // alert listen of changes
      onRefresh();
  } // of calcImages

  String whereClause() {
    String result = ' taken_date between \'${formatDate(_fromDate)}\' and \'${formatDate(_toDate)}\'';
     if (searchText != '') {
       result += "and ((location) like '%$searchText%' or caption like '%$searchText%' or file_name like '%$searchText%') ";
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


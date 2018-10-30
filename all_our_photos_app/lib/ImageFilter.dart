/**
 * Created by Chris on 13/10/2018.
 */

import 'package:all_our_photos_app/ImgFile.dart';


typedef ImageFilterAction = void Function(ImageFilter);

class ImageFilter {

  DateTime _fromDate = DateTime(1900);
  DateTime _toDate = DateTime(2030);
  ImageFilterAction onRefresh;
  List<bool> rank = <bool>[null,false,true,true];  // ignore entry zero
  String _searchText = '';
  List<ImgFile> _images;
  get images {
    checkImages();
    return _images;
  }

  bool _refreshRequired = true;
  bool get refreshRequired => _refreshRequired;

  // two constructors
  ImageFilter.dateRange(this._fromDate, this._toDate,{ImageFilterAction refresh}) {
    onRefresh = refresh;
  } // create with dateRange

  ImageFilter.yearMonth(int year,int month,{ImageFilterAction refresh}) {
    _fromDate = DateTime(year,month,1);
    _toDate = _fromDate.add(Duration(days: 31));
    onRefresh = refresh;
  }  // create with yearMonth

  ImageFilter.searchText(String searchText) {
    this.searchText = searchText;  // force lowercase
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

  set searchText(String value) {
    _searchText = value.toLowerCase();
    _refreshRequired = true;
  }
  setRank(int rankNo,bool value) {
    if (rank[rankNo] != value)
      _refreshRequired = true;
    rank[rankNo] = value;
  } // of setRank

  bool isWanted(thisImage) {
    try {
      if (thisImage.deletedDate != null) return false;
      if (!rank[thisImage.rank]) return false;
      if (thisImage.takenDate == null || thisImage.takenDate.isBefore(_fromDate)) return false;
      if (thisImage.takenDate == null || thisImage.takenDate.isAfter(_toDate)) return false;
      if (_searchText.length > 0 )
        if ((thisImage.caption+' '+thisImage.location+' '+
            thisImage.tags).toLowerCase().indexOf(_searchText)<0) return false;
      return true;
    } catch(ex) {
      return true;
    }
  } // isWanted
  void checkImages() {
    if (!_refreshRequired) return;
    _images = [];
    ImgCatalog.actOnAll((thisImage) {
      if (isWanted(thisImage))
        _images.add(thisImage);
      return true;
      }); // actoOnAll
    // todo check ascending or descending date sort
    _images.sort((img1,img2) => img1.takenDate.difference(img2.takenDate).inMinutes);
    _refreshRequired = false;
    if (onRefresh != null)  // alert listen of changes
      onRefresh(this);
  } // of calcImages

  void extendDateRange({int days = 7}) {
    _toDate = _toDate.add(Duration(days:days));
    _refreshRequired = true;
  } //
} // of ImageFilter


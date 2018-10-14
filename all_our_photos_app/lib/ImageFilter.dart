/**
 * Created by Chris on 13/10/2018.
 */

import './ImgFile.dart';

int _defaultMinRank = 1;
int _defaultMaxRank = 2;

class ImageFilter {


  DateTime _fromDate = DateTime(1900);
  DateTime _toDate = DateTime(2030);
  int _minRank = _defaultMinRank;
  int _maxRank = _defaultMaxRank;
  String _searchText = '';
  List<ImgFile> _images;
  bool _refreshRequired = true;
  // two constructors
  ImageFilter.dateRange(this._fromDate, this._toDate);
  ImageFilter.searchText(String searchText) {
    this.searchText = searchText;  // force lowercase
  }

  set searchText(String value) {
    _searchText = value.toLowerCase();
    _refreshRequired = true;
  }
  setRankRange(int min,int max) {
     _minRank = min;
     _maxRank = max;
     _refreshRequired = true;
  }
  void checkImages() {
    if (!_refreshRequired) return;
    _images = [];
    ImgCatalog.actOnAll((thisImage) {
      if (thisImage.deletedDate != null) return;
      if (thisImage.rank < _minRank) return;
      if (thisImage.rank > _maxRank) return;
      if (thisImage.takenDate.isBefore(_fromDate)) return;
      if (thisImage.takenDate.isAfter(_toDate)) return;
      if (_searchText.length > 0 )
        if ((thisImage.caption+' '+thisImage.location+' '+
            thisImage.tags).toLowerCase().indexOf(_searchText)<0) return;
      _images.add(thisImage);
    });
    // todo check ascending or descending date sort
    _images.sort((img1,img2) => img1.takenDate.difference(img2.takenDate).inMinutes);
    _refreshRequired = false;
  } // of calcImages

  void extendDateRange({int days = 7}) {
    _toDate = _toDate.add(Duration(days:days));
    _refreshRequired = true;
  } //
} // of ImageFilter


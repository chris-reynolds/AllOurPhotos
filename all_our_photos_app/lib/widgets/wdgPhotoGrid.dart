/*
  Created by Chris on 20th Oct 2018

  Purpose: Stateful PhotoGrid widget with multi-select
*/

import 'package:flutter/material.dart';
import '../dart_common/Logger.dart' as Log;
import '../dart_common/DateUtil.dart';
import '../shared/aopClasses.dart';
import '../screens/scSimpleDlg.dart';
import '../screens/scTypeAheadDlg.dart';
import '../ImageFilter.dart';
import 'wdgImageFilter.dart';
import 'ImageEditorWidget.dart';
import 'wdgPhotoTile.dart';
import '../flutter_common/WidgetSupport.dart';

class PhotoGrid extends StatefulWidget {
  final ImageFilter _initImageFilter;

  PhotoGrid(this._initImageFilter) {
//    Log.message('PhotoGrid constructor by filter');
  }

  @override
  PhotoGridState createState() => new PhotoGridState();
}

class PhotoGridState extends State<PhotoGrid> {
  ImageFilter _imageFilter;
  double _targetOffset = 0.0;
  ScrollController _scrollController = ScrollController();
  int zzz = 0;
  List<String> _selectedImages = [];

  bool isSelected(AopSnap snap) {
    int idx = _selectedImages.indexOf(snap.fileName);
    return (idx >= 0);
  } // of isSelected

  void toggleSelected(AopSnap snap) {
    int idx = _selectedImages.indexOf(snap.fileName);
    if (idx < 0)
      _selectedImages.add(snap.fileName);
    else
      _selectedImages.removeAt(idx);
  } // of toggleSelected;

  void clearSelected() {
    _selectedImages.length = 0;
  } // clearSelected

  void selectAll({bool repaint:true}) {
    // Select All can Clear All
    bool clearAll = (_selectedImages.length ==_imageFilter.images.length);
    _selectedImages = [];
    if (!clearAll) {
      _imageFilter.images.forEach((AopSnap snap) {
          _selectedImages.add(snap.fileName);
      });
    }
    if (repaint)
      setState(() {});
  } // of selectAll

  int _picsPerRow = 3; // can be toggled
  void changePicsPerRow() {
    setState(() {
      int oldPicsPerRow = _picsPerRow;
      double oldOffset = _scrollController.offset;
      if (--_picsPerRow <= 0) _picsPerRow = 5;
//      switch (_picsPerRow) {
//        case 4:
//          _picsPerRow = 3;
//          break;
//        case 2:
//          _picsPerRow = 1;
//          break;
//        default:
//          _picsPerRow = 2;
//      } // of switch
      double targetOffset = oldOffset * oldPicsPerRow / _picsPerRow;
      _targetOffset = targetOffset;
      //     Log.message(
      //         '=============scroll controller offset $oldOffset to $targetOffset');
    });
  } // of changePicsPerRow

  bool _inSelectMode = false;

  void changeSelectMode() {
    setState(() {
      _selectedImages = [];
      _inSelectMode = !_inSelectMode;
    });
  }

  @override
  void initState() {
    super.initState();
    _imageFilter = widget._initImageFilter;
    _imageFilter.onRefresh = filterRefreshCallback;
    //   Log.message('PhotoGrid copying initFilter');
  }

  @override
  void didUpdateWidget(PhotoGrid oldWidget) {
    super.didUpdateWidget(oldWidget);
  }

  void filterRefreshCallback() {
    setState(() {
      Log.message('filterRefresh triggered ${++zzz}');
    });
  }

  List<AopSnap> get onlySelectedSnaps => _imageFilter.images.where(isSelected).toList();

  void editorCallback(String caption, String location) {
    int updateCount = 0;
    if (caption == '' && location == '') return;
    setState(() {
      for (int ix = 0; ix < _imageFilter.images.length; ix++) {
        AopSnap thisImage = _imageFilter.images[ix];
        if (isSelected(thisImage)) {
          if (caption != '') thisImage.caption = caption;
          if (location != '') thisImage.location = location;
          updateCount++;
        }
      }
    });
    Log.message('$updateCount images updated');
  } // editor Callback

  @override
  Widget build(BuildContext context) {
//    final Orientation orientation = MediaQuery.of(context).orientation;
    _scrollController =
        ScrollController(initialScrollOffset: _targetOffset, keepScrollOffset: false);

    return new Scaffold(
      appBar: new AppBar(
        title: (!_inSelectMode)
            ? const Text('Grid list')
            : Row(
                children: <Widget>[
                  Text('Select All'),
                  IconButton(
                      icon: Icon(Icons.select_all),
                      onPressed: () {
                        selectAll();
                      }),
                ],
              ),
        actions: <Widget>[
          if (_inSelectMode && _selectedImages != null && _selectedImages.length > 0) ...[
            IconButton(
                icon: Icon(Icons.star_border, color: Colors.black),
                onPressed: () {
                  handleMultiSetGreen(context, onlySelectedSnaps);
                }),
            IconButton(
                icon: Icon(Icons.text_fields),
                onPressed: () {
                  handleMultiCaption(context, onlySelectedSnaps);
                }),
            IconButton(
                icon: Icon(Icons.date_range),
                onPressed: () {
                  handleMultiTakenDate(context, onlySelectedSnaps);
                }),
            IconButton(
                icon: Icon(Icons.location_on),
                onPressed: () {
                  handleMultiLocation(context, onlySelectedSnaps);
                }),
          ],
          new IconButton(icon: Icon(Icons.check_box), onPressed: changeSelectMode),
          new IconButton(icon: Icon(Icons.photo_size_select_large), onPressed: changePicsPerRow),
        ],
      ),
      body: new Column(children: <Widget>[
        ImageFilterWidget(_imageFilter, onRefresh: filterRefreshCallback),
        new Expanded(
          child: GridView.count(
            controller: _scrollController,
            crossAxisCount: _picsPerRow,
            //(orientation == Orientation.portrait) ? 4 : 6,
            mainAxisSpacing: 4.0,
            crossAxisSpacing: 4.0,

            padding: const EdgeInsets.all(4.0),
            childAspectRatio: 1.0,
            //(orientation == Orientation.portrait) ? 1.0 : 1.3,
            children: [
              if (_imageFilter.images != null)
                for (int idx = 0; idx < _imageFilter.images.length; idx++)
                  PhotoTile(
                      isSelected: isSelected(_imageFilter.images[idx]),
                      snapList: _imageFilter.images,
                      index: idx,
                      inSelectMode: _inSelectMode,
                      highResolution: (_picsPerRow == 1),
                      onBannerTap: (imageFile) {
                        setState(() {
                          if (_inSelectMode)
                            toggleSelected(imageFile);
                          else {
                            imageFile.ranking = (imageFile.ranking + 1) % 3 + 1;
                            imageFile.save();
                          }
                        }); // setState
                      }), // bannerTap
            ],
          ),
        ),
        _inSelectMode ? ImageEditorWidget2(editorCallback) : Container(),
      ]), //of expanded
    ); // of column
  }

  void handleMultiCaption(BuildContext context, List<AopSnap> snaps) async {
    String value = '';
    String errorMessage = '';
    bool done = false;
    while (!done) {
      value = await showDialog(
          context: context,
          builder: (BuildContext context) => DgSimple('Caption for ${snaps.length} images', value,
                  errorMessage: errorMessage, isValid: (value) async {
                return (value.length < 10) ? 'Too short' : null;
              }));
      if (value == null || value == EXIT_CODE) return;
      Log.message('new caption is: $value');
      errorMessage = '';
      done = true;
      for (AopSnap snap in snaps) {
        snap.caption = value;
        if (snap.isValid)
          await snap.save();
        else {
          errorMessage = snap.lastErrors.join('\n');
          done = false;
          break;
        }
      } // of for loop
    } // of done loop
    setState(() {});
  } // handleMultiCaption

  void handleMultiTakenDate(BuildContext context, List<AopSnap> snaps) async {
    String value = '';
    String errorMessage = '';
    bool done = false;
    while (!done) {
      value = await showDialog(
          context: context,
          builder: (BuildContext context) =>
              DgSimple('Taken Date for ${snaps.length} images', value, errorMessage: errorMessage,
                  isValid: (value) async {
                try {
                  parseDMY(value);
                  return null;
                } catch (ex) {
                  return '$ex';
                }
              }));
      if (value == null || value == EXIT_CODE) return;
      try {
        Log.message('new taken date is: $value');
        DateTime newTakenDate = parseDMY(value);
        errorMessage = '';
        done = true;
        for (AopSnap snap in snaps) {
          snap.takenDate = newTakenDate;
          if (snap.isValid)
            await snap.save();
          else {
            errorMessage = snap.lastErrors.join('\n');
            done = false;
            break;
          }
        } // of for loop
      } catch (ex) {
        errorMessage = '$ex';
        done = false;
      }
    } // of done loop
    setState(() {});
  } // handleMultiTakenDate

  void handleMultiLocation(BuildContext context, List<AopSnap> snaps) async {
    String value = '';
    String errorMessage = '';
    bool done = false;
    List<String> allLocations = await AopSnap.distinctLocations;
    while (!done) {
      value = await showDialog(
          context: context,
          builder: (BuildContext context) => DgTypeAhead(
                  'Location for ${snaps.length} images', allLocations, value,
                  errorMessage: errorMessage, isValid: (value) async {
                try {
                  if (value.split(',').length < 3) throw 'We need at least town,region,country';
                  return null;
                } catch (ex) {
                  return '$ex';
                }
              }));
      if (value == null || value == EXIT_CODE) return;
      try {
        Log.message('new location is: $value');
        errorMessage = '';
        done = true;
        for (AopSnap snap in snaps) {
          snap.location = value;
          if (snap.isValid)
            await snap.save();
          else {
            errorMessage = snap.lastErrors.join('\n');
            done = false;
            break;
          }
        } // of for loop
      } catch (ex) {
        errorMessage = '$ex';
        done = false;
      }
    } // of done loop
    setState(() {});
  } // handleMultiLocation

  void handleMultiSetGreen(BuildContext context, List<AopSnap> snaps) async {
    String resultMessage = '${snaps.length} snaps updated';
    try {
      for (AopSnap snap in snaps) {
        snap.ranking = 3;
        if (snap.isValid)
          await snap.save();
        else {
          resultMessage = snap.lastErrors.join('\n');
          break;
        }
      } // of for loop
    } catch (ex) {
      resultMessage = '$ex';
    }
    Log.message(resultMessage);
    showMessage(context, resultMessage);
    setState(() {});
  } // handleMultiSetGreen



}

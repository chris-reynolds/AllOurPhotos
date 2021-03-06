/*
  Created by Chris on 20th Oct 2018

  Purpose: Stateful PhotoGrid widget with multi-select
*/

import 'dart:io';
import 'package:flutter/material.dart';
import '../dart_common/Logger.dart' as Log;
import '../dart_common/DateUtil.dart';
import '../shared/aopClasses.dart';
import '../screens/scSimpleDlg.dart';
import '../screens/scTypeAheadDlg.dart';
import '../ImageFilter.dart';
import 'wdgImageFilter.dart';

//import 'ImageEditorWidget.dart.xxx';
import 'wdgPhotoTile.dart';
import '../flutter_common/WidgetSupport.dart';
import '../dart_common/ListProvider.dart';
import '../dart_common/ListUtils.dart';
import '../dart_common/WebFile.dart';


class PhotoGrid extends StatefulWidget {
  final SelectableListProvider<AopSnap> _initImageFilter;
  final AopAlbum _album;

  PhotoGrid(this._initImageFilter, {AopAlbum album}) : this._album = album {
//    Log.message('PhotoGrid constructor by filter');
  }

  @override
  PhotoGridState createState() => new PhotoGridState();
}

class PhotoGridState extends State<PhotoGrid> with Selection<int> {
  SelectableListProvider<AopSnap> _imageFilter;
  double _targetOffset = 0.0;
  ScrollController _scrollController = ScrollController();



  void selectAll({bool repaint: true}) {
    // Select All can Clear All
    bool clearAll = (_imageFilter.selectionList.length == _imageFilter.items.length);
    _imageFilter.clearSelected();
    if (!clearAll) {
      _imageFilter.items.forEach((AopSnap snap) {
        _imageFilter.setSelected(snap, true);
      });
    }
    if (repaint) setState(() {});
  } // of selectAll

  int _picsPerRow = -1; // can be toggled
  int _maxPicsPerRow = 5;

  void changePicsPerRow() {
    setState(() {
      int oldPicsPerRow = _picsPerRow;
      double oldOffset = _scrollController.offset;
      if (--_picsPerRow <= 0) _picsPerRow = _maxPicsPerRow;
      double targetOffset = oldOffset * oldPicsPerRow / _picsPerRow;
      _targetOffset = targetOffset;
    });
  } // of changePicsPerRow

  bool _inSelectMode = false;

  void changeSelectMode() {
    setState(() {
      // todo check clearselection maybe
      _imageFilter.clearSelected();
      _inSelectMode = !_inSelectMode;
    });
  }

  @override
  void initState() {
    super.initState();
    _imageFilter = widget._initImageFilter;
    _imageFilter.onRefreshed = filterRefreshCallback;
    //   Log.message('PhotoGrid copying initFilter');
  }

  @override
  void didUpdateWidget(PhotoGrid oldWidget) {
    super.didUpdateWidget(oldWidget);
  }

  void filterRefreshCallback() {
    setState(() {
      Log.message('filterRefresh triggered ');
    });
  }

//  List<AopSnap> get onlySelectedSnaps => _imageFilter.items.where(isSelected).toList();

  void editorCallback(String caption, String location) {
    int updateCount = 0;
    if (caption == '' && location == '') return;
    setState(() {
      for (int ix = 0; ix < _imageFilter.items.length; ix++) {
        AopSnap thisImage = _imageFilter.items[ix];
        if (_imageFilter.isSelected(thisImage)) {
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
    if (_picsPerRow == -1) {
      _picsPerRow = Platform.isMacOS ? 5: 3;
      _maxPicsPerRow = Platform.isMacOS ? 10:5;
    }
    return new Scaffold(
      appBar: new AppBar(
        title: (!_inSelectMode)
            ? const Text('Grid list')
            : Row(
                children: <Widget>[
                  //          Text('Select All'),
                  IconButton(
                      icon: Icon(Icons.select_all),
                      tooltip: 'Select/Clear All',
                      onPressed: () {
                        selectAll();
                      }),
                ],
              ),
        actions: <Widget>[
          if (_inSelectMode && _imageFilter.selectionList.length > 0) ...[
            if (Platform.isMacOS)
              new IconButton(
                icon: Icon(Icons.file_download),
                tooltip: 'Export photo(s) to downloads folder',
                onPressed: () {
                  handleDownload(context,_imageFilter.selectionList).then((xx) {
                    setState(() {});
                  });
                },
              ),
            if (widget._album != null)
              IconButton(
                  icon: Icon(Icons.delete, color: Colors.black),
                  onPressed: () {
                    handleMultiRemoveFromAlbum(context, _imageFilter.selectionList);
                  }),
            IconButton(
                icon: Icon(Icons.star_border, color: Colors.black),
                tooltip: 'Set selected images green',
                onPressed: () {
                  handleMultiSetGreen(context, _imageFilter.selectionList);
                }),
            IconButton(
                icon: Icon(Icons.text_fields),
                tooltip: 'add a caption to selected images',
                onPressed: () {
                  handleMultiCaption(context, _imageFilter.selectionList);
                }),
            IconButton(
                icon: Icon(Icons.date_range),
                tooltip: 'Change taken date for selected images',
                onPressed: () {
                  handleMultiTakenDate(context, _imageFilter.selectionList);
                }),
            IconButton(
                icon: Icon(Icons.location_on),
                tooltip: 'Change location for selected images',
                onPressed: () {
                  handleMultiLocation(context, _imageFilter.selectionList);
                }),
          ],
          IconButton(
              icon: Icon(Icons.check_box),
              tooltip: 'Selection Mode on/off',
              onPressed: changeSelectMode),
          IconButton(
              icon: Icon(Icons.photo_size_select_large),
              tooltip: 'Change no of photos per line',
              onPressed: changePicsPerRow),
        ],
      ),
      body: new Column(children: <Widget>[
        if (_imageFilter is ImageFilter)
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
              if (_imageFilter.items != null)
                for (int idx = 0; idx < _imageFilter.items.length; idx++)
                  PhotoTile(
                      isSelected: _imageFilter.isSelected(_imageFilter.items[idx]),
                      snapList: _imageFilter.items,
                      index: idx,
                      inSelectMode: _inSelectMode,
                      highResolution: (_picsPerRow == 1),
                      onBannerTap: (imageFile) {
                        setState(() {
                          if (_inSelectMode)
                            _imageFilter.setSelected(_imageFilter.items[idx],
                                !_imageFilter.isSelected(_imageFilter.items[idx]));
                          //                     toggleSelected(imageFile);
                          else {
                            imageFile.ranking = (imageFile.ranking + 1) % 3 + 1;
                            imageFile.save();
                          }
                        }); // setState
                      }), // bannerTap
            ],
          ),
        ),
//        _inSelectMode ? ImageEditorWidget2(editorCallback) : Container(),
      ]), //of expanded
    ); // of column
  }

  void handleMultiCaption(BuildContext context, List<AopSnap> snaps) async {
    String value = '';
    String errorMessage = '';
    bool done = false;
    if (snaps.length>0)  // use first caption as default
      value = snaps[0].caption ?? '';
    while (!done) {
      value = await showDialog(
          context: context,
          builder: (BuildContext context) => DgSimple('Caption for ${snaps.length} images', value,
                  errorMessage: errorMessage, /*isValid: (value) async {
                return (value.length < 10) ? 'Too short' : null;
              }) */));
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

  void handleMultiRemoveFromAlbum(BuildContext  context, List<AopSnap> selectedSnaps) async {
    try {
      int result = await widget._album.removeSnaps(selectedSnaps);
      showMessage(context,'$result items removed from album');
    } catch(ex) {
      showMessage(context, 'Error: ${ex}');
    }
    setState(() {});
  } // of handleMultiRemoveFromAlbum*/

  Future<void> handleDownload(BuildContext context,List<AopSnap> selectedSnaps) async {
    String dirName = '${Platform.environment['HOME']}/Downloads/';
    String albumName = 'AllOurPhotos';
    if (widget._album != null) {
      albumName = widget._album.name.replaceAll('/', '-').replaceAll('\\', '-').replaceAll(' ', '');
    }
    if (albumName.length > 20)
      albumName = albumName.substring(0,19);
    dirName += albumName+'/';
    if (!Directory(dirName).existsSync())
      Directory(dirName).createSync();
    // make directory in downloads
    for (int snapIx=0; snapIx< selectedSnaps.length; snapIx++) {
//      showMessage(context,'${selectedSnaps.length-snapIx} photos to download');
      String sourceURL = selectedSnaps[snapIx].fullSizeURL;
      List<int> imgBytes = await loadWebBinary(sourceURL);
      File(dirName+selectedSnaps[snapIx].fileName).writeAsBytesSync(imgBytes,mode: FileMode.append );
    }
    showMessage(context,'Download complete. See your $dirName directory');
  } // of handleDownload
}

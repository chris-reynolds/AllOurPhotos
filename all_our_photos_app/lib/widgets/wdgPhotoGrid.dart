/*
  Created by Chris on 20th Oct 2018

  Purpose: Stateful PhotoGrid widget with multi-select
*/

// import 'dart:io';
import 'package:flutter/material.dart';
import 'package:aopcommon/aopcommon.dart';
import 'package:aopmodel/aop_classes.dart';
import '../screens/scSimpleDlg.dart';
import '../screens/scTypeAheadDlg.dart';
import '../ImageFilter.dart';
import 'wdgImageFilter.dart';
import '../utils/ExportPic.dart';
import 'wdgPhotoTile.dart';
import '../flutter_common/WidgetSupport.dart';
import '../MonthlyStatus.dart';

class PhotoGrid extends StatefulWidget {
  final SelectableListProvider<AopSnap> _initImageFilter;
  final AopAlbum? _album;
  final CallBack? _refreshNow;
  final CallBack? removeAlbumItems;

  PhotoGrid(this._initImageFilter,
      {AopAlbum? album, CallBack? refreshNow, this.removeAlbumItems, super.key})
      : _album = album,
        _refreshNow = refreshNow {
//    log.message('PhotoGrid constructor by filter');
  }

  @override
  PhotoGridState createState() => PhotoGridState();
}

class PhotoGridState extends State<PhotoGrid> with Selection<int> {
  late SelectableListProvider<AopSnap> _imageFilter;
  double _targetOffset = 0.0;
  ScrollController _scrollController = ScrollController();

  void selectAll({bool repaint = true}) {
    // Select All can Clear All
    bool clearAll =
        (_imageFilter.selectionList.length == _imageFilter.items.length);
    _imageFilter.clearSelected();
    if (!clearAll) {
      for (var snap in _imageFilter.items) {
        _imageFilter.setSelected(snap, true);
      }
    }

    if (repaint) setState(() {});
  } // of selectAll

  int _picsPerRow = UIPreferences.defaultGridColumns;
  int _maxPicsPerRow = UIPreferences.maxGridColumns;

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

  void changeMonthlyStatus() {
    if (_imageFilter is ImageFilter) {
      DateTime startDate = (_imageFilter as ImageFilter).fromDate;
      int yearNo = startDate.year;
      int monthNo = startDate.month;
      bool currentStatus = MonthlyStatus.read(yearNo, monthNo);
      MonthlyStatus.write(yearNo, monthNo, !currentStatus).then((x) {
        log.message('switched month to ${!currentStatus}');
        setState(() {});
      });
    }
  }

  IconData calcMonthlyStatusIcon() {
    DateTime startDate = (_imageFilter as ImageFilter).fromDate;
    int yearNo = startDate.year;
    int monthNo = startDate.month;
    bool currentStatus = MonthlyStatus.read(yearNo, monthNo);
    if (currentStatus)
      return Icons.done_outline_sharp;
    else
      return Icons.question_mark;
  }

  void changeSelectMode() {
    setState(() {
      // todo check clear selection maybe
      _imageFilter.clearSelected();
      _inSelectMode = !_inSelectMode;
    });
  }

  @override
  void initState() {
    super.initState();
    _imageFilter = widget._initImageFilter;
    _imageFilter.onRefreshed = filterRefreshCallback;
    _inSelectMode =
        (widget._album != null); // album always starts in select mode
  }

  @override
  void didUpdateWidget(PhotoGrid oldWidget) {
    super.didUpdateWidget(oldWidget);
  }

  void filterRefreshCallback() {
    setState(() {
      log.message('filterRefresh triggered ');
    });
  }

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
    log.message('$updateCount images updated');
  } // editor Callback

  @override
  Widget build(BuildContext context) {
//    final Orientation orientation = MediaQuery.of(context).orientation;
    _scrollController = ScrollController(
        initialScrollOffset: _targetOffset, keepScrollOffset: false);
    if (_picsPerRow == -1) {
      _picsPerRow = 2; //Platform.isMacOS ? 5 : 2;
      _maxPicsPerRow = 5; //Platform.isMacOS ? 10 : 5;
    }
    return Scaffold(
      appBar: AppBar(
        title: (!_inSelectMode)
            ? const Text('Grid list')
            : Row(
                children: <Widget>[
                  IconButton(
                      icon: Icon(Icons.select_all),
                      tooltip: 'Select/Clear All',
                      onPressed: () {
                        selectAll();
                      }),
                ],
              ),
        actions: <Widget>[
          if (_inSelectMode && _imageFilter.selectionList.isNotEmpty) ...[
            //           if (Platform.isMacOS)
            IconButton(
                icon: Icon(Icons.file_download),
                tooltip: 'Export photo(s)',
                onPressed: () async {
                  await ExportPic.exportSeveral(_imageFilter.selectionList);
                }),

            if (widget._album != null)
              IconButton(
                  icon: Icon(Icons.delete),
                  tooltip: 'Remove selected photos from album',
                  onPressed: () {
                    handleMultiRemoveFromAlbum(
                        context, widget._album!, _imageFilter.selectionList);
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
          if (widget._album == null) // only for monthly grid
            IconButton(
                icon: Icon(calcMonthlyStatusIcon()),
                tooltip: 'Mark Month as Done',
                onPressed: changeMonthlyStatus),
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
      body: Column(children: <Widget>[
        if (_imageFilter is ImageFilter)
          ImageFilterWidget(_imageFilter as ImageFilter,
              onRefresh: filterRefreshCallback),
        Expanded(
          child: GridView.count(
            controller: _scrollController,
            crossAxisCount: _picsPerRow,
            //(orientation == Orientation.portrait) ? 4 : 6,
            mainAxisSpacing: 4.0,
            crossAxisSpacing: 4.0,

            padding: const EdgeInsets.all(4.0),
            childAspectRatio: 1.1,
            //(orientation == Orientation.portrait) ? 1.0 : 1.3,
            children: [
              //   if (_imageFilter.items != null)
              for (int idx = 0; idx < _imageFilter.items.length; idx++)
                PhotoTile(
                    isSelected:
                        _imageFilter.isSelected(_imageFilter.items[idx]),
                    snapList: _imageFilter.items,
                    index: idx,
                    inSelectMode: _inSelectMode,
                    highResolution:
                        (_picsPerRow == 1 && !UIPreferences.isSmallScreen),
                    onBannerTap: (AopSnap imageFile) async {
                      if (_inSelectMode) {
                        _imageFilter.setSelected(_imageFilter.items[idx],
                            !_imageFilter.isSelected(_imageFilter.items[idx]));
                        setState(() {});
                      } else
                        try {
                          int newRanking = (imageFile.ranking! + 1) % 3 + 1;
                          imageFile.ranking = newRanking;
                          var success = await imageFile.save();
                          if (imageFile.ranking != newRanking ||
                              !(success! > 0))
                            throw "Failed to save new ranking???";
                          else
                            setState(() {});
                        } catch (ex) {
                          showMessage(context, '$ex');
                        }
                    },
                    // of bannerTap
                    onBannerLongPress: (AopSnap imageFile) async {
                      int endIndex = -1; // find where we are in the grid
                      int count = 0;
                      String progressMsg = 'Starting';
                      try {
                        for (int ix = 0;
                            ix < _imageFilter.items.length && endIndex == -1;
                            ix++) {
                          if (_imageFilter.items[ix].id == imageFile.id)
                            endIndex = ix;
                        }
                        progressMsg = 'endindex is $endIndex';
                        // now loop back selecting until start or already selected
                        if (!_imageFilter
                            .isSelected(_imageFilter.items[endIndex])) {
                          _imageFilter.setSelected(
                              _imageFilter.items[endIndex], true);
                          count++;
                        }
                        for (int ix = endIndex - 1; ix >= 0; ix--) {
                          if (_imageFilter.isSelected(_imageFilter.items[ix]))
                            break;
                          _imageFilter.setSelected(
                              _imageFilter.items[ix], true);
                          count++;
                          progressMsg = 'selecting image $ix';
                        }
                        progressMsg = 'start repaint';
                        setState(() {});
                        progressMsg = 'double-click selection $count images';
                        await showMessage(context, progressMsg);
                      } catch (ex) {
                        log.error('$ex for progress $progressMsg');
                        await showMessage(
                            context, '$ex for progress $progressMsg');
                        rethrow;
                      }
                    } // onBannerLongPress
                    ),
            ],
          ),
        ),
//        _inSelectMode ? ImageEditorWidget2(editorCallback) : Container(),
      ]), //of expanded
    ); // of column
  }

  void handleMultiCaption(BuildContext context, List<AopSnap> snaps) async {
    String? value = '';
    String errorMessage = '';
    bool done = false;
    if (snaps.isNotEmpty) // use first caption as default
      value = snaps[0].caption ?? '';
    while (!done) {
      value = await showDialog(
          context: context,
          builder: (BuildContext context) => DgSimple(
                'Caption for ${snaps.length} images',
                value,
                errorMessage: errorMessage,
              ));
      if (value == EXIT_CODE) return;
      log.message('new caption is: $value');
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
    _imageFilter.clearSelected();
    setState(() {});
  } // handleMultiCaption

  void handleMultiTakenDate(BuildContext context, List<AopSnap> snaps) async {
    String? value = '';
    String errorMessage = '';
    bool done = false;
    while (!done) {
      value = await showDialog(
          context: context,
          builder: (BuildContext context) => DgSimple(
                  'Taken Date for ${snaps.length} images', value,
                  errorMessage: errorMessage, isValid: (value) async {
                try {
                  parseDMY(value);
                  return null;
                } catch (ex) {
                  return '$ex';
                }
              }));
      if (value == EXIT_CODE) return;
      try {
        log.message('new taken date is: $value');
        DateTime newTakenDate = parseDMY(value ?? '');
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
    String? value = '';
    String errorMessage = '';
    bool done = false;
    List<String> allLocations = (await (AopSnap.distinctLocations));
    while (!done) {
      value = await showDialog(
          context: context,
          builder: (BuildContext context) => DgTypeAhead(
                  'Location for ${snaps.length} images', allLocations, value,
                  errorMessage: errorMessage, isValid: (value) async {
                try {
                  if (value.split(',').length < 3)
                    throw 'We need at least town,region,country';
                  return null;
                } catch (ex) {
                  return '$ex';
                }
              }));
      if (value == EXIT_CODE) return;
      try {
        log.message('new location is: $value');
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
    String resultMessage = '${snaps.length} snaps updated to green';
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
    log.message(resultMessage);
    showMessage(context, resultMessage);
    setState(() {});
  } // handleMultiSetGreen

  // includes album delete  --- WARNING NOT IN THE RIGHT PLACE AT ALL
  void handleMultiRemoveFromAlbum(BuildContext context, AopAlbum argAlbum,
      List<AopSnap> selectedSnaps) async {
    try {
      bool deleteAlbum = false;
      String message = '';
      if (selectedSnaps.isEmpty) return; // nothing to delete
      if ((await argAlbum.albumItems).length == selectedSnaps.length) {
        if ((await confirmYesNo(context, 'Delete this album',
            description:
                'All photos for this album have been\n selected for deletion'))!)
          deleteAlbum = true;
      }
      int count = await argAlbum.removeSnaps(selectedSnaps);
      message = "$count photos removed\n";
      if (deleteAlbum) {
        await argAlbum.delete();
        message += 'Album deleted';
        //;
        log.message('popping from grid after delete album');
        await showMessage(context, message);
        Navigator.pop(context, true);
      } else {
        await showMessage(context, message);
        if (widget._refreshNow != null) widget._refreshNow!();
        clearSelected();
        setState(() {});
      }
    } catch (ex) {
      showMessage(context, 'Error: $ex');
    }
  } // of handleMultiRemoveFromAlbum*/
}

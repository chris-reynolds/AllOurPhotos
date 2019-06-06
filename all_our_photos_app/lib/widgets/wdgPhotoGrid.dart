/*
  Created by Chris on 20th Oct 2018

  Purpose: Stateful PhotoGrid widget with multi-select
*/

import 'package:flutter/material.dart';
import '../dart_common/Logger.dart' as Log;
import '../shared/aopClasses.dart';
import '../ImageFilter.dart';
import 'wdgImageFilter.dart';
import 'ImageEditorWidget.dart';
import 'wdgPhotoTile.dart';

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

  int _picsPerRow = 4; // can be toggled
  void changePicsPerRow() {
    setState(() {
      int oldPicsPerRow = _picsPerRow;
      double oldOffset = _scrollController.offset;
      switch (_picsPerRow) {
        case 4:
          _picsPerRow = 2;
          break;
        case 2:
          _picsPerRow = 1;
          break;
        default:
          _picsPerRow = 4;
      } // of switch
      double targetOffset = oldOffset * oldPicsPerRow / _picsPerRow;
      _targetOffset = targetOffset;
 //     Log.message(
 //         '=============scroll controller offset $oldOffset to $targetOffset');
    });
  } // of changePicsPerRow

  bool _inSelectMode = false;

  void changeSelectMode() {
    setState(() {
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
      Log.message('filterRefresh triggered');
    });
  }

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
    _scrollController = ScrollController(
        initialScrollOffset: _targetOffset, keepScrollOffset: false);

    return new Scaffold(
      appBar: new AppBar(
        title: const Text('Grid list'),
        actions: <Widget>[
          new IconButton(
              icon: Icon(Icons.photo_size_select_large),
              onPressed: changePicsPerRow),
          new IconButton(icon: Icon(Icons.edit), onPressed: changeSelectMode),
        ],
      ),
      body: new Column(children: <Widget>[
        ImageFilterWidget(_imageFilter, filterRefreshCallback),
        new Expanded(
          child: new GridView.count(
            controller: _scrollController,
            crossAxisCount: _picsPerRow,
            //(orientation == Orientation.portrait) ? 4 : 6,
            mainAxisSpacing: 4.0,
            crossAxisSpacing: 4.0,

            padding: const EdgeInsets.all(4.0),
            childAspectRatio: 1.0,
            //(orientation == Orientation.portrait) ? 1.0 : 1.3,
            children: [
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
                          imageFile.ranking = (imageFile.ranking % 3) + 1;
                          imageFile.save();
                        }
                      });
                    }),

              _inSelectMode ? ImageEditorWidget2(editorCallback) : Container(),
            ],
          ),
        ),
      ]), //of expanded
    ); // of column
  }
}

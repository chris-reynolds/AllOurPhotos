/*
  Created by Chris on 20th Oct 2018

  Purpose: Stateful ImageList widget
*/


import 'package:flutter/material.dart';
import 'package:all_our_photos_app/ImageFilter.dart';
import 'package:all_our_photos_app/widgets/wdgImageFilter.dart';
import 'package:all_our_photos_app/widgets/ImageEditorWidget.dart';
import 'package:all_our_photos_app/ImgFile.dart';
import 'package:all_our_photos_app/widgets/wdgPhotoTile.dart';

class PhotoGrid extends StatefulWidget {
  final ImageFilter _initImageFilter;

  PhotoGrid(this._initImageFilter) {
    print('PhotoGrid constructor by filter');
  }

  @override
  PhotoGridState createState() => new PhotoGridState();
}

class PhotoGridState extends State<PhotoGrid> {

  ImageFilter _imageFilter;

  List<String> _selectedImages = [];
  bool isSelected(ImgFile imgFile) {
    int idx = _selectedImages.indexOf(imgFile.filename);
    return (idx>=0);
  } // of isSelected

  void toggleSelected(ImgFile imgFile) {
    int idx = _selectedImages.indexOf(imgFile.filename);
    if (idx<0)
      _selectedImages.add(imgFile.filename);
    else
      _selectedImages.removeAt(idx);
  } // of toggleSelected;

  void clearSelected() {
    _selectedImages.length = 0;
  } // clearSelected

  int _picsPerRow = 4;  // can be toggled
  void changePicsPerRow() {
    setState(() {
      switch (_picsPerRow) {
        case 4: _picsPerRow =2; break;
        case 2: _picsPerRow =1; break;
        default:_picsPerRow =4;
      } // of switch
    });
  } // of changePicsPerRow

  bool _inSelectMode = false;
  void changeSelectMode() {
    setState(() {
      _inSelectMode =  !_inSelectMode;
    });
  }
  @override
  void initState() {
    super.initState();
    _imageFilter = widget._initImageFilter;
    _imageFilter.onRefresh = filterRefreshCallback;
    print('PhotoGrid copying initFilter');
  }

  void filterRefreshCallback() {
    setState(() {
      print('filterRefresh triggered');
    });
  }

  void editorCallback(String caption,String location) {
    int updateCount = 0;
    if (caption=='' && location=='')
      return;
    setState(() {
      for (int ix = 0; ix < _imageFilter.images.length; ix++) {
        ImgFile thisImage = _imageFilter.images[ix];
        if (isSelected(thisImage)) {
          if (caption != '')
            thisImage.caption = caption;
          if (location != '')
            thisImage.location = location;
          updateCount++;
        }
      }
    });
    print('$updateCount images updated');
  } // editor Callback

  @override
  Widget build(BuildContext context) {
//    final Orientation orientation = MediaQuery.of(context).orientation;
    return new Scaffold(
      appBar: new AppBar(
        title: const Text('Grid list'),
        actions: <Widget>[
          new IconButton(icon: Icon(Icons.photo_size_select_large), onPressed: changePicsPerRow),
          new IconButton(icon: Icon(Icons.check), onPressed: changeSelectMode),
        ],
      ),
      body: new Column(
        children: <Widget>[
          ImageFilterWidget(_imageFilter,filterRefreshCallback),
          new Expanded(
            child: new GridView.count(
                crossAxisCount: _picsPerRow, //(orientation == Orientation.portrait) ? 4 : 6,
                mainAxisSpacing: 4.0,
                crossAxisSpacing: 4.0,
                padding: const EdgeInsets.all(4.0),
                childAspectRatio: 1.0, //(orientation == Orientation.portrait) ? 1.0 : 1.3,
                children: _imageFilter.images.map((ImgFile imageFile) {
                  return new PhotoTile(
                      isSelected: isSelected(imageFile),
                      imageFile: imageFile,
                      inSelectMode: _inSelectMode,
                      highResolution: (_picsPerRow == 1),
                      onBannerTap: (imageFile) {
                        setState(() {
                          if (_inSelectMode)
                            toggleSelected(imageFile);
                          else
                            imageFile.rank = (imageFile.rank % 3 )+1;
                        });
                      }
                  );
                }).toList().cast<PhotoTile>(),
              ),
          ),
          _inSelectMode ? ImageEditorWidget2(editorCallback) : Container(),
        ],
      ),
    );
  }
}

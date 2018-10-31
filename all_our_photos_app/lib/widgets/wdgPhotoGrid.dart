/*
  Created by Chris on 20th Oct 2018

  Purpose: Stateful ImageList widget
*/


import 'package:flutter/material.dart';
import 'package:all_our_photos_app/ImageFilter.dart';
import 'package:all_our_photos_app/widgets/wdgImageFilter.dart';
import 'package:all_our_photos_app/widgets/ImageEditorWidget.dart';
import 'package:all_our_photos_app/ImgFile.dart';
import 'package:all_our_photos_app/srvCatalogueLoader.dart';

typedef void BannerTapCallback(Photo photo,ImgFile imageFile);

class Photo {

  Photo.byImgFile(this._imageFile) {
    this.assetName = thumbnailURL(_imageFile);
    this.title = _imageFile.location;
    this.caption = _imageFile.rotation.toString()+'---'+_imageFile.caption;
    this.isSelected = false;
  } // byImgFile constructor

  final ImgFile _imageFile;
  String assetName;
  String assetPackage;
  String title;
  String caption;
  bool isSelected = false;
  String get tag => assetName; // Assuming that all asset names are unique.

  bool get isValid => assetName != null && title != null && caption != null;
}  // of Photo


class GridPhotoViewer extends StatefulWidget {
  const GridPhotoViewer(this.photo);
  final Photo photo;

  @override
  _GridPhotoViewerState createState() => new _GridPhotoViewerState();
}

class _GridPhotoViewerState extends State<GridPhotoViewer>  {

  @override
  Widget build(BuildContext context) {
    return new ClipRect(
          child: new Image.network(fullsizeURL(widget.photo._imageFile),
      //      package: widget.photo.assetPackage,
            fit: BoxFit.cover,
          ),
    );
  }
}

class PhotoItem extends StatelessWidget {
  PhotoItem({
    Key key,
    @required this.imageFile,
    @required this.photo,
    @required this.tileStyle,
    @required this.onBannerTap
  }) : assert(photo != null && photo.isValid),
        assert(tileStyle != null),
        assert(onBannerTap != null),
        super(key: key);
  final ImgFile imageFile;
  final Photo photo;
  final bool tileStyle;
  final BannerTapCallback onBannerTap; // User taps on the photo's header or footer.
//  final BannerTapCallback onCheckTap; // User taps on the photo's header or footer.

  void showPhoto(BuildContext context) {
    Navigator.push(context, new MaterialPageRoute<void>(
        builder: (BuildContext context) {
          return new Scaffold(
            appBar: new AppBar(
                title: new Text(photo.title)
            ),
            body: new SizedBox.expand(
              child: new Hero(
                tag: photo.tag,
                child: new GridPhotoViewer(photo),
              ),
            ),
          );
        }
    ));
  }

  @override
  Widget build(BuildContext context) {
    final Widget image = new GestureDetector(
        onTap: () { showPhoto(context); },
        child: new Hero(
            key: new Key(photo.assetName),
            tag: photo.tag,
            child: new Image.network(
              photo.assetName,
              fit: BoxFit.cover,
            )
        )
    );

    final IconData icon = Icons.star;
//    final IconData iconCut =  Icons.content_cut ;
    final IconData iconSelect = photo.isSelected ? Icons.check_box : Icons.check_box_outline_blank;

    if (tileStyle) {
      return new GridTile(
        footer: new GestureDetector(
          onTap: () {
            onBannerTap(photo,imageFile);
          },
          child: new GridTileBar(
              backgroundColor: Colors.black45,
              title: Text(photo.title),
              subtitle: Text(photo.caption),
              trailing: Row(
                  children: [
//                    new Icon(iconCut, color: Colors.white),
                    new Icon(icon, color: filterColors[photo._imageFile.rank]),
                  ])
          ),
        ),
        child: image,
      );
    } else {
        return new GridTile(
          header: new GestureDetector(
            onTap: () { onBannerTap(photo,imageFile); },
            child: new GridTileBar(
                backgroundColor: photo.isSelected ? Colors.black45 :Colors.black87,
                title: Text(photo.title),
                subtitle: Text(photo.caption),
                trailing: new Icon(iconSelect, color: Colors.white),
            ),
          ),
          child: image,
        );
    }
  }
}

/*****************************************************************
 *                     Main Entry Point
 ****************************************************************/
class GridListDemo extends StatefulWidget {
  ImageFilter _initImageFilter;

  GridListDemo();

  GridListDemo.byFilter(this._initImageFilter) {
    print('GridLIstDemo constructor by filter');
  }

  static const String routeName = '/material/grid-list';

  @override
  GridListDemoState createState() => new GridListDemoState();
}

class GridListDemoState extends State<GridListDemo> {
  bool _tileStyle = true;
  ImageFilter _imageFilter;

  void changeTileStyle(bool value) {
    setState(() {
      _tileStyle = value;
    });
  }
  void changeSelectMode() {
    setState(() {
      _tileStyle =  !_tileStyle;
    });
  }
  @override
  void initState() {
    super.initState();
    _imageFilter = widget._initImageFilter;
    _imageFilter.onRefresh = filterRefreshCallback;
    print('GridlistDemo copying initFilter');
  }

  void filterRefreshCallback() {
    setState(() {
      print('filterRefresh triggered');
    });
  }
  @override
  Widget build(BuildContext context) {
//    final Orientation orientation = MediaQuery.of(context).orientation;
    return new Scaffold(
      appBar: new AppBar(
        title: const Text('Grid list'),
        actions: <Widget>[
          new RaisedButton(onPressed: changeSelectMode,child: Text('Select'),),
        ],
      ),
      body: new Column(
        children: <Widget>[
          ImageFilterWidget(_imageFilter,filterRefreshCallback),
          new Expanded(
            child: new GridView.count(
                crossAxisCount: 4, //(orientation == Orientation.portrait) ? 4 : 6,
                mainAxisSpacing: 4.0,
                crossAxisSpacing: 4.0,
                padding: const EdgeInsets.all(4.0),
                childAspectRatio: 1.0, //(orientation == Orientation.portrait) ? 1.0 : 1.3,
                children: _imageFilter.images.map((ImgFile imageFile) {
                  return new PhotoItem(
                      photo: Photo.byImgFile(imageFile),
                      imageFile: imageFile,
                      tileStyle: _tileStyle,
                      onBannerTap: (photo,imageFile) {
                        setState(() {
                          photo.isSelected = !photo.isSelected;
                        });
                      }
                  );
                }).toList().cast<PhotoItem>(),
              ),
          ),
          ImageEditorWidget(),
        ],
      ),
    );
  }
}

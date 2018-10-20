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
//  Photo({
//    this.assetName,
//    this.assetPackage,
//    this.title,
//    this.caption,
//    this.isFavorite = false,
//  });

  Photo.byImgFile(this._imageFile) {
    this.assetName = thumbnailURL(_imageFile);
    this.title = _imageFile.location;
    this.caption = _imageFile.caption;
    this.isSelected = false;
    this.isFavorite = (_imageFile.rank==1);
  } // byImgFile constructor

  final ImgFile _imageFile;
  String assetName;
  String assetPackage;
  String title;
  String caption;
  bool isSelected = false;
  bool isFavorite;
  String get tag => assetName; // Assuming that all asset names are unique.

  bool get isValid => assetName != null && title != null && caption != null && isFavorite != null;
}

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
          child: new Image.network(widget.photo.assetName,
      //      package: widget.photo.assetPackage,
            fit: BoxFit.cover,
          ),
    );
  }
}

class GridDemoPhotoItem extends StatelessWidget {
  GridDemoPhotoItem({
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

    final IconData icon = photo.isFavorite ? Icons.star : Icons.star_border;
    final IconData iconCut =  Icons.content_cut ;
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
                    new Icon(iconCut, color: Colors.white),
                    new Icon(icon, color: Colors.white),
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
    assert(tileStyle != null);
    return null;
  }
}

/*****************************************************************
 *                     Main Entry Point
 ****************************************************************/
class GridListDemo extends StatefulWidget {
  ImageFilter _imageFilter;

  GridListDemo();

  GridListDemo.byFilter(ImageFilter initFilter) {
    print('Started by filter');
    _imageFilter = initFilter;
  }

  static const String routeName = '/material/grid-list';

  @override
  GridListDemoState createState() => new GridListDemoState();
}

class GridListDemoState extends State<GridListDemo> {
  bool _tileStyle = false;

//  List<Photo> hardPhotos = <Photo>[
//    new Photo(
//      assetName: 'http://192.168.1.251:3333/2017-01/thumbnails/DSCN4192.JPG',
//      assetPackage: _kGalleryAssetsPackage,
//      title: 'Omokoroa',
//      caption: 'Boat Club',
//    ),
//    new Photo(
//      assetName: 'http://192.168.1.251:3333/2017-01/thumbnails/DSCN4193.JPG',
//      assetPackage: _kGalleryAssetsPackage,
//      title: 'Omokoroa',
//      caption: 'Boat Club',
//    ),
//    new Photo(
//      assetName: 'http://192.168.1.251:3333/2017-01/thumbnails/DSCN4194.JPG',
//      assetPackage: _kGalleryAssetsPackage,
//      title: 'Omokoroa',
//      caption: 'Boat Club',
//    ),
//    new Photo(
//      assetName: 'http://192.168.1.251:3333/2017-01/thumbnails/DSCN4195.JPG',
//      assetPackage: _kGalleryAssetsPackage,
//      title: 'Omokoroa',
//      caption: 'Boat Club',
//    ),
//    new Photo(
//      assetName: 'http://192.168.1.251:3333/2017-01/thumbnails/DSCN4196.JPG',
//      assetPackage: _kGalleryAssetsPackage,
//      title: 'Tanjore',
//      caption: 'Thanjavur Temple',
//    ),
//    new Photo(
//      assetName: 'http://192.168.1.251:3333/2017-01/thumbnails/DSCN4197.JPG',
//      assetPackage: _kGalleryAssetsPackage,
//      title: 'Pondicherry',
//      caption: 'Salt Farm',
//    ),
//    new Photo(
//      assetName: 'http://192.168.1.251:3333/2017-01/thumbnails/DSCN4198.JPG',
//      assetPackage: _kGalleryAssetsPackage,
//      title: 'Chennai',
//      caption: 'Scooters',
//    ),
//    new Photo(
//      assetName: 'http://192.168.1.251:3333/2017-01/thumbnails/DSCN4199.JPG',
//      assetPackage: _kGalleryAssetsPackage,
//      title: 'Chettinad',
//      caption: 'Silk Maker',
//    ),
//
//  ];

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
  Widget build(BuildContext context) {
    final Orientation orientation = MediaQuery.of(context).orientation;
    return new Scaffold(
      appBar: new AppBar(
        title: const Text('Grid list'),
        actions: <Widget>[
          new RaisedButton(onPressed: changeSelectMode,child: Text('Select'),),
        ],
      ),
      body: new Column(
        children: <Widget>[
          ImageFilterWidget(widget._imageFilter),
          new Expanded(
              child: new GridView.count(
                crossAxisCount: (orientation == Orientation.portrait) ? 4 : 6,
                mainAxisSpacing: 4.0,
                crossAxisSpacing: 4.0,
                padding: const EdgeInsets.all(4.0),
                childAspectRatio: (orientation == Orientation.portrait) ? 1.0 : 1.3,
                children: widget._imageFilter.images.map((ImgFile imageFile) {
                  return new GridDemoPhotoItem(
                      photo: Photo.byImgFile(imageFile),
                      imageFile: imageFile,
                      tileStyle: _tileStyle,
                      onBannerTap: (photo,imageFile) {
                        setState(() {
                          photo.isSelected = !photo.isSelected; // TODO : Not both settings
                          photo.isFavorite = !photo.isFavorite;
                        });
                      }
                  );
                }).toList().cast<GridDemoPhotoItem>(),
              ),
            ),
          ImageEditorWidget(),
        ],
      ),
    );
  }
}

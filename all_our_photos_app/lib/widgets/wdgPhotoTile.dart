/*
  Created by Chris on 1st Nov 2018

  Purpose: PhotoTile widget is a tile of a PhotoGrid
*/

import 'package:flutter/material.dart';
import 'package:all_our_photos_app/ImgFile.dart';
import 'package:all_our_photos_app/srvCatalogueLoader.dart';
import 'package:all_our_photos_app/widgets/wdgSingleImage.dart';
import 'package:all_our_photos_app/widgets/wdgImageFilter.dart' show filterColors;



typedef void BannerTapCallback(ImgFile imageFile);


class PhotoTile extends StatelessWidget {
  PhotoTile({
    Key key,
    @required this.imageFile,
    @required this.isSelected,
    @required this.inSelectMode,
    @required this.onBannerTap
  }) : assert(isSelected != null ),
        assert(inSelectMode != null),
        assert(onBannerTap != null),
        super(key: key);
  final ImgFile imageFile;
  final bool isSelected;
  final bool inSelectMode;
  final BannerTapCallback onBannerTap; // User taps on the photo's header or footer.



  @override
  Widget build(BuildContext context) {
    final Widget imageWidget = new GestureDetector(
        onTap: () { showPhoto(context,imageFile); },
        child: new Hero(
            key: new Key(thumbnailURL(imageFile)),
            tag: imageFile.fullFilename,
            child: new Image.network(
              thumbnailURL(imageFile),
              fit: BoxFit.cover,
            )
        )
    );

    final IconData icon = Icons.star;
    final IconData iconSelect = isSelected ? Icons.check_box : Icons.check_box_outline_blank;

    if (!inSelectMode) {
      return new GridTile(
        header: new GestureDetector(
          onTap: () {
            onBannerTap(imageFile);
          },
          child: new GridTileBar(
              backgroundColor: Colors.black26,
              title: Text(imageFile.location),
              subtitle: Text(imageFile.caption),
              trailing: Row(
                  children: [
                    new Icon(icon, color: filterColors[imageFile.rank]),
                  ])
          ),
        ),
        child: imageWidget,
      );
    } else {
      return new GridTile(
        header: new GestureDetector(
          onTap: () { onBannerTap(imageFile); },
          child: new GridTileBar(
            backgroundColor: isSelected ? Colors.black45 :Colors.black26,
            title: Text(imageFile.location),
            subtitle: Text(imageFile.caption),
            trailing: new Icon(iconSelect, color: Colors.white),
          ),
        ),
        child: imageWidget,
      );
    }
  }
}
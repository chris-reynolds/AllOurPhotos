/*
  Created by Chris on 1st Nov 2018

  Purpose: PhotoTile widget is a tile of a PhotoGrid
*/

import 'package:flutter/material.dart';
import 'package:all_our_photos_app/ImgFile.dart';
import 'package:all_our_photos_app/srvCatalogueLoader.dart';
import 'package:all_our_photos_app/widgets/wdgSingleImage.dart';
import 'package:all_our_photos_app/widgets/wdgImageFilter.dart' show filterColors;
import 'package:all_our_photos_app/utils/DateUtil.dart';



typedef void BannerTapCallback(ImgFile imageFile);


class PhotoTile extends StatelessWidget {
  PhotoTile({
    Key key,
    @required this.imageFile,
    @required this.isSelected,
    @required this.inSelectMode,
    @required this.highResolution,
    @required this.onBannerTap
  }) : assert(isSelected != null ),
        assert(inSelectMode != null),
        assert(onBannerTap != null),
        super(key: key);
  final ImgFile imageFile;
  final bool isSelected;
  final bool inSelectMode;
  final bool highResolution;
  final BannerTapCallback onBannerTap; // User taps on the photo's header or footer.



  @override
  Widget build(BuildContext context) {
    final Widget imageWidget = new GestureDetector(
        onTap: () { showPhoto(context,imageFile); },
        child: new Hero(
            key: new Key(thumbnailURL(imageFile)),
            tag: imageFile.fullFilename,
            child: new Image.network(
              highResolution? fullsizeURL(imageFile) : thumbnailURL(imageFile),
              fit: BoxFit.scaleDown,
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
//              backgroundColor: Colors.black26,
              title: Text(formatDate(imageFile.takenDate,format:'mmm-yyyy'),style:TextStyle(color:Colors.black)),
              subtitle: Text(imageFile.filename,style:TextStyle(color:Colors.black)),
              trailing: Row(
                  children: [
                    new Icon(icon, color: filterColors[imageFile.rank],size:40.0),
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
//            backgroundColor: isSelected ? Colors.black45 :Colors.black26,
            title: Text(formatDate(imageFile.takenDate,format:'mmm-yyyy'),style:TextStyle(color:Colors.black)),
            subtitle: Text(imageFile.filename,style:TextStyle(color:Colors.black)),
            trailing: new Icon(iconSelect, color: Colors.black),
          ),
        ),
        child: imageWidget,
      );
    }
  }
}
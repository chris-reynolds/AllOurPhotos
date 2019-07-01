/*
  Created by Chris on 1st Nov 2018

  Purpose: PhotoTile widget is a tile of a PhotoGrid
*/

import 'package:flutter/material.dart';
import '../shared/aopClasses.dart';
import 'wdgSingleImage.dart';
import 'wdgImageFilter.dart' show filterColors;
// import '../dart_common/DateUtil.dart';



typedef void BannerTapCallback(AopSnap snap);


class PhotoTile extends StatelessWidget {
  PhotoTile({
    Key key,
    @required this.snapList,
    @required this.index,
    @required this.isSelected,
    @required this.inSelectMode,
    @required this.highResolution,
    @required this.onBannerTap
  }) : assert(isSelected != null ),
        assert(inSelectMode != null),
        assert(onBannerTap != null),
        super(key: key);
  final List<AopSnap> snapList;
  final int index;
  final bool isSelected;
  final bool inSelectMode;
  final bool highResolution;
  final BannerTapCallback onBannerTap; // User taps on the photo's header or footer.

  AopSnap get snap => snapList[index];

  @override
  Widget build(BuildContext context) {
    final Widget imageWidget = new GestureDetector(
        onTap: () { showPhoto(context,snapList,index); },
        child: new Hero(
            key: new Key(snap.thumbnailURL),
            tag: snap.fileName,
            child: new Image.network(
              highResolution? snap.fullSizeURL : snap.thumbnailURL,
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
            onBannerTap(snap);
          },
          child: new GridTileBar(
//              backgroundColor: Colors.black26,
             // title: Text(formatDate(snap.takenDate,format:'mmm-yyyy'),style:TextStyle(color:Colors.black)),
              title: Text(snap.caption,style:TextStyle(color:Colors.black)),
              subtitle: Text(snap.location??''),
              trailing: Row(
                  children: [
                    new Icon(icon, color: filterColors[snap.ranking],size:40.0),
                  ])
          ),
        ),
        child: imageWidget,
      );
    } else {
      return new GridTile(
        header: new GestureDetector(
          onTap: () { onBannerTap(snap); },
          child: new GridTileBar(
//            backgroundColor: isSelected ? Colors.black45 :Colors.black26,
            title: Text(snap.caption,style:TextStyle(color:Colors.black)),
            subtitle: Text(snap.location??''),
//            subtitle: Text(formatDate(snap.takenDate,format:'mmm-yyyy'),style:TextStyle(color:Colors.black)),
            trailing: new Icon(iconSelect, color: Colors.black),
          ),
        ),
        child: imageWidget,
      );
    }
  }
}
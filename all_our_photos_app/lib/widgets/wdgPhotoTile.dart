/*
  Created by Chris on 1st Nov 2018

  Purpose: PhotoTile widget is a tile of a PhotoGrid
*/

import 'package:flutter/material.dart';
import '../shared/aopClasses.dart';
import 'wdgImageFilter.dart' show filterColors;
import '../dart_common/DateUtil.dart';


typedef void BannerTapCallback(AopSnap snap);

const double HEADER_OFFSET = 50;
class PhotoTile extends StatelessWidget {
  PhotoTile(
      {Key key,
      @required this.snapList,
      @required this.index,
      @required this.isSelected,
      @required this.inSelectMode,
      @required this.highResolution,
      @required this.onBannerTap})
      : assert(isSelected != null),
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
    final Widget imageWidget = GestureDetector(
        onTap: () {
          if (inSelectMode)
            onBannerTap(snap);
          else
            Navigator.of(context).pushNamed('SinglePhoto',
                arguments: [snapList, index]); // weakly types params. yuk.
        },
        onLongPress: () {
          Navigator.of(context)
              .pushNamed('SinglePhoto', arguments: [snapList, index]); // weakly types params. yuk.
        },
        child: Padding(
          padding: const EdgeInsets.only(top:HEADER_OFFSET),
          child: Container(
              decoration: BoxDecoration(color: Colors.lime.shade50), //.fromRGBO(0, 0, 0, 1.0)),
              key: Key(snap.thumbnailURL),
              child: Transform.rotate(
                angle: snap.angle,
                child: Image.network(
                  highResolution ? snap.fullSizeURL : snap.thumbnailURL,
                  fit: BoxFit.scaleDown,
                ),
              )),
        ));

    final IconData icon = Icons.star;
    final IconData iconSelect = isSelected ? Icons.check_box : Icons.check_box_outline_blank;
    String descriptor =
        '${formatDate(snap.takenDate, format: 'd mmm yy')} ${snap.deviceName} ';
//    if (descriptor == null || descriptor.length == 0)
//      descriptor = '${formatDate(snap.takenDate,format:'dmmm yy')} ${snap.location??''}';
    if (!inSelectMode) {
      return new GridTile(

        header: new GestureDetector(
          onTap: () {
            onBannerTap(snap);
          },
          child: new GridTileBar(
            //backgroundColor: Colors.lime.shade50,
              title: Text(descriptor, style: TextStyle(color: Colors.black,fontFamily: 'Helvetica')),
              subtitle: Text(snap.caption?? snap.location??'', style: TextStyle(color: Colors.black,fontFamily: 'Helvetica')) ,
              trailing: Row(children: [
                new Icon(icon, color: filterColors[snap.ranking], size: 40.0),
              ])),
        ),
        child: imageWidget,
      );
    } else {
      return GridTile(
        header: new GestureDetector(
          onTap: () {
            onBannerTap(snap);
          },
          child: new GridTileBar(
       //     backgroundColor: isSelected ? Colors.lime.shade100 :Colors.lime.shade50,
            title: Text(descriptor, style: TextStyle(color: Colors.black,fontFamily: 'Helvetica')),
            subtitle: Text(snap.caption?? snap.location??'', style: TextStyle(color: Colors.black,fontFamily: 'Helvetica')) ,
//            subtitle: Text(formatDate(snap.takenDate,format:'mmm-yyyy'),style:TextStyle(color:Colors.black)),
            trailing: new Icon(iconSelect, color: Colors.black),
          ),
        ),
        child: imageWidget,
      );
    }
  }
}

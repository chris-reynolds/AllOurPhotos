/*
  Created by Chris on 1st Nov 2018

  Purpose: PhotoTile widget is a tile of a PhotoGrid
*/

import 'package:all_our_photos_app/utils/snapProvider.dart';
import 'package:flutter/material.dart';
import 'package:aopcommon/aopcommon.dart';
import 'package:aopmodel/aop_classes.dart';
import 'package:provider/provider.dart';
import 'wdgImageFilter.dart' show filterColors;

typedef BannerTapCallback = void Function(AopSnap snap);
nullSnapCallBack(AopSnap snap) {} // used for initialising callbacks

const double HEADER_OFFSET = 50;

class PhotoTile extends StatefulWidget {
  const PhotoTile(
      {super.key,
      required this.snapList,
      required this.index,
      this.isSelected = false,
      this.inSelectMode = false,
      this.highResolution = false,
      required this.onBannerTap,
      required this.onBannerLongPress});
  final List<AopSnap> snapList;
  final int index;
  final bool isSelected;
  final bool inSelectMode;
  final bool highResolution;
  final BannerTapCallback
      onBannerTap; // User taps on the photo's header or footer.
  final BannerTapCallback onBannerLongPress;
  @override
  State<PhotoTile> createState() => _PhotoTileState();
}

class _PhotoTileState extends State<PhotoTile> {
  AopSnap get snap => widget.snapList[widget.index];

  @override
  Widget build(BuildContext context) {
    final Widget imageWidget = GestureDetector(
        onTap: () async {
          if (widget.inSelectMode) {
            widget.onBannerTap(snap);
            setState(() {});
          } else {
            await Navigator.pushNamed(context, 'SinglePhoto', arguments: [
              widget.snapList,
              widget.index
            ]); // weakly types params. yuk.
          }
        },
        onDoubleTap: () {
          if (widget.inSelectMode) widget.onBannerLongPress(snap);
        },
        onLongPress: () async {
          await Navigator.pushNamed(context, 'SinglePhoto', arguments: [
            widget.snapList,
            widget.index
          ]); // weakly types params. yuk.
        },
        child: Padding(
          padding: const EdgeInsets.only(top: HEADER_OFFSET),
          child: Container(
              decoration: BoxDecoration(
                  color: Colors.lime.shade50), //.fromRGBO(0, 0, 0, 1.0)),
              key: Key(snap.thumbnailURL),
//              child: Transform.rotate(
//                angle: 0, //-snap.angle,
              child: Image.network(
                widget.highResolution ? snap.fullSizeURL : snap.thumbnailURL,
                fit: BoxFit.scaleDown,
//                ),
              )),
        ));

    const IconData icon = Icons.star;
    final IconData iconSelect =
        widget.isSelected ? Icons.check_box : Icons.check_box_outline_blank;
    String descriptor =
        '${formatDate(snap.takenDate!, format: 'd mmm yy')} ${snap.deviceName} ';
    if (!widget.inSelectMode) {
      return ChangeNotifierProvider(
        create: (context) => SnapProvider(snap),
        child: GridTile(
          header: GestureDetector(
            onTap: () {
              widget.onBannerTap(snap);
            },
            child: GridTileBar(
                title: Text(descriptor,
                    style: TextStyle(
                        color: Colors.black, fontFamily: 'Helvetica')),
                subtitle: Text(snap.caption ?? snap.location ?? '',
                    style: TextStyle(
                        color: Colors.black, fontFamily: 'Helvetica')),
                trailing: Row(children: [
                  Icon(icon, color: filterColors[snap.ranking!], size: 40.0),
                ])),
          ),
          child: imageWidget,
        ),
      );
    } else {
      return GridTile(
        header: GestureDetector(
          onTap: () {
            widget.onBannerTap(snap);
          },
          onDoubleTap: () {
            widget.onBannerLongPress(snap);
          },
          child: GridTileBar(
            title: Text(descriptor,
                style: TextStyle(color: Colors.black, fontFamily: 'Helvetica')),
            subtitle: Text(snap.caption ?? snap.location ?? '',
                style: TextStyle(color: Colors.black, fontFamily: 'Helvetica')),
//            subtitle: Text(formatDate(snap.takenDate,format:'mmm-yyyy'),style:TextStyle(color:Colors.black)),
            trailing: Icon(iconSelect, color: Colors.black),
          ),
        ),
        child: imageWidget,
      );
    }
  }
}

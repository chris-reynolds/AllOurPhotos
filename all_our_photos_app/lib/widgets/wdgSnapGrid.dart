/*
  Created by chrisreynolds on 2019-05-31
  
  Purpose: The purpose of this is to allow you to show a list of snaps

*/

import 'package:all_our_photos_app/flutter_common/WidgetSupport.dart';
import 'package:flutter/material.dart';
import 'package:aopcommon/aopcommon.dart';
import 'package:aopmodel/aop_classes.dart';
//import 'package:provider/provider.dart';
//import '../providers/snapProvider.dart';

class SsSnapGrid extends StatelessWidget {
  final List<AopSnap> snapList;
  final dynamic parentGrid;
  const SsSnapGrid(this.snapList, this.parentGrid, {super.key});

  Widget snapTile(BuildContext context, int index) {
    AopSnap snap = snapList[index];
    return Stack(children: [
      GestureDetector(
          onTap: () {
            Navigator.of(context).pushNamed('SinglePhoto',
                arguments: [snapList, index]); // weakly types params. yuk.
          },
          child: Hero(
              key: Key(snap.thumbnailURL),
              tag: snap.fileName!,
              child: Transform.rotate(
                angle: snap.angle,
                child: Image.network(
                  snap.thumbnailURL,
                  fit: BoxFit.scaleDown,
                ),
              ))),
      Checkbox(
        value: parentGrid.isSelected(snap.id),
        onChanged: (value) {
          parentGrid.setSelected(snap.id, value);
          parentGrid.setState(() {});
        },
      ), // of checkbox
      //),
    ]);
  } // of snapTile

  @override
  Widget build(BuildContext context) {
    //snapProvider = context.read<SnapProvider>();

    assert(parentGrid is Selection<int>);

    if (snapList.isEmpty)
      return Container();
    else
      return GridView.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: UIPreferences.isSmallScreen ? 1 : 2,
            mainAxisSpacing: 3.0,
            crossAxisSpacing: 3.0,
            childAspectRatio: 1.33),
        itemCount: snapList.length,
        itemBuilder: snapTile,
      );
  }
} // of ssSnapGrid

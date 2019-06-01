/*
  Created by chrisreynolds on 2019-05-31
  
  Purpose: The purpose of this is to allow you to show a list of snaps

*/

import 'package:flutter/material.dart';
import '../shared/aopClasses.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import '../dart_common/ListUtils.dart';

Widget snapGrid(
    BuildContext context, List<AopSnap> snapList, dynamic parentGrid) {
  assert(parentGrid is Selection<int>);
  Widget snapTile(BuildContext context, int index) {
    AopSnap snap = snapList[index];
    return Stack(children: [
      Image.network(snap.thumbnailURL),
      Checkbox(
        value: parentGrid.isSelected(snap.id),
        onChanged: (value) {
          parentGrid.setSelected(snap.id, value);
          parentGrid.setState(() {});
        },
      ), // of checkbox
      //title: Text('${snap.caption}'),
      //),
    ]);
  } // of snapTile

  if (snapList == null)
    return Container();
  else
    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 3.0,
          crossAxisSpacing: 3.0,
          childAspectRatio: 1.33),
      itemCount: snapList.length,
      itemBuilder: snapTile,
    );
}
class SsSnapGrid extends StatelessWidget {
  List<AopSnap> snapList;
  dynamic parentGrid;
  SsSnapGrid(this.snapList,this.parentGrid);

  @override
  Widget build(BuildContext context) {
    assert(parentGrid is Selection<int>);
    Widget snapTile(BuildContext context, int index) {
      AopSnap snap = snapList[index];
      return Stack(children: [
        Image.network(snap.thumbnailURL),
        Checkbox(
          value: parentGrid.isSelected(snap.id),
          onChanged: (value) {
            parentGrid.setSelected(snap.id, value);
            parentGrid.setState(() {});
          },
        ), // of checkbox
        //title: Text('${snap.caption}'),
        //),
      ]);
    } // of snapTile

    if (snapList == null)
      return Container();
    else
      return GridView.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 3.0,
            crossAxisSpacing: 3.0,
            childAspectRatio: 1.33),
        itemCount: snapList.length,
        itemBuilder: snapTile,
      );
  }
} // of ssSnapGrid


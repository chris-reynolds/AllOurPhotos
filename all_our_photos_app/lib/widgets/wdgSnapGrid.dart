/*
  Created by chrisreynolds on 2019-05-31
  
  Purpose: The purpose of this is to allow you to show a list of snaps

*/

import 'package:flutter/material.dart';
import '../shared/aopClasses.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import '../dart_common/ListUtils.dart';


Widget snapGrid(BuildContext context, List<AopSnap> snapList) {
  if (snapList == null)
    return Container();
  else
    return StaggeredGridView.countBuilder(
        crossAxisCount: 8,
        itemCount: snapList.length,
        itemBuilder: (BuildContext context, int index) =>
        new Container(
          color: Colors.green,
          child: Image.network(snapList[index].thumbnailURL),
//            child: new Center(
//              child: new CircleAvatar(
//                backgroundColor: Colors.red,
//                child: new Text('$index'),
//              ),
        )
  ,
  staggeredTileBuilder: (int index) =>
  new StaggeredTile.count(4, index.isEven ? 3: 4),
  mainAxisSpacing: 4.0,
  crossAxisSpacing: 4.0,
  );
}

//Widget snapTile(AopSnap snap) {
//  return Column(children: [
//    ListTile(
//      leading: Checkbox(
//        value: isSelected(snap.id),
//        onChanged: (value) {
//          setSelected(snap.id, value);
//          setState(() {});
//        },
//      ), // of checkbox
//      title: Text('${snap.caption}'),
//    ),
//    Image.network(snap.thumbnailURL),
//  ]);
//} // of snapTile

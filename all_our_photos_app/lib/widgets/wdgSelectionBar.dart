/*
  Created by chrisreynolds on 2019-05-31
  
  Purpose: This is used to encapsulate the AppBar during a selection process

*/
import 'package:flutter/material.dart';
import '../dart_common/ListUtils.dart';

class SelectionBar extends StatelessWidget {
  final Selection parentGrid;
  final Function onAccept;
  // we can only use this common for a widget that uses the Selection mixin
  SelectionBar(this.parentGrid,{@required this.onAccept});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      actions: <Widget>[
        Text('${parentGrid.selectionList.length} items selected'),
        IconButton(icon:Icon(Icons.check),onPressed: (){}),
        IconButton(icon:Icon(Icons.close),onPressed: (){
          parentGrid.clearSelected();}),
      ],
    ); // of row
  }
}



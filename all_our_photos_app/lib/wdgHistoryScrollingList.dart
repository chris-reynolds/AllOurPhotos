import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class HistoryScrollingList extends StatelessWidget {
  HistoryScrollingList(this.listType);
  final String listType;
  @override
  Widget build(BuildContext context) {
    return new Center(
        child: new Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            new Text(
              listType,
              style: Theme.of(context).textTheme.display1,
            ),
          ],
        ),
    );
  }
}
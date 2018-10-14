import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class Testing extends StatelessWidget {
  Testing(this.listType);
  final String listType;
  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      body: new Center(
        child: new Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            new Text(
              listType,
              style: Theme.of(context).textTheme.display1,
            ),
          ],
        ),
      ),
    );
  }
}
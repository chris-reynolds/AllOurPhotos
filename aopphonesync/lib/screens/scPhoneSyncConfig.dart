/*
  Created by chrisreynolds on 2019-09-23
  
  Purpose: Stateful PhoneSyncConfigWidget
*/


import 'package:flutter/material.dart';


class PhoneSyncConfigWidget extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return new PhoneSyncConfigWidgetState();
  }
}

class PhoneSyncConfigWidgetState extends State<PhoneSyncConfigWidget> {
  @override
  Widget build(BuildContext context) {
    return new Center(
      child: new Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          new Text(
            'NEW WIDGET - Todo',
            style: Theme
                .of(context)
                .textTheme
                .display1,
          ),
        ],
      ),
    );
  }
}
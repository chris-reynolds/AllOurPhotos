/*
  Created by chrisreynolds on 2019-05-27
  
  Purpose: This allows you to control which months are selected in a year

*/

import 'package:flutter/material.dart';

typedef QuarterCallback = void Function(int);

class MonthSelector extends StatefulWidget {
  final QuarterCallback onPressed;

  MonthSelector({@required this.onPressed});

  @override
  _MonthSelectorState createState() => _MonthSelectorState();
}

class _MonthSelectorState extends State<MonthSelector> {
  List<bool> _monthList = [true, false, false, false];
//  bool _multiMonth = true;
  List<String> _monthNames = 'Jan-Mar Apr-Jun Jul-Sep Oct-Dec'.split(' ');

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        for (int i = 0; i < 4; i++)
          FlatButton(
              padding: EdgeInsets.all(0),
              child: Text(_monthNames[i]),
              onPressed: () {
                setState(() {
                  for (int j = 0; j < 4; j++) _monthList[j] = (j == i);
                });
                if (widget.onPressed != null)
                  widget.onPressed(i);
              },
              color: _monthList[i] ? Colors.greenAccent : Colors.amber),
      ], // of children
    ); // of Row
  } // of build
} // of _MonthSelectorState

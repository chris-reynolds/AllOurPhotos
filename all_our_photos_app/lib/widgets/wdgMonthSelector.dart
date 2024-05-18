/*
  Created by chrisreynolds on 2019-05-27
  
  Purpose: This allows you to control which months are selected in a year

*/

import 'package:flutter/material.dart';

typedef QuarterCallback = void Function(int);

class MonthSelector extends StatefulWidget {
  final QuarterCallback onPressed;

  const MonthSelector({super.key, required this.onPressed});

  @override
  MonthSelectorState createState() => MonthSelectorState();
}

class MonthSelectorState extends State<MonthSelector> {
  final List<bool> _monthList = [true, false, false, false];
  final List<String> _monthNames = 'Jan-Mar Apr-Jun Jul-Sep Oct-Dec'.split(' ');

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        for (int i = 0; i < 4; i++)
          TextButton(
              //padding: EdgeInsets.all(0),
              onPressed: () {
                setState(() {
                  for (int j = 0; j < 4; j++) _monthList[j] = (j == i);
                });
                //               if (widget.onPressed != null)
                widget.onPressed(i);
              },
              style: TextButton.styleFrom(
                  backgroundColor:
                      _monthList[i] ? Colors.greenAccent : Colors.amber),
              //padding: EdgeInsets.all(0),
              child: Text(_monthNames[i]))
      ], // of children
    ); // of Row
  } // of build
} // of _MonthSelectorState

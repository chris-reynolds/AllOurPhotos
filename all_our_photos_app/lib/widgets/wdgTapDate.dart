/*
  Created by chrisreynolds on 27/10/18
  
  Purpose: Stateful TapDateWidget
*/


import 'package:flutter/material.dart';

import 'package:all_our_photos_app/utils.dart' as Utils;

typedef DateChangedEvent = Function(DateTime);

class TapDateWidget extends StatefulWidget {
  DateTime _date;
  DateChangedEvent _onChange;
  TapDateWidget(this._date, this._onChange);

  @override
  State<StatefulWidget> createState() {
    return new TapDateWidgetState();
  }
}

class TapDateWidgetState extends State<TapDateWidget> {

  Future<Null> popupDatePicker(BuildContext context)  async {
    final _selectedDate = await showDatePicker(
      context: context, initialDate: widget._date,
        firstDate: DateTime(1900), lastDate: DateTime.now() );
    if (_selectedDate != null && _selectedDate != widget._date) {
      setState( () {
        widget._date = _selectedDate;
        widget._onChange(_selectedDate);
      }); // of setState
    }
  }
  @override
  Widget build(BuildContext context) {
    return new FlatButton(
      child: Text('(${Utils.formatDate(widget._date,format:'d-mmm-yy')})',
      // TODO : work out how to decorate theme styles with underscore
      style: Theme.of(context).textTheme.body2.apply(decoration: TextDecoration.underline)),
      onPressed: () { popupDatePicker(context); },
    );
  } // of build
} // of TapDateWidgetState
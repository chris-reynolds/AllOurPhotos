/*
  Created by chrisreynolds on 27/10/18
  
  Purpose: Stateful TapDateWidget
*/


import 'package:flutter/material.dart';

import '../dart_common/DateUtil.dart' as Utils;

typedef DateChangedEvent = Function(DateTime);

class TapDateWidget extends StatefulWidget {
  final DateTime _initDate;
  final DateChangedEvent _onChange;
  TapDateWidget(this._initDate, this._onChange);

  @override
  State<StatefulWidget> createState() {
    return new TapDateWidgetState();
  }
}

class TapDateWidgetState extends State<TapDateWidget> {

  DateTime _date;

  Future<Null> popupDatePicker(BuildContext context)  async {
    final _selectedDate = await showDatePicker(
      context: context, initialDate: _date,
        firstDate: DateTime(1900), lastDate: DateTime.now() );
    if (_selectedDate != null && _selectedDate != _date) {
      setState( () {
        _date = _selectedDate;
        widget._onChange(_selectedDate);
      }); // of setState
    }
  }


  @override
  void initState() {
    super.initState();
    _date = widget._initDate;
  }

  @override
  Widget build(BuildContext context) {
    return new TextButton(
      child: Text('(${Utils.formatDate(_date,format:'d-mmm-yy')})',
      // TODO : work out how to decorate theme styles with underscore
      style: Theme.of(context).textTheme.bodyText2.apply(decoration: TextDecoration.underline)),
      onPressed: () { popupDatePicker(context); },
    );
  } // of build
} // of TapDateWidgetState
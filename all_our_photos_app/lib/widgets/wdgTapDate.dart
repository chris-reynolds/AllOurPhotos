/*
  Created by chrisreynolds on 27/10/18
  
  Purpose: Stateful TapDateWidget
*/


import 'package:flutter/material.dart';
import 'package:aopcommon/aopcommon.dart';

typedef DateChangedEvent = Function(DateTime);

class TapDateWidget extends StatefulWidget {
  final DateTime _initDate;
  final DateChangedEvent _onChange;
  const TapDateWidget(this._initDate, this._onChange);

  @override
  State<StatefulWidget> createState() {
    return TapDateWidgetState();
  }
}

class TapDateWidgetState extends State<TapDateWidget> {

  DateTime _date;

  Future<void> popupDatePicker(BuildContext context)  async {
    final selectedDate = await showDatePicker(
      context: context, initialDate: _date,
        firstDate: DateTime(1900), lastDate: DateTime.now() );
    if (selectedDate != null && selectedDate != _date) {
      setState( () {
        _date = selectedDate;
        widget._onChange(selectedDate);
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
    return TextButton(
      child: Text('(${formatDate(_date,format:'d-mmm-yy')})',
      // TODO : work out how to decorate theme styles with underscore
      style: Theme.of(context).textTheme.bodyMedium.apply(decoration: TextDecoration.underline)),
      onPressed: () { popupDatePicker(context); },
    );
  } // of build
} // of TapDateWidgetState
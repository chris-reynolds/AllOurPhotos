/*Created by chris reynolds on 2019-08-22

Purpose: This is a popup dialog that will allow the user to select a value from a list

*/
import 'package:flutter/material.dart';
import 'package:autocomplete_textfield/autocomplete_textfield.dart';
import '../dart_common/Logger.dart' as Log;
import '../widgets/TypeAheadTextField.dart';
import 'scSimpleDlg.dart';

class DgTypeAhead extends StatefulWidget {
  final String initialValue;
  final String title;
  final String errorMessage;
  final List<String> options;
  final DlgValidator isValid;

  @override
  _DgTypeAheadState createState() => _DgTypeAheadState(title, this.options, initialValue, this.errorMessage);

  DgTypeAhead(this.title, this.options, this.initialValue, {this.errorMessage:'', this.isValid})
      : super();
}

class _DgTypeAheadState extends State<DgTypeAhead> {
  TextEditingController _nameController;
  String value;
  String title;
  List<String> options;
  String errorMessage;
  GlobalKey<AutoCompleteTextFieldState<String>> textKey = GlobalKey();

  _DgTypeAheadState(this.title, this.options, this.value, this.errorMessage) : super();

  void handleSavePressed(String value) async {
    if (widget.isValid != null)
      errorMessage = await widget.isValid(_nameController.text);
    else
      errorMessage = null;
    if (value != EXIT_CODE && errorMessage !=null && errorMessage.length > 0)
      setState(() {});
    else
      Navigator.pop(context, value);
  } // of handleSavePressed

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _nameController.text = value;
  } // of initState

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SimpleDialog(
      contentPadding: EdgeInsets.all(20),
      titlePadding: EdgeInsets.all(20),
      title: Row(
        children: [
          Text(title),
          Spacer(),
          IconButton(
              icon: Icon(Icons.save),
              onPressed: () {
                handleSavePressed(_nameController.text);
              }),
          IconButton(
              icon: Icon(Icons.close),
              onPressed: () {
                _nameController.text = '';
                handleSavePressed(EXIT_CODE);
              }),
        ],
      ),
      children: <Widget>[
        TypeAheadTextField(
          key: textKey,
          decoration: new InputDecoration(labelText: 'Location Lookup', errorText: ''),
          controller: _nameController,
          //TextEditingController(text: ""),
          suggestions: options,
          textChanged: (text) => value = text,
          clearOnSubmit: false,
          textSubmitted: (text) =>
              setState(() {
                if (text != "") {
//                  locationTextController.text = text;
                  value = text;
                  Log.message('typeahead value ==== $text');
                }
              }),
        ),

      ],
    );
  } // of build
}



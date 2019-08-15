/*Created by chris reynolds on 2019-05-22

Purpose: This is a popup dialog that will allow the user to enter the name of a new album

*/
import 'package:flutter/material.dart';

typedef DlgValidator = Future<String> Function(String);

const String EXIT_CODE = 'XXCLOSEXX';

class DgSimple extends StatefulWidget {
  final String initialValue;
  final String title;
  final String errorMessage;
  final DlgValidator isValid;

  @override
  _DgSimpleState createState() => _DgSimpleState(title, initialValue, this.errorMessage);

  DgSimple(this.title, this.initialValue, {this.errorMessage:'', this.isValid})
      : super();
}

class _DgSimpleState extends State<DgSimple> {
  TextEditingController _nameController;
  String value;
  String title;
  String errorMessage;

  _DgSimpleState(this.title, this.value, this.errorMessage) : super();

  void handleSavePressed(String value) async {
    if (widget.isValid != null)
      errorMessage = await widget.isValid(_nameController.text);
    else
      errorMessage = null;
    if (errorMessage !=null && errorMessage.length > 0)
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
              icon: Icon(Icons.close),
              onPressed: () {
                _nameController.text = '';
                handleSavePressed(EXIT_CODE);
              })
        ],
      ),
      children: <Widget>[
        TextField(
          controller: _nameController,
          autofocus: true,
//          onEditingComplete: (value){return (value.length<10)?"Must be at least10 characters":null;},
          onSubmitted: handleSavePressed,
        ),
        Text(
          errorMessage,
          style: Theme.of(context).textTheme.body2,
          maxLines: 3,
        ),
      ],
    );
  } // of build
}

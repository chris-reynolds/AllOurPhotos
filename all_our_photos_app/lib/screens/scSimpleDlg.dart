/*Created by chris reynolds on 2019-05-22

Purpose: This is a popup dialog that will allow the user to enter the name of a new album

*/
import 'package:flutter/material.dart';

typedef DlgValidator = Future<String?> Function(String);

const String EXIT_CODE = 'XXCLOSEXX';

class DgSimple extends StatefulWidget {
  final String? initialValue;
  final String errorMessage;
  final String title;
  final DlgValidator? isValid;

  @override
  DgSimpleState createState() => DgSimpleState();

  const DgSimple(this.title, this.initialValue,
      {this.errorMessage = '', this.isValid})
      : super();
}

class DgSimpleState extends State<DgSimple> {
  final TextEditingController _nameController = TextEditingController();

  String value = '';
  String localErrorMessage = '';

  void handleSavePressed(String value) async {
    if (widget.isValid != null)
      localErrorMessage = (await widget.isValid!(_nameController.text)) ?? '';
    if (localErrorMessage.isNotEmpty)
      setState(() {});
    else
      Navigator.pop(context, value);
  } // of handleSavePressed

  @override
  void initState() {
    super.initState();
    localErrorMessage = widget.errorMessage;
    _nameController.text = widget.initialValue ?? '';
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
          Text(widget.title),
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
          localErrorMessage,
          style: Theme.of(context).textTheme.bodyMedium,
          maxLines: 3,
        ),
      ],
    );
  } // of build
}

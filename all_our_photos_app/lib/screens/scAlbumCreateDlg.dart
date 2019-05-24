/*Created by chris reynolds on 2019-05-22

Purpose: This is a popup dialog that will allow the user to enter the name of a new album

*/
import 'package:flutter/material.dart';

class DgAlbumCreate extends StatefulWidget {
  String name;
  String errorMessage;
  @override
  _DgAlbumCreateState createState() => _DgAlbumCreateState();

  DgAlbumCreate(this.name, this.errorMessage):super();
}

class _DgAlbumCreateState extends State<DgAlbumCreate> {
  TextEditingController _nameController = TextEditingController();

  void handleSavePressed(String value) {
    Navigator.pop(context,_nameController.text);
  } // of handleSavePressed

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.name;
  } // of initState

  @override
  Widget build(BuildContext context) {
    return SimpleDialog(
      contentPadding: EdgeInsets.all(20),
      titlePadding: EdgeInsets.all(20),
      title: Text('New album'),
      children: <Widget>[
        TextField(
          controller: _nameController,
          autofocus: true,
          onSubmitted: handleSavePressed,
        ),
        Text(widget.errorMessage,style: Theme.of(context).textTheme.body2,
          maxLines: 3,),
      ],
    );
  } // of build
}

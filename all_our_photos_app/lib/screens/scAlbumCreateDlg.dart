/*Created by chris reynolds on 2019-05-22

Purpose: This is a popup dialog that will allow the user to enter the name of a new album

*/
import 'package:flutter/material.dart';

const String EXIT_CODE = 'XXCLOSEXX';
class DgAlbumCreate extends StatefulWidget {
  final String name;
  final String errorMessage;
  @override
  _DgAlbumCreateState createState() => _DgAlbumCreateState();

  DgAlbumCreate(this.name, this.errorMessage):super();
}

class _DgAlbumCreateState extends State<DgAlbumCreate> {
  TextEditingController _nameController = TextEditingController();

  void handleSavePressed(String value) {
    Navigator.pop(context,value);
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
      title: Row(
        children:[Text('Album name'),
          Spacer(),
          IconButton(icon: Icon(Icons.close), onPressed: (){
            handleSavePressed(EXIT_CODE);
          })
        ],
      ),
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

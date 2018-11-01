/*
  Created by Chris on 18th Oct 2018
  
  Purpose: Stateful ImageEditorWidget widget
*/


import 'package:flutter/material.dart';

class ImageEditorWidget extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return new ImageEditorWidgetState();
  }
}

class ImageEditorWidgetState extends State<ImageEditorWidget> {
  @override
  Widget build(BuildContext context) {
    return new Center(
      child: new Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
//          new ImageFilterWidget(widget._imageFilter),
          new Text(
            'Image editor Panel',
            style: Theme.of(context).textTheme.display1,
          ),
        ],
      ),
    );
  }
}

typedef EditorCallback = Function(String caption,String location);
class ImageEditorWidget2 extends StatelessWidget {

  TextEditingController _captionController = TextEditingController();
  TextEditingController _locationController = TextEditingController();
  EditorCallback _editorCallback;

  ImageEditorWidget2(this._editorCallback);

  void _onUpdate() {
    print('TODO: ImageEditorWidget2.onUpdate()');
    _editorCallback(_captionController.text,_locationController.text);
  } // onUpdate

  @override
  Widget build(BuildContext context) {
    return Row(
       mainAxisAlignment: MainAxisAlignment.start,
      children: <Widget>[
        new Flexible(
          child: new TextField(
          controller: _captionController,
            decoration: const InputDecoration(helperText: "Enter Caption"),
            style: Theme.of(context).textTheme.body2,
          ),
        ),
        new Flexible(
          child: new TextField(
            controller: _locationController,
            decoration: const InputDecoration(helperText: "Enter Location"),
            style: Theme.of(context).textTheme.body2,
          ),
        ),
//        Expanded(child:Container()),
        IconButton(
          icon: Icon(Icons.update),
          onPressed: _onUpdate,
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import '../dart_common/Logger.dart' as Log;
import '../shared/aopClasses.dart';

void showPhoto(BuildContext context, List<AopSnap> snapList, int index) {
  AopSnap snap = snapList[index];
  Navigator.push(context,
      new MaterialPageRoute<void>(builder: (BuildContext context) {
    return new Scaffold(
      appBar: new AppBar(
        title: new Text(snap.fileName + ' ' + snap.caption),
        actions: <Widget>[
          IconButton(icon: Icon(Icons.edit), onPressed: () {}),
          IconButton(icon: Icon(Icons.crop), onPressed: () {}),
          IconButton(icon: Icon(Icons.palette), onPressed: () {}),
          PopupMenuButton<String>(
            onSelected: (String result) {
              Log.message('menu item selected - $result');
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                  const PopupMenuItem<String>(
                    value: 'harder',
                    child: Text('Working a lot harder'),
                  ),
                  const PopupMenuItem<String>(
                    value: 'smarter',
                    child: Text('Being a lot smarter'),
                  ),
                  const PopupMenuItem<String>(
                    value: 'selfStarter',
                    child: Text('Being a self-starter'),
                  ),
                  const PopupMenuItem<String>(
                    value: 'tradingCharter',
                    child: Text('Placed in charge of trading charter'),
                  ),
                ],
          ),
        ], // of actions
      ), // of appBar
      body: new SizedBox.expand(
        child: new Hero(
          tag: snap.fileName,
          child: new SingleImageWidget(snap),
        ),
      ),
    );
  }));
}

class SingleImageWidget extends StatefulWidget {
  const SingleImageWidget(this._snap);

  final AopSnap _snap;

  @override
  _SingleImageWidgetState createState() => new _SingleImageWidgetState();
}

class _SingleImageWidgetState extends State<SingleImageWidget> {
  @override
  Widget build(BuildContext context) {
    return new ClipRect(
      child: new Image.network(
        widget._snap.fullSizeURL,
        fit: BoxFit.scaleDown,

      ),
    );
  }
}

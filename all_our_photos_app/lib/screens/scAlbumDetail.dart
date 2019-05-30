/*Created by chrisreynolds on 2019-05-24

Purpose: This will show the details of a single album

*/
import 'package:flutter/material.dart';
import '../shared/aopClasses.dart';
import '../dart_common/Logger.dart' as Log;

class AlbumDetail extends StatefulWidget {
  @override
  _AlbumDetailState createState() => _AlbumDetailState();
}

class _AlbumDetailState extends State<AlbumDetail> {
  final key = new GlobalKey<ScaffoldState>();
  AopAlbum argAlbum;
  List<AopSnap> _list;
  List<int> _selectedItemIds = [];

  bool isSelected(int snapId) {
    return _selectedItemIds.indexOf(snapId) >= 0;
  }

  void toggleSelected(int snapId) {
    if (snapId==0)  // flush selected
      _selectedItemIds = [];
    else if (isSelected(snapId))
      _selectedItemIds.remove(snapId);
    else
      _selectedItemIds.add(snapId);
    setState(() {

    });
  } // of toggleSelected

  @override
  Widget build(BuildContext context) {
    if (argAlbum == null)
      return Text('Loading...');
    else
      return new Scaffold(
        key: key,
        appBar: buildBar(context),
        body: new ListView(
          padding: new EdgeInsets.symmetric(vertical: 8.0),
          children: _buildList(),
        ),
        floatingActionButton: FloatingActionButton(
            child: Icon(Icons.add_a_photo),
            onPressed: () => handleAddAlbumItem(context)),
      );
  } // of build

  Widget buildBar(BuildContext context) {
    if (_selectedItemIds.length==0)
    return new AppBar(
        centerTitle: true,
        title: Text('${argAlbum.name}'),
        actions: <Widget>[
          new IconButton(
            icon: Icon(Icons.save),
            onPressed: () {
              setState(() {
//            if (this.actionIcon.icon == Icons.search) {
//              this.actionIcon = new Icon(
//                Icons.close,
//                color: Colors.white,
//              );
//              this.appBarTitle = new TextField(
//                controller: _searchQuery,
//                style: new TextStyle(
//                  color: Colors.white,
//                ),
//                decoration: new InputDecoration(
//                    prefixIcon: new Icon(Icons.search, color: Colors.white),
//                    hintText: "Search...",
//                    hintStyle: new TextStyle(color: Colors.white)),
//              );
//              _handleSearchStart();
//            } else {
//              _handleSearchEnd();
//            }
              });
            },
          ),
        ]);
    else return AppBar(
       title: Text('${_selectedItemIds.length} items selected'),
      actions: <Widget>[
        IconButton(icon:Icon(Icons.redo),onPressed: (){}),
        IconButton(icon:Icon(Icons.delete),onPressed: (){}),
        IconButton(icon:Icon(Icons.close),onPressed: (){toggleSelected(0);}),
      ],
    );
  }

  List<Widget> _buildList() {
    if (_list == null)
      return [];
    else
      return _list
          .map((snap) => snapTile(snap))
          .toList();
  } // buildList

  @override
  void didChangeDependencies() {
    argAlbum = ModalRoute.of(context).settings.arguments;
    refreshList();
  } // of didChangeDependencies

  void handleAddAlbumItem(BuildContext context) {
    Navigator.pushNamed(context, 'AlbumItemCreate', arguments: argAlbum);
  } // of handleAddAlbumItem

  void handleDelete() async {
    // todo : await sho
  }  // of handleDelete

  @override
  void initState() {
    super.initState();
  }

  void refreshList() {
    argAlbum.snaps.then((newList) {
      setState(() {
        _list = newList;
        Log.message('${_list.length} album items loaded');
      });
    });
  } // of refreshList

  Widget snapTile(AopSnap snap) {
    return Column(
        children:[ListTile(
      leading: Checkbox(value: isSelected(snap.id), onChanged: (v)=>toggleSelected(snap.id)),
      title: Text('${snap.caption}')),
          Image.network(snap.fullSizeURL),
           ]);
  } // of snapTile
}

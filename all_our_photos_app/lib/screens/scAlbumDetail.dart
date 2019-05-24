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
  List<AopAlbumItem> _list;
  List<int> _selectedItemIds = [];

  @override
  Widget build(BuildContext context) {

    return new Scaffold(
      key: key,
      appBar: buildBar(context),
      body: new ListView(
        padding: new EdgeInsets.symmetric(vertical: 8.0),
        children: _buildList(),
      ),
      floatingActionButton: FloatingActionButton(
          child: Icon(Icons.add_a_photo), onPressed: ()=> handleAddAlbumItem(context)),
    );
  }  // of build

  Widget buildBar(BuildContext context) {
    return new AppBar(centerTitle: true, title: appBarTitle, actions: <Widget>[
      new IconButton(
        icon: actionIcon,
        onPressed: () {
          setState(() {
            if (this.actionIcon.icon == Icons.search) {
              this.actionIcon = new Icon(
                Icons.close,
                color: Colors.white,
              );
              this.appBarTitle = new TextField(
                controller: _searchQuery,
                style: new TextStyle(
                  color: Colors.white,
                ),
                decoration: new InputDecoration(
                    prefixIcon: new Icon(Icons.search, color: Colors.white),
                    hintText: "Search...",
                    hintStyle: new TextStyle(color: Colors.white)),
              );
              _handleSearchStart();
            } else {
              _handleSearchEnd();
            }
          });
        },
      ),
    ]);
  }

  void handleAddAlbumItem(BuildContext context) {
    Navigator.pushNamed(context, 'AlbumItemCreate',arguments:argAlbum);
  } // of handleAddAlbumItem

  @override
  void initState() {
    super.initState();
    argAlbum = ModalRoute.of(context).settings.arguments;
    refreshList();
  }

  void refreshList() {
    argAlbum.albumItems.then((newList) {
      setState(() {
        _list = newList;
        Log.message('${_list.length} album items loaded');
      });
    });
  } // of refreshList

}

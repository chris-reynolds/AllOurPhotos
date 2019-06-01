/*Created by chrisreynolds on 2019-05-24

Purpose: This will show the details of a single album

*/
import 'package:flutter/material.dart';
import '../shared/aopClasses.dart';
import '../dart_common/Logger.dart' as Log;
import '../dart_common/ListUtils.dart';
import '../widgets/wdgSnapGrid.dart';
import 'scAlbumCreateDlg.dart';

class AlbumDetail extends StatefulWidget {
  @override
  _AlbumDetailState createState() => _AlbumDetailState();
}

class _AlbumDetailState extends State<AlbumDetail> with Selection<int> {
  final scaffoldKey = new GlobalKey<ScaffoldState>();
  AopAlbum argAlbum;
  List<AopSnap> _list;

  @override
  Widget build(BuildContext context) {
    if (argAlbum == null)
      return Text('Loading...');
    else
      return new Scaffold(
        key: scaffoldKey,
        appBar: buildBar(context),
        body: snapGrid(context, _list, this),
//          new ListView(
//          padding: new EdgeInsets.symmetric(vertical: 8.0),
//          children: _buildList(),
//        ),
        floatingActionButton: FloatingActionButton(
          child: Icon(Icons.add_a_photo),
          onPressed: () => handleAddAlbumItem(context),
        ),
      );
  } // of build

  Widget buildBar(BuildContext context) {
    if (selectionList.length == 0)
      return new AppBar(
          centerTitle: true,
          title: Text('${argAlbum.name}'),
          actions: <Widget>[
            new IconButton(
              icon: Icon(Icons.edit),
              onPressed: () {
                handleRenameAlbum(context).then((xx) {
                  setState(() {});
                });
              },
            ),
          ]);
    else
      return AppBar(
        title: Text('${selectionList.length} items selected'),
        actions: <Widget>[
          IconButton(
              icon: Icon(Icons.redo),
              onPressed: () {
                // TODO move items to another album
              }),
          IconButton(
              icon: Icon(Icons.delete),
              onPressed: () {
                argAlbum.removeSnaps(selectionList).then((count) {
                  clearSelected();
                  refreshList();
                  showSnackBar("$count items removed");
                });
              }),
          IconButton(
              icon: Icon(Icons.close),
              onPressed: () {
                clearSelected();
                refreshList();
              }),
        ],
      );
  }

  List<Widget> _buildList() {
    if (_list == null)
      return [];
    else
      return _list.map((snap) => snapTile(snap)).toList();
  } // buildList

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    argAlbum = ModalRoute.of(context).settings.arguments;
    refreshList();
  } // of didChangeDependencies

  void handleAddAlbumItem(BuildContext context) {
    Navigator.pushNamed(context, 'AlbumItemCreate', arguments: argAlbum)
        .then((selectedSnaps) {
      List<int> snapIds = selectedSnaps;
      Log.message('${snapIds.length} snaps returned');
      argAlbum.addSnaps(snapIds).then((count) {
        clearSelected();
        refreshList();
        showSnackBar("$count items added");
      });
    });
  } // of handleAddAlbumItem

  void handleDelete() async {
    // todo : await sho
  } // of handleDelete

  Future<void> handleRenameAlbum(BuildContext context) async {
    String newName;
    String errorMessage = '';
    bool done = false;
    while (!done) {
      newName = await showDialog(
          context: context,
          builder: (BuildContext context) =>
              DgAlbumCreate(argAlbum.name, errorMessage));
      if (newName == EXIT_CODE)
        return;  // jump straight out
      Log.message('new name is: $newName');
      argAlbum.name = newName;
      await argAlbum.validate();
      if (argAlbum.isValid) {
        try {
          await argAlbum.save();
          refreshList();
          done = true;
        } catch (ex) {
          errorMessage = ex.message;
        }
      } else
        errorMessage = argAlbum.lastErrors.join('\n');
    } // of done loop
  } // handleRenameAlbum

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

  void showSnackBar(String message) {
    scaffoldKey.currentState
      ..removeCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  } // of showSnackBar

  Widget snapTile(AopSnap snap) {
    return Column(children: [
      ListTile(
        leading: Checkbox(
          value: isSelected(snap.id),
          onChanged: (value) {
            setSelected(snap.id, value);
            setState(() {});
          },
        ), // of checkbox
        title: Text('${snap.caption}'),
      ),
      Image.network(snap.thumbnailURL),
    ]);
  } // of snapTile
}

/*Created by chrisreynolds on 2019-05-24

Purpose: This will show the details of a single album

*/
import 'dart:io';
import 'package:all_our_photos_app/shared/DomainObject.dart';
import 'package:flutter/material.dart';
//import 'package:image/image.dart';
import '../shared/aopClasses.dart';
import '../dart_common/Logger.dart' as Log;
import '../dart_common/ListUtils.dart';
import '../dart_common/ListProvider.dart';
import '../dart_common/WebFile.dart';
import '../dart_common/DateUtil.dart';
import '../widgets/wdgSnapGrid.dart';
import '../widgets/wdgPhotoGrid.dart';
import 'scSimpleDlg.dart';
import '../flutter_common/WidgetSupport.dart';

class AlbumDetail extends StatefulWidget {
  @override
  _AlbumDetailState createState() => _AlbumDetailState();
}

class _AlbumDetailState extends State<AlbumDetail> with Selection<AopSnap>
    implements SelectableListProvider<AopSnap>{
  final scaffoldKey = new GlobalKey<ScaffoldState>();
  AopAlbum argAlbum;
  List<AopSnap> _list;
  List<AopSnap> get items => _list;

  CallBack onRefreshed;

  @override
  Widget build(BuildContext context) {
    if (argAlbum == null)
      return Text('Loading...');
    else
      return new Scaffold(
        key: scaffoldKey,
        appBar: buildBar(context),
//        body: snapGrid(context, _list, this),
//        body: SsSnapGrid(_list, this, argAlbum),
        body: PhotoGrid(this,album: argAlbum),
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
            if (Platform.isMacOS)
            new IconButton(
              icon: Icon(Icons.file_download),
              tooltip: 'Export album to downloads folder',
              onPressed: () {
                handleDownload(context).then((xx) {
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
              onPressed: () {moveToAnotherAlbum(context);}),
          IconButton(
              icon: Icon(Icons.delete),
              onPressed: () async {
                bool deleteAlbum = false;
                if (_list.length == selectionList.length) {
                  if (await confirmYesNo(context, 'Delete album',
                      description: 'All photos for this album have been\n selected for deletion'))
                    deleteAlbum = true;
                }
                argAlbum.removeSnaps(selectionList).then((count) {
                  clearSelected();
                  refreshList();
                  showSnackBar("$count photos removed");
                  if (deleteAlbum) {
                    argAlbum.delete();
                    showSnackBar('Album deleted');
                    Navigator.pop(context);
                  }
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
        showSnackBar("$count photos added");
      });
    });
  } // of handleAddAlbumItem

  Future<void> handleDownload(BuildContext context) async {
    List<AopSnap> snaps = await argAlbum.snaps;
    String dirName = '${Platform.environment['HOME']}/Downloads/';
    String albumName = argAlbum.name.replaceAll('/','-').replaceAll('\\','-').replaceAll(' ', '');
    if (albumName.length > 20)
      albumName = albumName.substring(0,19);
    dirName += albumName+'/';
    if (!Directory(dirName).existsSync())
      Directory(dirName).createSync();
    // make directory in downloads
     for (int snapIx=0; snapIx< snaps.length; snapIx++) {
      showSnackBar('${snaps.length-snapIx} photos to download');
      String sourceURL = snaps[snapIx].fullSizeURL;
      List<int> imgBytes = await loadWebBinary(sourceURL);
      String prefix = formatDate(snaps[snapIx].takenDate)+'-';
      File(dirName+prefix+snaps[snapIx].fileName).writeAsBytesSync(imgBytes,mode: FileMode.append );
    }
    showSnackBar('Download complete. See your downloads directory');
  } // of handleDownload

  Future<void> moveToAnotherAlbum(BuildContext context) async {
    List<AopAlbum> allAlbums = await AopAlbum.all();
    AopAlbum newAlbum = await showSelectDialog<AopAlbum>(context,
        'Move to another album','Album', allAlbums, (AopAlbum album)=>album.name);
    if (newAlbum == null)
      showSnackBar('Move abandoned');
    else if (newAlbum.id == argAlbum.id)
      showSnackBar('You cant move to the same album');
    else {
      // check if everything is moving
      bool deleteAlbum = false;
      if (_list.length == selectionList.length) {
        if (await confirmYesNo(context, 'Delete album',
            description: 'All photos for this album have been\n selected for deletion'))
          deleteAlbum = true;
      }
      // now we need to move the items before the optional delete
      int counter = 0;
      List<AopAlbumItem> oldItems = await argAlbum.albumItems;
      List<int> selectedIds = idList(this.selectionList);
      for (AopAlbumItem albumItem in oldItems) {
        if (selectedIds.indexOf(albumItem.snapId)>=0) {
          albumItem.albumId = newAlbum.id;
          if (await albumItem.save() >0)
            counter++;
        } // match
      } // of search loop
      showSnackBar('$counter photos moved to (${newAlbum.name})');
      if (deleteAlbum) {
        await argAlbum.delete();
        Navigator.pop(context);
      } else
        refreshList();
    } // ok to move
  } // moveToAnotherAlbum

  Future<void> handleRenameAlbum(BuildContext context) async {
    String newName;
    String errorMessage = '';
    bool done = false;
    while (!done) {
      newName = await showDialog(
          context: context,
          builder: (BuildContext context) =>
              DgSimple('Album name',argAlbum.name, errorMessage: errorMessage));
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
    // if there is a listener, let then know
    if (onRefreshed != null)
      this.onRefreshed();
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
          value: isSelected(snap),
          onChanged: (value) {
            setSelected(snap, value);
            setState(() {});
          },
        ), // of checkbox
        title: Text('${snap.caption}'),
      ),
      Image.network(snap.thumbnailURL),
    ]);
  } // of snapTile
}

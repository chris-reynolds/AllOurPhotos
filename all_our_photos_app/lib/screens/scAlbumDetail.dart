/*Created by chris reynolds on 2019-05-24

Purpose: This will show the details of a single album

*/
import 'dart:io';
import 'package:all_our_photos_app/shared/DomainObject.dart';
import 'package:flutter/material.dart';
import 'package:aopcommon/aopcommon.dart';
import '../shared/aopClasses.dart';
import '../widgets/wdgPhotoGrid.dart';
import 'scSimpleDlg.dart';
import '../flutter_common/WidgetSupport.dart';
import '../utils/ExportPic.dart';

class AlbumDetail extends StatefulWidget {
  AlbumDetail({Key? key}): super(key: key);

  @override
  _AlbumDetailState createState() => _AlbumDetailState();
}

class _AlbumDetailState extends State<AlbumDetail> with Selection<AopSnap>
    implements SelectableListProvider<AopSnap>{
  final scaffoldKey = GlobalKey<ScaffoldState>();

  AopAlbum? argAlbum;
  List<AopSnap>? _list;

  @override
  List<AopSnap> get items => _list??[];

  @override
  CallBack onRefreshed = (){};

  void refreshNow() async {
    _list = await argAlbum!.snaps;
  }
  @override
  Widget build(BuildContext context) {
    if (argAlbum == null)
      return Text('Loading...');
    else
      return Scaffold(
        key: scaffoldKey,
        appBar: buildBar(context),
//        body: snapGrid(context, _list, this),
//        body: SsSnapGrid(_list, this, argAlbum),
        body: PhotoGrid(this,album: argAlbum, refreshNow: refreshNow),
        floatingActionButton: FloatingActionButton(
          child: Icon(Icons.add_a_photo),
          onPressed: () => handleAddAlbumItem(context),
        ),
      );
  } // of build

  PreferredSizeWidget buildBar(BuildContext context) {
 //   if (selectionList.isEmpty)
      return AppBar(
          centerTitle: true,
          title: Text(argAlbum!.name),
          actions: <Widget>[
            IconButton(
              icon: Icon(Icons.edit),
              onPressed: () {
                handleRenameAlbum(context).then((xx) {
                  setState(() {});
                });
              },
            ),
//            if (Platform.isMacOS)
          if ( items.isNotEmpty)
            IconButton(
              icon: Icon(Icons.file_download),
              tooltip: 'Export album to downloads folder',
              onPressed: () {
                handleDownload(context).then((xx) {
                  setState(() {});
                });
              },
            ),

          ]);
    // else
    //   return AppBar(
    //     title: Text('${selectionList.length} items selected'),
    //     actions: <Widget>[
    //       IconButton(
    //           icon: Icon(Icons.redo),
    //           onPressed: () {moveToAnotherAlbum(context);}),
    //       // IconButton(
    //       //     icon: Icon(Icons.delete),
    //       //     onPressed: () async {await handleDelete(context);}),
    //       IconButton(
    //           icon: Icon(Icons.close),
    //           onPressed: () {
    //             clearSelected();
    //             refreshList();
    //           }),
    //     ],
    //   );
  }


  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    argAlbum = ModalRoute.of(context)!.settings.arguments as AopAlbum?;
    refreshList();
  } // of didChangeDependencies

  void handleAddAlbumItem(BuildContext context) {
    Navigator.pushNamed(context, 'AlbumItemCreate', arguments: argAlbum)
        .then((selectedSnaps) {
      List<int> snapIds = selectedSnaps as List<int>? ?? [];
      log.message('${snapIds.length} snaps returned');
      argAlbum!.addSnaps(snapIds).then((count) {
        clearSelected();
        refreshList();
        showSnackBar("$count photos added",context);
      });
    });
  } // of handleAddAlbumItem

  // Future<void> handleDelete(BuildContext context) async {
  //   bool deleteAlbum = false;
  //   if (selectionList == null) return; // nothing to delete
  //   if (_list.length == selectionList.length) {
  //     if (await confirmYesNo(context, 'Delete album?',
  //         description: 'All photos for this album have been\n selected for deletion'))
  //       deleteAlbum = true;
  //   }
  //   int count = await argAlbum.removeSnaps(selectionList);
  //   showSnackBar("$count photos removed",context);
  //   if (deleteAlbum) {
  //     showSnackBar('Album deleted',context);
  //     print('album delete');
  //     var fred = await argAlbum.delete();
  //     print('now pop');
  //     Navigator.pop(context,true);
  //   } else {
  //     clearSelected();
  //     refreshList();
  //   }
  // } // of handleDelete

  Future<void> handleDownload(BuildContext context) async {
    List<AopSnap> snaps = selectionList;
    String dirName = '${Platform.environment['HOME']}/Downloads/';
    String albumName = argAlbum!.name.replaceAll('/','-').replaceAll('\\','-').replaceAll(' ', '');
    if (albumName.length > 20)
      albumName = albumName.substring(0,19);
    dirName += '$albumName/';
    if (!Directory(dirName).existsSync())
      Directory(dirName).createSync();
    // make directory in downloads
    int errors = 0;
     for (int snapIx=0; snapIx< snaps.length; snapIx++) {
      showSnackBar('${snaps.length-snapIx} photos to download',context);
      String sourceURL = snaps[snapIx].fullSizeURL;
      if (!await ExportPic.save(sourceURL,snaps[snapIx].fileName,albumName))
        errors += 1;
//      List<int> imgBytes = await loadWebBinary(sourceURL);
//      String prefix = formatDate(snaps[snapIx].takenDate)+'-';
//      File(dirName+prefix+snaps[snapIx].fileName).writeAsBytesSync(imgBytes,mode: FileMode.append );
    }
    showSnackBar('Download complete. There were $errors errors.',context);
  } // of handleDownload

  Future<void> moveToAnotherAlbum(BuildContext context) async {
    List<AopAlbum> allAlbums = await AopAlbum.all();
    AopAlbum? newAlbum = await showSelectDialog<AopAlbum>(context,
        'Move to another album','Album', allAlbums, (AopAlbum album)=>album.name);
    if (newAlbum == null)
      showSnackBar('Move abandoned',context);
    else if (newAlbum.id == argAlbum!.id)
      showSnackBar('You cant move to the same album',context);
    else {
      // check if everything is moving
      bool deleteAlbum = false;
      if (_list!.length == selectionList.length) {
        if ((await confirmYesNo(context, 'Delete album after move',
            description: 'All photos for this album have been\n selected for deletion'))!)
          deleteAlbum = true;
      }
      // now we need to move the items before the optional delete
      int counter = 0;
      List<AopAlbumItem> oldItems = await argAlbum!.albumItems;
      List<int> selectedIds = idList(selectionList) as List<int>;
      for (AopAlbumItem albumItem in oldItems) {
        if (selectedIds.contains(albumItem.snapId)) {
          albumItem.albumId = newAlbum.id;
          if ((await albumItem.save())! >0)
            counter++;
        } // match
      } // of search loop
      showSnackBar('$counter photos moved to (${newAlbum.name})',context);
      if (deleteAlbum) {
        await argAlbum!.delete();
        Navigator.pop(context,true);
      } else
        refreshList();
    } // ok to move
  } // moveToAnotherAlbum

  Future<void> handleRenameAlbum(BuildContext context) async {
    String? newName;
    String errorMessage = '';
    bool done = false;
    while (!done) {
      newName = await showDialog(
          context: context,
          builder: (BuildContext context) =>
              DgSimple('Album name',argAlbum!.name, errorMessage: errorMessage));
      if (newName == EXIT_CODE)
        return;  // jump straight out
      log.message('new name is: $newName');
      argAlbum!.name = newName??'null album name';
      await argAlbum!.validate();
      if (argAlbum!.isValid) {
        try {
          await argAlbum!.save();
          refreshList();
          done = true;
        } catch (ex) {
          errorMessage = '$ex';
        }
      } else
        errorMessage = argAlbum!.lastErrors.join('\n');
    } // of done loop
  } // handleRenameAlbum

  @override
  void initState() {
    super.initState();
  }

  void refreshList() {
    argAlbum!.snaps.then((newList) {
      setState(() {
        _list = newList;
        log.message('${_list!.length} album items loaded');
      });
    });
    // if there is a listener, let then know
    //if (onRefreshed != null)
      onRefreshed();
  } // of refreshList

  void showSnackBar(String message, BuildContext context) {
//    ScaffoldMessenger.of(context)
//      ..removeCurrentSnackBar()
//      ..showSnackBar(SnackBar(content: Text(message)));
  } // of showSnackBar

  Widget snapTile(AopSnap snap) {
    return Column(children: [
      ListTile(
        leading: Checkbox(
          value: isSelected(snap),
          onChanged: (value) {
            setSelected(snap, value!);
            setState(() {});
          },
        ), // of checkbox
        title: Text(snap.caption!),
      ),
      Image.network(snap.thumbnailURL),
    ]);
  } // of snapTile
}

import 'package:all_our_photos_app/GooglePhotoSync.dart';
import 'package:all_our_photos_app/ImgFile.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';
import 'package:all_our_photos_app/GooglePhotosLibraryApi.dart';
import 'package:all_our_photos_app/appNavigator.dart';

class GoogleAlbumsWidget extends StatefulWidget {
  @override
  _GoogleAlbumsState createState() => _GoogleAlbumsState();
}


class _GoogleAlbumsState extends State<GoogleAlbumsWidget> {
  List<GoogleAlbum> _albums = [];
  int _albumIndex = -1;
  List<GooglePhoto> _photos = [];
  StreamController<GooglePhoto> _streamController;

  @override
  void initState() {
    super.initState();
    GooglePhotosLibraryClient.listAlbums().then((albums) {
      setState(()=>_albums = albums);
    });
    _streamController = StreamController.broadcast();
    _streamController.stream.listen((aPhoto)=>setState(() => _photos.add(aPhoto)));
  }

  @override
  void dispose() {
    _streamController?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text("Google Photo Albums for $googleUserName"),
            actions: <Widget>[
            IconButton(
                icon: Icon(Icons.refresh),
                tooltip: 'Sync with Google Photos',
                onPressed: () => _downloadAlbums(context),
            ),
        ]),
        body: Column(
            children: [
              Flexible(
                  flex:1,
                  child:ListView.builder(
                    itemCount: _albums.length,
                    itemBuilder: albumButtonBuilder
                )),
              Flexible(
                  flex:3,
                  child:ListView.builder(
                itemCount: _photos.length,
                itemBuilder: thumbnailBuilder
            ) ),
          ])
        );
  } // of build

  Widget albumButtonBuilder (BuildContext ctxt, int index) {
    bool isCurrent = (index == _albumIndex);
    return RaisedButton(
        child:Text('${_albums[index].title} - ${_albums[index].mediaItemsCount}'),
      color: isCurrent ? Colors.red:Colors.blue,
      onPressed: ()=> selectAlbum(index) ,
    );
  } // of albumButtonBuilder

  Widget thumbnailBuilder (BuildContext ctxt, index) {
     GooglePhoto thisPhoto = _photos[index];
     String setWidth = (MediaQuery.of(context).size.width*0.9).floor().toString();
     return Column(
         children: [
           Image.network(
              thisPhoto.baseUrl+'=w'+setWidth),
         Text(thisPhoto.filename),
    ]);
  } // of thumbnailBuilder

  void _downloadAlbums(BuildContext context) async {
    print ('downloadAlbums starting');
    for (var thisAlbum in _albums) {
      print('Album  - ${thisAlbum.title}');
      Stream<GooglePhoto> photoStream = GooglePhotosLibraryClient.listAlbumPhotos(thisAlbum.id);
      await for (var thisPhoto in photoStream) {
        ImgFile imgFile = GooglePhotoSync.findInCatalogue(thisPhoto);
        if (imgFile == null) {
          print('${thisPhoto.filename} to be added');
          try {
            await GooglePhotoSync.makeImgFile(thisPhoto);
          } catch(ex) {
            final snackBar = SnackBar(content: Text(ex.toString()));
            Scaffold.of(context).showSnackBar(snackBar);
          } // of try/catch
        } else
          print('${thisPhoto.filename} is ignored');
      } // of photoStream
    } // of album loop
    print('downloadAlbums ending');
  } // of downloadAlbums


  void selectAlbum(int index) async {
    _albumIndex = index;
    _photos = [];
    print('switching $index id=${_albums[_albumIndex].id}');
    Stream<GooglePhoto> photoStream = GooglePhotosLibraryClient.listAlbumPhotos(_albums[_albumIndex].id);
    await for (var thisPhoto in photoStream)
      _photos.add(thisPhoto);
    print('photo count is ${_photos.length}');
    setState(() {});
  } // of selectIndex
} // of _GoogleAlbumsState


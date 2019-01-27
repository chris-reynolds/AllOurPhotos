import 'package:flutter/material.dart';
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

  @override
  void initState() {
    super.initState();
    GooglePhotosLibraryClient.listAlbums().then((albums) {
      setState(()=>_albums = albums);
    });
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text("Google Photo Albums for $googleUserName"),
        ),
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
        child:Text(_albums[index].title),
      color: isCurrent ? Colors.red:Colors.blue,
      onPressed: ()=> selectAlbum(index) ,
    );
  } // of albumButtonBuilder

  Widget thumbnailBuilder (BuildContext ctxt, index) {
     GooglePhoto thisPhoto = _photos[index];
     return Column(
         children: [
           Image.network(
              thisPhoto.baseUrl),
         Text(thisPhoto.filename),
    ]);
  } // of thumbnailBuilder

  void selectAlbum(int index) {
    setState( () { _albumIndex = index; } );
    print('switching $index id=${_albums[_albumIndex].id}');
    GooglePhotosLibraryClient.listAlbumPhotos(_albums[_albumIndex].id).then((photos) {
      print('photo count is ${photos.length}');
      setState(() {_photos = photos;});
    });
  } // of selectIndex
} // of _GoogleAlbumsState


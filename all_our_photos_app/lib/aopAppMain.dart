import 'package:flutter/material.dart';
import 'screens/scAlbumList.dart';
import 'screens/scTesting.dart';
import 'screens/scAlbumDetail.dart';
import 'screens/scAlbumAddPhoto.dart';
import 'screens/scMetaEditor.dart';
import 'screens/scSinglePhoto.dart';
import 'screens/scDBFix.dart';
import 'screens/scLaunchWithLogin.dart';

const VERSION = 'All Our Photos 3Apr21.v1';

void main() {

  MaterialApp application = new MaterialApp(
    title: 'All Our Photos',
    debugShowCheckedModeBanner: false,
    //true,
    theme: new ThemeData(
      primaryColor: const Color(0xFF02BB9F),
      primaryColorDark: const Color(0xFF167F67),
      accentColor: const Color(0xFFFFAD32),
      textTheme: TextTheme(
          bodyText1: TextStyle(fontSize: 25.0, color: Colors.red)),
      buttonTheme: ButtonThemeData(
        buttonColor: Colors.greenAccent,
      ),
    ),
    home: LaunchWithLogin(VERSION),
    routes: <String, WidgetBuilder>{
      'home': (context) => LaunchWithLogin(VERSION) ,
      'AlbumList': (BuildContext context) => AlbumList(),
      'AlbumDetail': (BuildContext context) => AlbumDetail(),
      'AlbumItemCreate': (BuildContext context) => AlbumAddPhoto(),
      'MetaEditor': (BuildContext context) => MetaEditorWidget(),
      'SinglePhoto': (BuildContext context) => SinglePhotoWidget(),
      'Db Fix': (BuildContext context) => DbFixFormWidget(),
      'testlog': (BuildContext context) => SearchList(),
    },
  );
  runApp(application);
} // of main



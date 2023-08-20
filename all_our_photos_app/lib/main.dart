import 'package:flutter/material.dart';
import 'screens/scAlbumList.dart';
import 'screens/scTesting.dart';
import 'screens/scAlbumDetail.dart';
import 'screens/scAlbumAddPhoto.dart';
import 'screens/scMetaEditor.dart';
import 'screens/scSinglePhoto.dart';
import 'screens/scDBFix.dart';
import 'screens/scLaunchWithLogin.dart';

const VERSION = 'All Our Photos 9 Aug 23.v1';

void main() {

  MaterialApp application = MaterialApp(
    title: 'All Our Photos',
    debugShowCheckedModeBanner: false,
    //showSemanticsDebugger: true,
     theme: ThemeData(
       primarySwatch: Colors.blue,
     ),
    //   fontFamily: 'Helvetica', //'Helvetica',
    //   primaryColor: const Color(0xFF02BB9F),
    //   primaryColorDark: const Color(0xFF167F67),
    //   textTheme: TextTheme(
    //       bodyLarge: TextStyle(fontSize: 25.0, color: Colors.red,fontFamily:'Helvetica'),
    //       bodyMedium: TextStyle(fontFamily: 'Helvetica'),
    //     titleMedium: TextStyle(fontFamily: 'Helvetica'),
    //     titleSmall: TextStyle(fontFamily: 'Helvetica'),
    //     bodySmall: TextStyle(fontFamily: 'Helvetica'),
    //     labelLarge: TextStyle(fontFamily: 'Helvetica'),
    //     labelSmall: TextStyle(fontFamily: 'Helvetica'),
    //   ),
    //   buttonTheme: ButtonThemeData(
    //     buttonColor: Colors.greenAccent,
    //   ),
    //   chipTheme: ChipThemeData(selectedColor: Colors.lightBlueAccent),
    //   colorScheme: ColorScheme.fromSwatch().copyWith(secondary: const Color(0xFFFFAD32)),
    // ),
    home: LaunchWithLogin(VERSION),
    routes: <String, WidgetBuilder>{
      'home': (context) => LaunchWithLogin(VERSION) ,
      'AlbumList': (BuildContext context) => AlbumList(),
      'AlbumDetail': (BuildContext context) => AlbumDetail(),
      'AlbumItemCreate': (BuildContext context) => AlbumAddPhoto(),
      'MetaEditor': (BuildContext context) => MetaEditorWidget(),
      'SinglePhoto': (BuildContext context) => SinglePhotoWidget(),
      'Db Fixs': (BuildContext context) => DbFixFormWidget(),
      'testlog': (BuildContext context) => SearchList(),
    },
  );
  runApp(application);
} // of main



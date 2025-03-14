import 'package:flutter/material.dart';
import 'screens/scAlbumList.dart';
import 'screens/scTesting.dart';
import 'screens/scAlbumDetail.dart';
import 'screens/scAlbumAddPhoto.dart';
import 'screens/scMetaEditor.dart';
import 'screens/scSinglePhoto.dart';
import 'screens/scDBFix.dart';
import 'screens/scLaunchWithLogin.dart';
import 'package:provider/provider.dart';
import '../providers/albumProvider.dart';
import '../providers/snapProvider.dart';
import 'package:aopmodel/aop_classes.dart';

const VERSION = 'All Our Photos 6 Mar 2025';

void main() {
  MaterialApp application = MaterialApp(
    title: 'All Our Photos',
    debugShowCheckedModeBanner: false,
    //showSemanticsDebugger: true,
    theme: ThemeData(
      primarySwatch: Colors.blue,
      iconTheme: IconThemeData(size: 20),
    ),
    home: LaunchWithLogin(VERSION),
    routes: <String, WidgetBuilder>{
      'home': (context) => LaunchWithLogin(VERSION),
      'AlbumList': (BuildContext context) => AlbumList(),
      'AlbumDetail': (BuildContext context) => AlbumDetail(),
      'AlbumItemCreate': (BuildContext context) => AlbumAddPhoto(),
      'MetaEditor': (BuildContext context) => MetaEditorWidget(),
      'SinglePhoto': (BuildContext context) => SinglePhotoWidget(),
      'Db Fixs': (BuildContext context) => DbFixFormWidget(),
      'testlog': (BuildContext context) => SearchList(),
    },
  );
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => AlbumProvider()),
        ChangeNotifierProvider(
            create: (context) => SnapProvider(AopSnap(data: {}))),
      ],
      child: application,
    ),
  );
} // of main

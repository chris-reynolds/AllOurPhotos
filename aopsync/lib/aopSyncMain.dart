import 'package:flutter/material.dart';
import 'screens/scLaunchWithLogin.dart';



void main() {
    runApp(PhoneSyncApp());
} // of main

class PhoneSyncApp extends StatefulWidget {

  PhoneSyncApp() :super();

  @override
  _PhoneSyncAppState createState() => new _PhoneSyncAppState();
}

class _PhoneSyncAppState extends State<PhoneSyncApp> {

  @override
  Widget build(BuildContext context) {
      return new MaterialApp(
        debugShowCheckedModeBanner: false,
        home: LaunchWithLogin(),
      );
  }  // of build

} // of _PhoneSyncAppState


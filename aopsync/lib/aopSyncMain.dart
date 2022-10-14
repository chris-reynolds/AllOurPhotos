import 'package:flutter/material.dart';
import 'screens/scLaunchWithLogin.dart';



void main() {
    runApp(PhoneSyncApp());
} // of main

class PhoneSyncApp extends StatefulWidget {

  const PhoneSyncApp({Key? key}) :super(key: key);

  @override
  _PhoneSyncAppState createState() => _PhoneSyncAppState();
}

class _PhoneSyncAppState extends State<PhoneSyncApp> {

  @override
  Widget build(BuildContext context) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: LaunchWithLogin(),
      );
  }  // of build

} // of _PhoneSyncAppState


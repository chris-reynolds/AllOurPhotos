import 'package:flutter/material.dart';
import 'screens/scLaunchWithLogin.dart';

void main() {
  runApp(AopSyncApp());
} // of main

const APP_VERSION = 'AOP Sync 17 Dec 23';

class AopSyncApp extends StatefulWidget {
  const AopSyncApp({Key? key}) : super(key: key);

  @override
  AopSyncAppState createState() => AopSyncAppState();
}

class AopSyncAppState extends State<AopSyncApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: LaunchWithLogin(APP_VERSION),
    );
  } // of build
} // of _PhoneSyncAppState


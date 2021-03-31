/*
  Created by chrisreynolds on 2019-09-26
  
  Purpose: 

*/

import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:aopcommon/aopcommon.dart';
import '../authentication_state.dart';
import '../shared/dbAllOurPhotos.dart';
import 'scSignin.dart';
import 'scHome.dart';

class LaunchWithLogin extends StatelessWidget {
  final StreamController<AuthenticationState> _streamController =
      new StreamController<AuthenticationState>();

  Future<void> initConfig() async {
    String localDocs = (await getApplicationDocumentsDirectory()).path;
    log.message('localdocs from $localDocs');
    if (Platform.isAndroid) {
      String extStorage = (await getExternalStorageDirectory()).path;
      log.message('external storage is $extStorage');
    }
    await loadConfig(localDocs + '/aopPhoneSync.config.json');
    log.message('loaded config from $localDocs');
  } // of initConfig

  Future<void> tryLogin() async {
    try {
      var db = DbAllOurPhotos();
      await db.initConnection(config);
      await db.startSession(config);
      _streamController.add(AuthenticationState.authenticated());
      saveConfig();
      log.message('Config saved');
    } catch (ex) {
      log.error('Failed to login $ex');
      _streamController.add(AuthenticationState.failed());
    }
  } // of tryLogin

  void tryLogout() => _streamController.add(AuthenticationState.signedOut());

  @override
  Widget build(BuildContext context) {
    initConfig().then((xx) => tryLogin());
    log.message('building after tryLogin');
    return new StreamBuilder<AuthenticationState>(
        stream: _streamController.stream,
//        initialData: new AuthenticationState.initial(),
        builder: (BuildContext context, AsyncSnapshot<AuthenticationState> snapshot) {
          final state = snapshot.data;
          if (state == null)
            return CircularProgressIndicator();
          else if (state.authenticated)
            return HomePage(tryLogout);
          else
            return SignInPage(/*_streamController,*/ tryLogin);
        });
  }
}

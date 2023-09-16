/*
  Created by chrisreynolds on 2019-09-26
  
  Purpose: 

*/

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:aopcommon/aopcommon.dart' show config, log;
import '../authentication_state.dart';
// import 'package:aopmodel/dbAllOurPhotos.dart';
import 'scSignin.dart';
import 'scHome.dart';

class LaunchWithLogin extends StatelessWidget {
  final StreamController<AuthenticationState> _streamController =
      StreamController<AuthenticationState>();
  final String title;
  LaunchWithLogin(this.title);
  Future<void> initConfig() async {
    config.init('aop');
    log.message('loaded config ');
  } // of initConfig

  Future<void> tryLogin() async {
    try {
//      var db = DbAllOurPhotos();
//      await db.initConnection(config);
//      await db.startSession(config);
      _streamController.add(AuthenticationState.authenticated());
      await config.save();
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
    return StreamBuilder<AuthenticationState>(
        stream: _streamController.stream,
//        initialData: new AuthenticationState.initial(),
        builder: (BuildContext context,
            AsyncSnapshot<AuthenticationState> snapshot) {
          final state = snapshot.data;
          if (state == null)
            return CircularProgressIndicator();
          else if (state.authenticated)
            return HomeScreen(
              logoutFn: tryLogout,
              title: title,
            );
          else
            return SignInPage(/*_streamController,*/ tryLogin);
        });
  }
}

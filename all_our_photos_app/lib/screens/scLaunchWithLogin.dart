/*
  Created by chrisreynolds on 2019-09-26
  
  Purpose: 

*/

import 'dart:async';
import 'package:aopmodel/aop_classes.dart';
import 'package:aopmodel/domain_object.dart';
import 'package:flutter/material.dart';
import 'package:aopcommon/aopcommon.dart' show log, WebFile;
import '../authentication_state.dart';
import '../utils/Config.dart';
import 'scSignin.dart';
import 'scHome.dart';

class LaunchWithLogin extends StatelessWidget {
  final StreamController<AuthenticationState> _streamController =
      StreamController<AuthenticationState>();
  final String title;
  LaunchWithLogin(this.title);
  Future<void> initConfig() async {
    await config.load('aop_config.json');
    log.message('loaded config $config');
  } // of initConfig

  Future<void> tryLogin() async {
    try {
//      var db = DbAllOurPhotos();
//      await db.initConnection(config);
//      await db.startSession(config);
      if (config['sesuser'] == null) throw Exception('No User');
      rootUrl = 'http://${config['host']}:${config['port']}';
      WebFile.setRootUrl('$rootUrl/photos');
      Map<String, dynamic> sessionRequest = await sessionProvider.rawRequest(
          'ses/${config['sesuser']}/${config['sespassword']}/${config['sesdevice']}');
      config['sessionid'] = sessionRequest['jam'] ?? '';
      if (!config['sessionid'].startsWith('2'))
        throw Exception('Invalid session Id');
      modelSessionid = config['sessionid'];
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

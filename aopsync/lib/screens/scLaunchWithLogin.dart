/*
  Created by chrisreynolds on 2019-09-26
  
  Purpose: 

*/

import 'dart:async';
import 'dart:io';
import 'package:aopmodel/aop_classes.dart';
import 'package:aopmodel/domain_object.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:aopcommon/aopcommon.dart' show log, WebFile;
import '../authentication_state.dart';
import '../utils/Config.dart';
import 'scSignin.dart';
import 'scHome.dart';

class LaunchWithLogin extends StatelessWidget {
  final StreamController<AuthenticationState> _streamController =
      StreamController<AuthenticationState>();
  final String title;
  LaunchWithLogin(this.title, {super.key});
  Future<void> initConfig() async {
    log.debug('starting version $title');
    await config.load('aop_config.json');
    log.debug('loaded config $config');
  } // of initConfig

  Future<bool> checkPermissions(List<Permission> permissionList) async {
    for (var permission in permissionList) {
      // var fred = await permission.status;
      if (await permission.status.isDenied) {
        await permission.request();
      }
      if (!await permission.status.isGranted) return false;
    }
    return true;
  } // of checkPermissions

  Future<void> tryLogin() async {
    try {
      if (Platform.isAndroid) {
        var androidInfo = await DeviceInfoPlugin().androidInfo;
        List<Permission> photoPermissions = androidInfo.version.sdkInt >= 32
            ? [Permission.photos, Permission.videos]
            : [Permission.storage];
        if (!await checkPermissions(
            [...photoPermissions, Permission.accessMediaLocation])) {
          _streamController.add(AuthenticationState.noPermission());
          return;
        }
      }
      if (config['sesuser'] == null) throw Exception('No User');
      if (Uri.base.host.isNotEmpty) {
        rootUrl = '${Uri.base}';
        rootUrl = rootUrl.replaceAll('8686',
            '8000'); // allow interactive debugging on port 8686 with affecting server
      } else
        rootUrl = 'http://${config['host']}:${config['port']}/';
      WebFile.setRootUrl('${rootUrl}photos/');
      Map<String, dynamic> sessionRequest = await sessionProvider.rawRequest(
          'ses/${config['sesuser']}/${config['sespassword']}/${config['sesdevice']}');
      config['sessionid'] = sessionRequest['jam'] ?? '';
      if (!config['sessionid'].startsWith('2'))
        throw Exception('Invalid session Id');
      modelSessionid = config['sessionid'];
      WebFile.setPreserve('{jam:"$modelSessionid"}');
      _streamController.add(AuthenticationState.authenticated());

      await config.save();
      log.debug('Config saved');
    } catch (ex) {
      log.error('Failed to login $ex');
      _streamController.add(AuthenticationState.failed());
    }
  } // of tryLogin

  void tryLogout() => _streamController.add(AuthenticationState.signedOut());

  @override
  Widget build(BuildContext context) {
    initConfig().then((xx) => tryLogin());
    log.debug('building after tryLogin');
    return StreamBuilder<AuthenticationState>(
        stream: _streamController.stream,
//        initialData: new AuthenticationState.initial(),
        builder: (BuildContext context,
            AsyncSnapshot<AuthenticationState> snapshot) {
          final state = snapshot.data;
          if (state == null)
            return CircularProgressIndicator();
          else if (state.authenticated)
            return HomePage(
              tryLogout: tryLogout,
              title: title,
            );
          else
            return SignInPage(tryLogin);
        });
  }
}

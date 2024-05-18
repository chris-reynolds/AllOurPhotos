/*
  Created by chrisreynolds on 2019-09-26
  
  Purpose: 

*/
// import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:aopcommon/aopcommon.dart';
import '../flutter_common/WidgetSupport.dart';
import '../utils/Config.dart';

List<String> _fieldDefs = [
  'User name:sesuser',
  'Password:sespassword',
  'Device:sesdevice',
];

class SignInPage extends StatelessWidget {
  final _loginFormKey = GlobalKey<FormState>();
  final AsyncCallback loginCallback;
  final WsFieldSet _fieldSet;

  SignInPage(this.loginCallback)
      : _fieldSet = WsFieldSet(_fieldDefs, values: config.values(), spacer: 1);

  signIn2() async {
    var formValueMap = _fieldSet.values;
//    var formValueMap = wsFormValues(_loginFormKey.currentState); // _loginFormKey.currentState;
    log.message('my form state $formValueMap');
    config.addAll(formValueMap);
    await loginCallback();
    log.message('just executed login callback');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: Text('Sign in'),
          actions: [navIconButton(context, 'testlog', Icons.list)]),
      body: SafeArea(
        child: Form(
          key: _loginFormKey,
          child: ListView(
            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 0),
            children: <Widget>[
              ..._fieldSet.widgets,
              ElevatedButton(
                child: Text('Sign in'),
                onPressed: () async {
                  log.message('sign in 23 callback');
                  await signIn2();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

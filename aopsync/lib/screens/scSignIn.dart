/*
  Created by chrisreynolds on 2019-09-26
  
  Purpose: 

*/
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
// import 'package:flutter/widgets.dart';
import 'package:aopcommon/aopcommon.dart';
import '../flutter_common/WidgetSupport.dart';
import 'scLogger.dart';

//import 'package:flutter_form_builder/flutter_form_builder.dart';



class SignInPage extends StatelessWidget {
//  final StreamController<AuthenticationState> _streamController;
  final _loginFormKey = GlobalKey<FormState>();
  final AsyncCallback loginCallback;
  WsFieldSet _fieldSet;
  SignInPage(this.loginCallback, {Key key}) : super(key: key) {
    List<String> fieldDefs = [
      'DB Host:dbhost',
      'DB Port:dbport',
      'Database:dbname',
      'DB User:dbuser',
      'DB Password:dbpassword',
      'User name:sesuser',
      'Password:sespassword',
//      'Web Root:webroot',
//      "Web Port:webport",
      'Device:sesdevice',
    ];
    if (!Platform.isIOS)
      fieldDefs.add('Local Directory:lcldirectory');
    _fieldSet = WsFieldSet(fieldDefs,values: config, spacer:1);

  }

  signIn2() async {
    var formValueMap = _fieldSet.values;
//    var formValueMap = wsFormValues(_loginFormKey.currentState); // _loginFormKey.currentState;
    log.message('my form state $formValueMap');
    config.addAll(formValueMap);
    await loginCallback();
  log.message('just executed login callback');
  }

  void _showLogger(BuildContext context) {
    Navigator.push(context, MaterialPageRoute(builder:(context)=>LoggerList(),fullscreenDialog: true));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Sign in'),actions:[
        IconButton(
          icon: Icon(Icons.list),
          onPressed: ()=>_showLogger(context),
        ),
      ]),
      body: SafeArea(
        child: Form(
//          onChanged: handleFormChanged,
          key: _loginFormKey,
          child: ListView(
            padding: EdgeInsets.symmetric(horizontal: 24,vertical: 0),
            children: <Widget>[
              ..._fieldSet.widgets,
//              ...registerLoginWidgets(),
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

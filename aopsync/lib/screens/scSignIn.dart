/*
  Created by chrisreynolds on 2019-09-26
  
  Purpose: 

*/
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:aopcommon/aopcommon.dart';
import '../flutter_common/WidgetSupport.dart';
import 'scLogger.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';



class SignInPage extends StatelessWidget {
//  final StreamController<AuthenticationState> _streamController;
  final _loginFormKey = GlobalKey<FormBuilderState>();
  final Function loginCallback;

  SignInPage(/*this._streamController,*/this.loginCallback) ;

  signIn() async {
    var formValueMap = wsFormValues(_loginFormKey.currentState); // _loginFormKey.currentState;
    log.message('my form state $formValueMap');
    config.addAll(formValueMap);
    loginCallback();
  log.message('just executed login callback');
  }

  void _showLogger(BuildContext context) {
    Navigator.push(context, MaterialPageRoute(builder:(context)=>LoggerList(),fullscreenDialog: true));
  }

  List<Widget> registerLoginWidgets() {
    List<String> fields = [
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
      fields.add('Local Directory:lcldirectory');
    return fields.map((thisFieldDef) => wsMakeField(thisFieldDef, values: config, spacer: 1)).toList();
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
        child: FormBuilder(
//          onChanged: handleFormChanged,
          key: _loginFormKey,
          child: ListView(
            padding: EdgeInsets.symmetric(horizontal: 24,vertical: 0),
            children: <Widget>[
              ...registerLoginWidgets(),
              RaisedButton(
                child: Text('Sign in'),
                onPressed: signIn,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/*
  Created by chrisreynolds on 2019-09-26
  
  Purpose: 

*/
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import '../dart_common/Config.dart';
import '../flutter_common/WidgetSupport.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import '../dart_common/Logger.dart' as Log;

class SignInPage extends StatelessWidget {
//  final StreamController<AuthenticationState> _streamController;
  final _loginFormKey = GlobalKey<FormBuilderState>();
  final Function loginCallback;

  SignInPage(/*this._streamController,*/this.loginCallback) ;

  signIn() async {
    var formValueMap = wsFormValues(_loginFormKey.currentState); // _loginFormKey.currentState;
    Log.message('my form state $formValueMap');
    config.addAll(formValueMap);
    loginCallback();
  Log.message('just executed login callback');
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
      'Web Root:webroot',
      "Web Port:webport",
      'Device:sesdevice',
      'Local Directory:lcldirectory',
    ];
    return fields.map((thisFieldDef) => wsMakeField(thisFieldDef, values: config, spacer: 1)).toList();
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Sign in3')),
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

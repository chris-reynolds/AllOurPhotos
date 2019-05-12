///
///  Created by Chris R on 6th May 2019
///

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../dart_common/LoginStateMachine.dart';
import '../dart_common/WidgetSupport.dart';
import '../dart_common/Logger.dart' as Log;
import '../dart_common/Config.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';

class LoginForm extends StatefulWidget {
  final LoginStateMachine loginSM;

  LoginForm(this.loginSM);

  @override
  _LoginFormState createState() => _LoginFormState(loginSM);
}

class _LoginFormState extends State<LoginForm> {
  LoginStateMachine _loginSM;
  var _loginFormKey = GlobalKey<FormBuilderState>();
  String _messageText = 'Nothing2';
  Map<String, dynamic> fieldValues = {
    'dbhost': '192.168.1.251',
    'dbport': '3306',
    'sesdevice': 'fffff'
  };

  _LoginFormState(this._loginSM) : super();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: FormBuilder(
//          onChanged: handleFormChanged,
          key: _loginFormKey,
          child: ListView(
            padding: EdgeInsets.symmetric(horizontal: 24),
            children: <Widget>[
              SizedBox(height: 80),
              Column(
                children: [
                  Image.asset('assets/login_icon.png'),
                  SizedBox(height: 20),
                  Text('All Our Photos - LOGIN'),
                ],
              ),
              if (_loginSM.loginStatus == etLoginStatus.NoConfig)
                ...registerMachineWidgets(),
              if (_loginSM.loginStatus == etLoginStatus.NotLoggedIn)
                ...loginUserWidgets(),
              if (_loginSM.loginStatus == etLoginStatus.TooManyTries)
                ...lockedOutWidgets(),
              if (_loginSM.loginStatus == etLoginStatus.ServerNotAvailable)
                ...serverNotAvailableWidgets(),
              SizedBox(height: 36),
              Text('$_messageText',
                  style: TextStyle(color: Colors.red, fontSize: 20)),
              if (_loginSM.loginStatus == etLoginStatus.NoConfig ||
                  _loginSM.loginStatus == etLoginStatus.NotLoggedIn)
                ButtonBar(children: <Widget>[
                  FlatButton(
                    child: Text('Cancel'),
                    onPressed: handleCancelPressed,
                  ),
                  RaisedButton(
                      child: Text('Next'), onPressed: handleNextPressed)
                ])
            ], // of listview children
          ), // of listView
        ), // of form
      ), // of safeArea
    ); // of scaffold
  } // of build

  List<Widget> loginUserWidgets() {
    List<String> fields = [
      'User name:sesuser',
      'Password:sespassword',
      'Device:sesdevice',
    ];
    return fields
        .map((thisFieldDef) => wsMakeField(thisFieldDef, values: fieldValues))
        .toList();
  }

  List<Widget> registerMachineWidgets() {
    List<String> fields = [
      'Host:dbhost',
      'Port:dbport',
      'DB User Name:dbuser',
      'DB Password:dbpassword',
      'Database:dbname'
    ];
    return fields
        .map((thisFieldDef) => wsMakeField(thisFieldDef, values: fieldValues))
        .toList();
  }

  List<Widget> lockedOutWidgets() {
    return [Text('locked out')];
  }

  List<Widget> serverNotAvailableWidgets() {
    return [
      Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
        Text('Server Not Available',
            style: TextStyle(fontSize: 20, color: Colors.red)),
        RaisedButton(
            child: Text('RETRY'),
            onPressed: () {
              _loginSM.logout();
            }),
      ]))
    ];
  } // of serverNotAvailableWidgets

  void handleShowMessage(String messageText) {
    setState(() {
      _messageText = messageText;
    });
  }

  @override
  void initState() {
    // hook up the listeners to react to the state changes
    super.initState();
    _loginSM.addStateListener(this.handleStatusChange);
    _loginSM.addMessageListener(handleShowMessage);
  } // of initState

  @override
  void dispose() {
    _loginSM.removeStateListener(this.handleStatusChange);
    _loginSM.removeMessageListener(handleShowMessage);
    super.dispose();
  } // of dispose

  void handleStatusChange(etLoginStatus newStatus) {
    setState(() {});
  } // of handleStatusChange

  void handleStatusMessage(String newMessage) {
    setState(() {
      _messageText = newMessage;
    });
  } // of handleStatusChange

  void handleNextPressed() async {
    Log.message('The Next button was  pressed');
    _messageText = '';
    if (_loginFormKey.currentState.validate()) {
      _loginFormKey.currentState.save();
      fieldValues.addAll(wsFormValues(_loginFormKey.currentState));
      await _loginSM.startSession(fieldValues);
    } else
      Log.message('Validation failed ');
    if (_loginSM.loginStatus == etLoginStatus.LoggedIn) {
      saveConfig();
      Navigator.of(context).pushNamed('home');
    }
  } // of handleNextPressed

  void handleCancelPressed() {
    Log.message('The cancel button was pressed');
    _loginSM.backTrack();
//    _loginFormKey.currentState.reset();
  } // of handleCancelPressed

} // of _LoginFormState

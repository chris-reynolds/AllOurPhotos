///
///  Created by Chris R on 6th May 2019
///

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../appNavigator.dart';
import '../dart_common/LoginStateMachine.dart';
import '../dart_common/WidgetSupport.dart';
import '../dart_common/Logger.dart' as Log;
import '../dart_common/Config.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';

class LoginForm extends StatefulWidget {
//  final LoginStateMachine loginSM;

  LoginForm();

  @override
  _LoginFormState createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {

  var _loginFormKey = GlobalKey<FormBuilderState>();
  String _messageText = '';
  Map<String, dynamic> fieldValues = {
    'dbhost': '192.168.1.251',
    'dbport': '3306',
    'sesdevice': 'fffff'
  };

  _LoginFormState() : super() {
    if (loginStateMachine.loginStatus == etLoginStatus.LoggedIn)
      loginStateMachine.logout();
  } // of constructor

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
              if (loginStateMachine.loginStatus == etLoginStatus.NoConfig)
                ...registerMachineWidgets(),
              if (loginStateMachine.loginStatus == etLoginStatus.NotLoggedIn)
                ...loginUserWidgets(),
              if (loginStateMachine.loginStatus == etLoginStatus.TooManyTries)
                ...lockedOutWidgets(),
              if (loginStateMachine.loginStatus == etLoginStatus.ServerNotAvailable)
                ...serverNotAvailableWidgets(),
              SizedBox(height: 36),
              Text('$_messageText',
                  style: TextStyle(color: Colors.red, fontSize: 20)),
              if (loginStateMachine.loginStatus == etLoginStatus.NoConfig ||
                  loginStateMachine.loginStatus == etLoginStatus.NotLoggedIn)
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
              loginStateMachine.logout();
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
    loginStateMachine.addStateListener(this.handleStatusChange);
    loginStateMachine.addMessageListener(handleShowMessage);
  } // of initState

  @override
  void dispose() {
    loginStateMachine.removeStateListener(this.handleStatusChange);
    loginStateMachine.removeMessageListener(handleShowMessage);
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
      await loginStateMachine.startSession(fieldValues);
    } else
      Log.message('Validation failed ');
    if (loginStateMachine.loginStatus == etLoginStatus.LoggedIn) {
      saveConfig();
      Navigator.of(context).pushNamed('home');
    }
  } // of handleNextPressed

  void handleCancelPressed() {
    Log.message('The cancel button was pressed');
    loginStateMachine.backTrack();
//    _loginFormKey.currentState.reset();
  } // of handleCancelPressed

} // of _LoginFormState

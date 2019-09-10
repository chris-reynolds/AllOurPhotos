import '../shared/dbAllOurPhotos.dart';
import '../dart_common/Logger.dart' as Log;

//import '../screens/scLogin.dart';
import 'dart:async';

///
///  Created by Chris R on 6th May 2019
///

enum etLoginStatus {
  NoConfig,
  NotLoggedIn,
  LoggedIn,
  TooManyTries,
  ServerNotAvailable
}

// this is used to alert a listen that the status has changed.
typedef StatusChangeFn = void Function(etLoginStatus newStatus);
typedef MessageFn = void Function(String message);

class LoginStateMachine {
  Map<String, dynamic> _config;
  etLoginStatus _loginStatus = etLoginStatus.NotLoggedIn;
  List<StatusChangeFn> _stateListeners = [];
  List<MessageFn> _messageListeners = [];

  // variables to handle lockout of repeated bad login
  static const MAXLOGIN = 3;
  static const Duration LOCKOUTPERIOD = Duration(seconds: 15);
  int badLoginCount = 0;
  DateTime repeatedLoginLockOutTime;

  etLoginStatus get loginStatus => _loginStatus;

  set loginStatus(etLoginStatus newStatus) {
    etLoginStatus oldStatus = _loginStatus;
    _loginStatus = newStatus;
    if (oldStatus != newStatus) {
      for (StatusChangeFn listener in _stateListeners) listener(newStatus);
    }
  } // of set login Status

  void addStateListener(StatusChangeFn newListener) =>
      _stateListeners.add(newListener);

  void removeStateListener(StatusChangeFn oldListener) =>
      _stateListeners.remove(oldListener);

  void broadcastMessage(String messageText) {
    for (var listener in _messageListeners) listener(messageText);
  } // of broadcastMessage

  void addMessageListener(MessageFn newListener) =>
      _messageListeners.add(newListener);

  void removeMessageListener(MessageFn oldListener) =>
      _messageListeners.remove(oldListener);

  LoginStateMachine(this._config, {StatusChangeFn listener}) {
    if (_config == null) _config = {};
    if (listener != null) addStateListener(listener);
  } // of constructor

  Future<bool> _tryDbConnect() async {
    int result = await DbAllOurPhotos().initConnection({
      'dbhost': _config['dbhost'],
      'dbport': _config['dbport'],
      'dbuser': _config['dbuser'],
      'dbpassword': _config['dbpassword'],
      'dbname': _config['dbname']
    });
    return (result == 1);
  } // _tryDbConnect

  Future<int> _tryNewSession() async {
    int sessionid = await DbAllOurPhotos().startSession({
      'sesuser': _config['sesuser'],
      'sespassword': _config['sespassword'],
      'sesdevice': _config['sesdevice']
    });
    return sessionid;
  } // of tryNewSession

  Future<void> initState() async {
    await startSession();
  } // initState

  Future<int> startSession([Map<String, dynamic> newConfig]) async {
    if (newConfig != null) this._config.addAll(newConfig);
    if (repeatedLoginLockOutTime != null &&
        repeatedLoginLockOutTime.isAfter(DateTime.now())) {
      broadcastMessage('Repeated bad logins caused a locked account');
      return -1;
    }
    if (_config['dbname'] == null || _config['dbhost'] == null) {
      loginStatus = etLoginStatus.NoConfig;
      return 0;
    } else {
      try {
        await _tryDbConnect();
      } catch (ex, stack) {
        Log.error('????????????????1 \n $ex \n $stack');
        loginStatus = etLoginStatus.ServerNotAvailable;
        return 0;
      }
      // we have a good connection so lets open a session
      try {
        int sessionid = await _tryNewSession();
        if (sessionid > 0) // successful
          loginStatus = etLoginStatus.LoggedIn;
        else {
          // deal with bad login
          broadcastMessage('Incorrect user name or password');
          if (++badLoginCount <= MAXLOGIN)
            loginStatus = etLoginStatus.NotLoggedIn;
          else {
            // time to lock out
            repeatedLoginLockOutTime = DateTime.now().add(LOCKOUTPERIOD);
            loginStatus = etLoginStatus.TooManyTries;
            Timer(LOCKOUTPERIOD, this.handleUnlockTimer);
          }
        }
        return sessionid;
      } catch (ex, stack) {
        Log.error('???????????????????2 \n$ex \n$stack');
        loginStatus = etLoginStatus.NotLoggedIn;
      }
    }
    return -1; // should never get here
  } // startSession

  void backTrack() {
    switch (loginStatus) {
      case etLoginStatus.NotLoggedIn:
        loginStatus = etLoginStatus.NoConfig;
        break;
      case etLoginStatus.NoConfig:
        loginStatus = etLoginStatus.ServerNotAvailable;
        break;
      case etLoginStatus.LoggedIn:
        loginStatus = etLoginStatus.NotLoggedIn;
        break;
      case etLoginStatus.ServerNotAvailable:
        loginStatus = etLoginStatus.NotLoggedIn;
        break;
      case etLoginStatus.TooManyTries:
        loginStatus = etLoginStatus.NotLoggedIn;
        break;
    }
  } // of backTrack

  void logout() {
    this.loginStatus = etLoginStatus.NotLoggedIn;
    broadcastMessage('');
  } // of logout

  void handleUnlockTimer() {
    badLoginCount = 0;
    repeatedLoginLockOutTime = null;
    if (loginStatus == etLoginStatus.TooManyTries)
      loginStatus = etLoginStatus.NotLoggedIn;
    broadcastMessage('Account unlocked');
  } // of handleUnlockTimer

} // of LoginStateMachine

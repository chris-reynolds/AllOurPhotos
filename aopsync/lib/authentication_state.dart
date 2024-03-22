/*
  Created by chrisreynolds on 2019-09-26
  
  Purpose: 

*/

class AuthenticationState {
  final bool authenticated;

  AuthenticationState.initial({this.authenticated = false});

  AuthenticationState.authenticated({this.authenticated = true});

  AuthenticationState.failed({this.authenticated = false});

  AuthenticationState.signedOut({this.authenticated = false});

  AuthenticationState.noPermission({this.authenticated = false});
}

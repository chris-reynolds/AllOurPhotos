/*
  Created by ChrisR on 16th October 2018
  
  Purpose: Central Point for the app and navigation outside the launcher

*/

import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';


MaterialApp application;
bool _isSignedInToGoogle = false;
Map<String,String> authHeaders;
get isSignedInToGoogle => _isSignedInToGoogle; // readonly from outside


GoogleSignIn _googleSignIn = GoogleSignIn(
  scopes: [
    'https://www.googleapis.com/auth/photoslibrary.readonly',
  ],
);

Future<bool> signInToGoogle() async {
  _isSignedInToGoogle = false;
  try {
    await _googleSignIn.signIn();
    print('Signed in as ${_googleSignIn.currentUser.displayName}');
    _isSignedInToGoogle = true;
    authHeaders = await _googleSignIn.currentUser.authHeaders;
  } catch (error) {
    print('Failed to signin $error');
  }
  return _isSignedInToGoogle;
}
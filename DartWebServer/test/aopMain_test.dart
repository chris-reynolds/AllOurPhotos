/**
 * Created by Chris on 14/09/2018.
 */

import 'dart:io';
import 'dart:convert';
import 'dart:async';
import 'package:test/test.dart';
import '../bin/aopMain.dart' as aopApp;
import 'aopTestSupport.dart';

void main() {
  setUp(() async {
    await aopApp.main(['testConfig.json']);
  });

  tearDown(() async {
    await aopApp.mainServer.close(force: true);
    aopApp.mainServer = null;
  });
  group('aopServer', () {
    test('can see root ',  () async {
      var tr = TestRequest();
      await tr.get('/',accept:'application/json')
      ..uExpectHeader('content-type','json')
      ..uExpectText('2017')
//    ..uExpectData(length,4)
      ..uExpectStatus(200);
    });
    test('can see folder ',  () async {
      var tr = TestRequest();
      await tr.get('/2017-08',accept:'application/json')
        ..uExpectHeader('content-type','json')
        ..uExpectText('IMG_20170827_085827249')
//    ..uExpectData(length,4)
        ..uExpectStatus(200);
    });
    test('can see folder index ',  () async {
      var tr = TestRequest();
      await tr.get('/2017-08/index.json',accept:'application/json')
        ..uExpectHeader('content-type','json')
        ..uExpectText('IMG_20170827_085827249')
//    ..uExpectData(length,4)
        ..uExpectStatus(200);
    });
    test('can fail softly for bad folder ',  () async {
      var tr = TestRequest();
      await tr.get('/badname',accept:'text/html')
        ..uExpectStatus(404);
    });
    test('can fail softly for bad file ',  () async {
      var tr = TestRequest();
      await tr.get('/2017-08/badname.jpg',accept:'image/jpeg')
        ..uExpectStatus(404);
    });
    test('can fail softly for bad folder and file ',  () async {
      var tr = TestRequest();
      await tr.get('/badname/badname.json',accept:'application/json')
        ..uExpectStatus(404);
    });

  });
}


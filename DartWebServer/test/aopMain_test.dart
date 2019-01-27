/**
 * Created by Chris on 14/09/2018.
 */

import 'dart:io';
import 'dart:convert';
import 'dart:async';
import 'package:test/test.dart';
import '../bin/aopMain.dart' as aopApp;
import 'aopTestSupport.dart';
import 'package:test_api/src/backend/invoker.dart' as Fred;

var fred;
Function myBody(Function body)  {
   return () async {
     print('prebody');
     await body();
     fred = Fred.Invoker.current.liveTest;
     print('postbody liveTest errorcount=$fred');
   };
}
void main() {
  fred =1;
  setUp(() async {
    fred +=1;
    await aopApp.main(['testConfig.json']);
  });

  tearDown(() async {
    var bill = fred;
    print('teardown liveTest errorcount=$bill');
    await aopApp.mainServer.close(force: true);
    aopApp.mainServer = null;
  });
  group('aopServer-', () {
    test('can see root ',  () async {
      var tr = TestRequest();
      var tr2 = await tr.get('/',accept:'text/tab-separated-values');
      tr2.uExpectHeader('content-type','tab-separated-values');
      tr2.uExpectText('2017');
//    ..uExpectData(length,4)
      tr2.uExpectStatus(200);
    });
    test('can see folder ',  () async {
      var tr = TestRequest();
      await tr.get('/2017-08',accept:'text/tab-separated-values')
        ..uExpectHeader('content-type','tab-separated-values')
        ..uExpectText('IMG_20170827_085827249')
//    ..uExpectData(length,4)
        ..uExpectStatus(200);
    });
    test('can see folder index ', myBody( () async {
      var tr = TestRequest();
      await tr.get('/2017-08/index.tsv',accept:'text/tab-separated-values')
        ..uExpectHeader('content-type','tab-separated-values')
        ..uExpectText('IMG_20170827zz_085827249')
//    ..uExpectData(length,4)
        ..uExpectStatus(200);
    }));
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

  },);
}


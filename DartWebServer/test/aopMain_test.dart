/**
 * Created by Chris on 14/09/2018.
 */

//import 'dart:io';
//import 'dart:convert';
//import 'dart:async';
import 'package:test/test.dart';
import '../bin/aopMain.dart' as aopApp;
import 'aopTestSupport.dart';
//import 'package:test_api/src/backend/invoker.dart' as Fred;


void main() {
  setUp(() async {
    await aopApp.main(['testConfig.json']);
  });

  tearDown(() async {
   // print('teardown ');
    await aopApp.mainServer.close(force: true);
    aopApp.mainServer = null;
  });
  group('aopServer-', () {
    test('should not see root ',  () async {
      var tr = TestRequest();
      var tr2 = await tr.get('/',accept:'text/html');
      tr2.uExpectHeader('content-type','text/html');
      tr2.uExpectText('Not Found');
//    ..uExpectData(length,4)
      tr2.uExpectStatus(404);
    });
    test('should not see folder ',  () async {
      var tr = TestRequest();
      await tr.get('/2017-08',accept:'text/tab-separated-values')
        ..uExpectHeader('content-type','text/html')
        ..uExpectText('Not Found')
//    ..uExpectData(length,4)
        ..uExpectStatus(404);
    });
//    test('can see folder index ',  () async {
//      var tr = TestRequest();
//      await tr.get('/2017-08/index.tsv',accept:'text/tab-separated-values')
//        ..uExpectHeader('content-type','tab-separated-values')
//        ..uExpectText('IMG_20170827_085827249')
////    ..uExpectData(length,4)
//        ..uExpectStatus(200);
//    });
    test('can fail softly for bad folder ',  () async {
      var tr = TestRequest();
      await tr.get('/badname',accept: 'text/html')
        ..uExpectStatus(404);
    });
    test('can fail softly for bad file ',  () async {
      var tr = TestRequest();
      await tr.get('/2017-08/badname.jpg',accept:'text/html')
        ..uExpectStatus(404);
    });
    test('can fail softly for bad folder and file ',  () async {
      var tr = TestRequest();
      await tr.get('/badname/badname.json',accept:'text/html')
        ..uExpectText('Not Found')
        ..uExpectStatus(404);
    });
    test('post file ',  () async {
      var tr = TestRequest();
      await tr.get('/2011-11/badname.jpg',accept:'text/html',putData:[1,2,4,8])
        ..uExpectText('Written /2011-11/badname.jpg')
        ..uExpectStatus(200);
    });
  },);
}


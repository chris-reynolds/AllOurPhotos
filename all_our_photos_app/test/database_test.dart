/**
 * Created by Chris on 14/09/2018.
 * *
 * unit testing for the database layer
 */

import 'package:test/test.dart';
import '../lib/dbAllOurPhotos.dart';
import '../lib/aopClasses.dart';
import 'dart:io' as Io;


DbAllOurPhotos dbAop;

Io.Directory testDataDirectory;

void main() {
  setUp(() async {
    dbAop = DbAllOurPhotos();
    await dbAop.initConnection();
    testDataDirectory = Io.Directory('${Io.Directory.current.parent.path}/testdata');
  });

  tearDown(() async {
    // print('teardown ');
    dbAop.close();
    dbAop = null;
  });
  group('User', () {
    test('delete admin if exists',() async {
      List<AopUser> adminUsers = await userProvider.getSome('name="admin"');
      for (var user in adminUsers)
        await user.delete();
      adminUsers = await userProvider.getSome('name="admin"');
      expect(0,adminUsers.length,reason:'Expecting no admin users');
    });
    test('list users ', () async {
      var users = await userProvider.getSome('1=1');
      expect(users.length, 2);
    });
    test('get user 1', () async {
      AopUser user = await userProvider.get(1);
      expect(user.name,'chris');
    });
    test('add user ', () async {
      AopUser user = AopUser();
      user.name = 'admin';
      user.hint = 'admin00';
      int lastId = await user.save();
      print('inserted id is $lastId');
      AopUser adminUser = await userProvider.get(lastId);
      expect(adminUser.name,'admin');
      await adminUser.delete();
    });
    // todo find out how to hand exceptions in unit tests
/*    test('check unique user name', () async {
      AopUser oldUser = await userProvider.get(1);
      AopUser newUser = AopUser();
      newUser.name = oldUser.name;
      newUser.hint = oldUser.hint;
      try {
        int lastId = await newUser.save();
      } catch (ex) {
        print('Exception****************** $ex');
        expect(null,ex,reason:'duplicate user');
      }
    }); */

  }); // of User Group
  group('Image', ()  {
    test('Scrub snaps', () async {
      List<AopSnap> testSnaps = await snapProvider.getSome('import_source="test script"');
      for (var testSnap in testSnaps) {
        (await testSnap.fullImage).delete();
        await testSnap.delete();
      }
    }); // of scrub snaps
    test('Save image from file', () async {
      Io.File testFile = Io.File('${testDataDirectory.path}/test.jpg');
      List<int> contents = testFile.readAsBytesSync();
      AopFullImage image = AopFullImage();
      image.contents = contents;
      //image.snap_id = 99;
      int insertId = await image.save();
      AopSnap snap = AopSnap();
      snap.directory = '${testDataDirectory.path}';
      snap.fileName = 'test.jpg';
      snap.importSource = 'test script';
      snap.fullImageId = insertId;
      insertId = await snap.save();
    });  // of save image as file
  }); // of Image Group
} // of main



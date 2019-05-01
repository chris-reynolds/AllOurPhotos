/**
 * Created by Chris on 14/09/2018.
 * *
 * unit testing for the database layer
 */

import 'package:test/test.dart';
import '../lib/shared/dbAllOurPhotos.dart';
import '../lib/shared/aopClasses.dart';
import '../lib/dart_common/Config.dart';
import 'dart:io' as Io;


DbAllOurPhotos dbAop;

Io.Directory testDataDirectory;

int insertedSnapId_forAlbum;
void main() {
  setUp(() async {
    loadConfig();
    dbAop = DbAllOurPhotos();
    await dbAop.initConnection(config);
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
      insertedSnapId_forAlbum = insertId;
    });  // of save image as file
  }); // of Image Group
  group('Albums',() {
    test('Clean All albums',() async {
      List<AopAlbum> testAlbums = await albumProvider.getSome('name like "test%"');
      for (var testAlbum in testAlbums) {
        List<AopAlbumItem> items = await testAlbum.albumItems;
        items.forEach((item) async => await item.delete());
        await testAlbum.delete();
      }
    }); // of Clean All albums test
    test('Create album',() async {
      AopAlbum newAlbum = AopAlbum();
      newAlbum.name = 'test 1';
      await newAlbum.save();
      List<AopAlbum> testAlbums = await albumProvider.getSome('name like "test%"');
      expect(testAlbums.length,1,reason:'Created one test album after scrubbing');
    }); // of Create album test
    test('Create album item',() async {
      AopAlbum newAlbum = AopAlbum();
      newAlbum.name = 'test 2';
      int newAlbumId = await newAlbum.save();
      AopAlbumItem item = AopAlbumItem();
      item.snapId = insertedSnapId_forAlbum;
      item.albumId = newAlbumId;
      await item.save();
    }); // of Create album item test
  }); // of Albums group
} // of main



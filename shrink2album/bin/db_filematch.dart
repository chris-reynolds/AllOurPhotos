import 'dart:io';
import 'package:mysql1/mysql1.dart';

MySqlConnection dbConn2;
int lineNo = 0;
int found = 0;
int errors = 0;
int currentAlbumId = -1;
String currentAlbumName = 'Nothing';

void main(List<String> args) async {
  try {
    await dbConnect();
    var lines = File('shrinklist.txtd').readAsLinesSync();
    for (String line in lines) {
      var bits = line.split('\t');
      var albumName = bits[0];
      var filename = bits[1];
      var thisDate = DateTime.parse(bits[3]);
      int photoId = await getPhotoId(filename, thisDate);
      if (photoId > 0) {
        found++;
        int albumId = await getAlbumId(fullAlbumName(albumName));
        var sql =
            'insert into aopalbum_items(album_id,snap_id) values($albumId,$photoId);';
        Results newItem = await dbConn2.query(sql);
        if (newItem.affectedRows != 1) {
          errors++;
        }
      }
      lineNo++;
    }
    print('Processed $lineNo lines and found $found but $errors errors');
  } catch (e, s) {
    stderr.writeln('Exception in line $lineNo : $e\n $s');
  }
}

Future<void> dbConnect() async {
  var settings = ConnectionSettings(
      host: '192.168.1.199',
      port: 3306,
      user: 'photos',
      password: 'photos00',
      db: 'allourphotos');
  dbConn2 = await MySqlConnection.connect(settings);
  await dbConn2
      .query('select spsessioncreate("chris","chris00","shrink2album");');
  //print('No of rows at start = ${qry}');
} // of dbConnect

String fullAlbumName(String s) => 'shrink $s';

Future<int> getAlbumId(String albumName) async {
  if (currentAlbumName != albumName) {
    var qry =
        await dbConn2.query('select id from aopalbums where name="$albumName"');
    if (qry.isEmpty) {
      // we will need to create it
      // stuff
      var sql = 'insert into aopalbums(name) values("$albumName");';
      Results newAlbum = await dbConn2.query(sql);
      if (newAlbum.affectedRows != 1) {
        throw 'stuff';
      } else {
        currentAlbumId = newAlbum.insertId;
      }
    } else {
      currentAlbumId = qry.first.first as int;
    }

    currentAlbumName = albumName;
  }
  return currentAlbumId;
}

Future<int> getPhotoId(String filename, DateTime thisDate) async {
  for (int dys in [30, 90, 180]) {
    var sql =
        'select max(id) from aopsnaps where file_name like "$filename%" and ${calcSqlDateRange(thisDate, dys)}';
    Results photoId = await dbConn2.query(sql);
    if (photoId.isNotEmpty && photoId.first.first != null) {
      return photoId.first.first;
    }
  }
  return 0; // not found
}

String calcSqlDateRange(DateTime thisDate, int dayCount) =>
    ' taken_date between "${thisDate.add(Duration(days: -dayCount))}" and "${thisDate.add(Duration(days: dayCount))}"';

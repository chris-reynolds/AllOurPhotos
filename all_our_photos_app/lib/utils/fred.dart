import 'dart:async';
import 'dart:io';
import 'package:mysql1/mysql1.dart';

Future main() async {
  // Open a connection (testdb should already exist)
  final conn = await MySqlConnection.connect(new ConnectionSettings(
      host: '192.168.1.251', port: 3306, user: 'photos', password:'photos00', db: 'allourphotos'));

  List<int> picContents = [49,50,51,52];

  picContents = File('pubspec.lock').readAsBytesSync();
  await conn.query('drop table if exists users');

  // Create a table
  await conn.query(
      'CREATE TABLE users (id int NOT NULL AUTO_INCREMENT PRIMARY KEY, name varchar(255), email varchar(255), age int, media blob)');

  // Insert some data
  var result = await conn.query(
      'insert into users (name, email, age, media) values (?, ?, ?, ?)',
      ['Bob', 'bob@bob.com', 25,picContents]);
  print("Inserted row id=${result.insertId}");

  // Query the database using a parameterized query
  var results = await conn
      .query('select name, email,media from users where id = ?', [result.insertId]);
  Blob fred;
  for (var row in results) {
    print('Name: ${row[0]}, email: ${row[1]}, media: ${row[2]}');
    picContents = row[2].toBytes();
    var sink = File('./pubspecccc.lock').openWrite();
    sink.add(picContents);
   // sink.flush();
    sink.close();
  }

  // Finally, close the connection
  await conn.close();
}
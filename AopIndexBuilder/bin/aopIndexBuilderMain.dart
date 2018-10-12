
import 'dart:io';
import 'package:AopIndexBuilder/IndexBuilder.dart';
import 'package:AopIndexBuilder/Logger.dart' as log;
import 'package:AopIndexBuilder/IndexScanner.dart' as IndexScanner;

//final photoDir = 'C:\\projects\\AllOurPhotos\\testdata\\';
final photoDir = 'P:\\photos\\';
myLogger(String s) {
  stdout.writeln('${DateTime.now()} : $s');
}  // myLogger

main(List<String> arguments) async {
  log.onMessage = myLogger;
  log.logLevel = log.eLogLevel.llMessage; // show messages and errors for now
  IndexBuilder ib = IndexBuilder(photoDir);
  await ib.buildAll();
  await IndexScanner.justdoit();
  ib.save();
}

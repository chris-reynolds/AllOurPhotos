
import 'dart:io';
import 'package:AopIndexBuilder/IndexBuilder.dart';
import 'package:AopIndexBuilder/Logger.dart' as log;
import 'package:AopIndexBuilder/IndexScanner.dart' as IndexScanner;
myLogger(String s) {
  stdout.writeln('${DateTime.now()} : $s');
}  // myLogger

main(List<String> arguments) async {
  log.onMessage = myLogger;
  log.logLevel = log.eLogLevel.llMessage; // show messages and errors for now
  IndexBuilder ib = IndexBuilder('C:\\projects\\AllOurPhotos\\testdata\\');
  await ib.buildAll();
  IndexScanner.justdoit();
  ib.save();
}

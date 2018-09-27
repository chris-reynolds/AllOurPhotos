
import 'dart:io';
import 'package:AopIndexBuilder/IndexBuilder.dart';
import 'package:AopIndexBuilder/Logger.dart' as log;
myLogger(String s) {
  stdout.writeln(s);  
}  // myLogger

main(List<String> arguments) {
  log.message = myLogger;
  IndexBuilder ib = IndexBuilder('C:\\projects\\AllOurPhotos\\testdata\\');
  ib.buildAll();
}

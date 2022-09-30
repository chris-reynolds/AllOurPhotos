// import 'package:shrink2album/shrink2album.dart' as shrink2album;
import 'dart:io';

int lineNo = 0;
int badLineCount = 0;
List<String> outLines = [];

void main(List<String> args) {
  if (args.isEmpty) throw "crap";
  var lines = File(args[0]).readAsLinesSync();
  for (String line in lines) {
    try {
      processLine(line);
    } catch (e, s) {
      stderr.writeln('Error in line $lineNo : $line \n $e \n $s ');
    }
  }
  print('#zzzFinished. $badLineCount bad lines of $lineNo');
  File('${args[0]}b').writeAsStringSync(outLines.join('\n'));
} // of main

void processLine(String line) {
  lineNo++;
  line = line.replaceAll('/shrink/', '/');
  List<String> bits = line.split('/');
  if (bits.length > 1) {
    String filename = bits.last.substring(7);
    String dirname = bits[bits.length - 2].replaceAll('_', '-');

    if (dirname.length == 6 && int.tryParse(dirname) != null) {
      dirname = dirname.substring(0, 4) + '-' + dirname.substring(4, 6);
    }
    String albumName = dirname;
    if (dirname.length == 7) {
      dirname += '-15'; // probably date
    } else {
      if (int.tryParse(dirname.substring(0, 4)) != null) {
        dirname = '${dirname.substring(0, 4)}-06-01'; // starts with year
      }
      if (albumName == 'josie annie') dirname = '2007-01-01';
      if (albumName == 'uk and tucson') dirname = '2012-09-15';
      if (albumName == 'peugot') dirname = '2012-07-26';
      if (albumName == 'facebook') dirname = '2011-12-25';
      if (albumName == 'lakes') dirname = '2008-06-01';
      if (albumName.startsWith('dubai')) dirname = '2008-09-01';
      if (albumName == 'facebook') albumName = 'christmas 2011';
    }
    var myDate = DateTime.tryParse(dirname);
    if (myDate == null) {
      // maybe year is one higher
      dirname = bits[bits.length - 3];
      if (dirname.startsWith('2')) {
        // probably a year
        myDate = DateTime(int.parse(dirname.substring(0, 4)), 6, 1);
      }
    }
    if (myDate == null) {
      print('$albumName,$filename,$dirname, BAD DATE $line');
      badLineCount++;
    } else {
      if (albumName.length == 10 && DateTime.tryParse(albumName) != null) {
        albumName = albumName.substring(0, 7);
      }
      print('$albumName\t$filename\t$dirname\t$myDate\t$line');
      outLines.add('$albumName\t$filename\t$dirname\t$myDate\t$line');
    }
  }
//  print('Entered line: $line ');
}

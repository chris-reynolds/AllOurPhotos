import 'dart:io';

void main(List<String> args) {
  String lastPic = '';
  String thisPic = '';
  var inLines = File('shrinklist.txtc').readAsLinesSync();
  List<String> outLines = [];
  for (var line in inLines) {
    var bits = line.split('\t');
    if (bits.length > 2) {
      thisPic = bits[1].toUpperCase();
      if (thisPic != lastPic) {
        lastPic = thisPic;
        outLines.add(line);
      }
    }
  }
  File('shrinklist.txtd').writeAsStringSync(outLines.join('\n'));
}

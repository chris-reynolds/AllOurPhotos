import 'dart:io';
import 'package:exifdart/exifdart.dart';

Future<String> show(String imageFileName) async {
  List<String> result = [];
  File imgFile = File(imageFileName);
  if (imgFile.existsSync()) {
    MemoryBlobReader mbr = MemoryBlobReader(imgFile.readAsBytesSync());
    var tags = await readExif(mbr);
    tags['UserComment'] ='';
    tags['MakeNote'] = '';
    tags.forEach((k,v){
//      v = v.toString().replaceAll('\0','').trimRight();
      result.add ('$k $v');
    });
    return result.join('\n');
  } else
    return '$imageFileName not found';
}

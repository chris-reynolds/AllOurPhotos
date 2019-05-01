/**
 * Created by Chris on 25/09/2018.
 */
@TestOn("vm")
import 'package:test/test.dart';
import 'package:AopIndexBuilder/JpegLoader.dart';
//import 'package:AopIndexBuilder/ImgFile.dart';
import 'dart:io';

const String TESTFILENAME = "C:\\projects\\AllOurPhotos\\testdata\\2017-08\\IMG_20170827_085827249.jpg";

void main() {
  test("JPEG Loader", () async {
    var jpegLoader = JpegLoader();
    await jpegLoader.extractTags(File(TESTFILENAME).readAsBytesSync());
    var tagList = jpegLoader.tags;
    var keys = List<String>.of(tagList.keys);
    File fred = File('tags.txt');
    fred.writeAsString(keys.join("\n"));
    expect(tagList['Model'].toString().replaceAll('\x00', ''), equals('Moto E (4)'));
//    var newFile = ImgFile('dirrr','fileeeeeeeeeeee');
//    jpegLoader.saveToImgFile(newFile);
//    expect((newFile.latitude*1000).round(),equals(-37634));
  });
}
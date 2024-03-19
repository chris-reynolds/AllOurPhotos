/*
  Created by chrisreynolds on 28/02/20
  
  Purpose: This tries to encapsulate the IOGallery as a list with a start date

*/
import 'dart:io';
import 'dart:typed_data';
import 'package:aopcommon/aopcommon.dart';
import 'package:flutter/services.dart';
//photo_manager import 'package:photo_manager/photo_manager.dart' as PM;

class GalleryItem {
  Uint8List data;
  String id;
  DateTime createdDate;
  JpegLoader loader;
  GalleryItem(this.data, this.id, this.createdDate, this.loader);

  String get safeFilename {
    String temp = id.replaceAll('/', '_');
    temp = temp.replaceAll('\'', '-');
    if (temp.length > 30 && !temp.contains('.')) {
      temp = "ios${formatDate(createdDate, format: 'yyyymmdd_hhnnss')}.jpg";
    }
    if (!temp.contains('.')) temp = "$temp.jpg";
    return temp;
  } // safe_id
}

class IosGallery {
  DateTime startDate = DateTime(1980);
  String error = '';
  //JpegLoader _jpegLoader = JpegLoader();
  //bool _isLoaded = false;
  // List<PM.AssetEntity> _items = [];
  var _items = [];
  int get count => _items.length;

  Future<void> loadFrom(DateTime startDate) async {
    startDate = startDate.add(Duration(
        hours: -48)); // todo: get the time zone as IosGallery uses utc dates
    log.debug('IOS Gallery querying from ${dbDate(startDate)}');
    // startDate = DateTime.now();
    this.startDate = startDate;
    //   var dateFilter = PM.FilterOptionGroup(
    //       createTimeCond: PM.DateTimeCond(min: startDate, max: DateTime.now()));
    //   PM.AssetPathEntity root = (await PM.PhotoManager.getAssetPathList(
    //       onlyAll: true, filterOption: dateFilter))[0];
    //   _items =
    //       await root.getAssetListRange(start: 0, end: await root.assetCountAsync);
  }

  Future<GalleryItem?> operator [](int index) async {
    if (index < 0 || index >= count) return null;
    var item = _items[index];
    var ff = (await item.originFile)!;
    var ff2 = await ff.readAsBytes();
    var jpegLoader = JpegLoader();
    await jpegLoader.extractTags(ff2);
    log.debug('tags = ${jpegLoader.tags.length}');
    // var jpegBytes = (await item
    //     .thumbnailDataWithSize(PM.ThumbnailSize(item.width, item.height)))!;
    Uint8List jpegBytes = Uint8List(1); //photo_manager
    var createdDate = fromSwiftDate(item.createDateSecond!);
    var galleryItem = GalleryItem(jpegBytes, item.id, createdDate, jpegLoader);
    log.debug(
        'loading $index size of ${galleryItem.safeFilename} is ${galleryItem.data.length}');
    var file = await item.file;
    if (Platform.isIOS && file!.existsSync()) // IOS picture file is temporary
      file.deleteSync();
    return galleryItem;
  }

  DateTime fromSwiftDate(int swiftNo) {
    log.debug('from swift ms $swiftNo');
    DateTime baseDate = DateTime(1970);
    DateTime newDate = baseDate
        .add(Duration(milliseconds: (1000 * swiftNo).floor()))
        .toLocal();
    return newDate;
  }

  int toSwiftDate(DateTime thisDate) {
    DateTime baseDate = DateTime(1970);
    Duration d = thisDate.difference(baseDate);
    return d.inSeconds;
  }

  void clearCollection() async {
    for (var item in _items) {
      var file = (await item.file)!;
      if (file.existsSync()) file.deleteSync();
    }
    _items = [];
//    await _channel.invokeMethod<int>('clearCollection');
  }
} // of IosGallery

/*
  Created by chrisreynolds on 28/02/20
  
  Purpose: This tries to encapsulate the IOGallery as a list with a start date

*/

import 'dart:typed_data';
import 'package:flutter/services.dart';



class GalleryItem {
  Uint8List data;
  String id;
  DateTime createdDate;

  GalleryItem(this.data, this.id, this.createdDate);

  String get safeFilename {
    String temp = id.replaceAll('/', '_');
    temp = temp.replaceAll('\'', '-');
    if (temp.length > 20) temp = temp.substring(temp.length - 19);
    if (!temp.contains('.')) temp = temp + '.jpg';
    return temp;
  } // safe_id
}

class IosGallery {
  DateTime startDate;
  String error = '';
  bool _isLoaded = false;
  int count = 0;
  final _channel = MethodChannel("/gallery");

  Future<void> loadFrom(startDate) async {
    this.startDate = startDate;
    count = await _channel.invokeMethod<int>("getCountFromDate", toSwiftDate(startDate));
  }

  Future<GalleryItem> operator [](int index) async {
    if (index < 0 || index >= count) return null;
    var channelResponse = await _channel.invokeMethod("getItem", index);
    var dict = Map<String, dynamic>.from(channelResponse);
    var galleryItem = GalleryItem(dict['data'], dict['id'], fromSwiftDate(dict['created']));
    print('loading $index size of ${galleryItem.safeFilename} is ${galleryItem.data.length}');
    return galleryItem;
  }

  DateTime fromSwiftDate(int swiftNo) {
    print('from swift ms $swiftNo');
    DateTime baseDate = DateTime(1970);
    DateTime newDate = baseDate.add(Duration(milliseconds: (1000 * swiftNo).floor())).toLocal();
    return newDate;
  }

  int toSwiftDate(DateTime thisDate) {
    DateTime baseDate = DateTime(1970);
    Duration d = thisDate.difference(baseDate);
    return d.inSeconds;
  }
} // of IosGallery

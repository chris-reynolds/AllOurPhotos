/*
 * Copyright (c) 2019 Razeware LLC
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * Notwithstanding the foregoing, you may not use, copy, modify, merge, publish,
 * distribute, sublicense, create a derivative work, and/or sell copies of the
 * Software in any work that is designed, intended, or marketed for pedagogical or
 * instructional purposes related to programming, coding, application development,
 * or information technology.  Permission for such use, copying, modification,
 * merger, publication, distribution, sublicensing, creation of derivative works,
 * or sale is expressly withheld.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */

import 'package:flutter/material.dart';
import '../GalleryImage.dart';
import 'package:flutter/services.dart';
import 'package:aopcommon/aopcommon.dart';


DateTime fromSwift(int swiftNo ) {
  log.message('from swift ms $swiftNo');
  DateTime baseDate = DateTime(1970);
  DateTime newDate = baseDate.add(Duration(milliseconds: (1000*swiftNo).floor())).toLocal();
  return newDate;
}

int toSwift(DateTime thisDate ) {
  DateTime baseDate = DateTime(1970);
  Duration d = thisDate.difference(baseDate);
  return d.inSeconds;
}

class MultiGallerySelectPage extends StatefulWidget {
  const MultiGallerySelectPage({Key? key}) : super(key: key);

  @override
  createState() => _MultiGallerySelectPageState();
}

class _MultiGallerySelectPageState extends State<MultiGallerySelectPage> {
  final _numberOfColumns = 4;
  final _title = "Gallery";
  final _channel = MethodChannel("/gallery");

  final _selectedItems = <GalleryImage>[];
  final _itemCache = <int, GalleryImage>{};

  Future<GalleryImage?> _getItem(int index) async {
// 1
    if (_itemCache[index] != null) {
      return _itemCache[index];
    } else {
      // 2
      var channelResponse = await _channel.invokeMethod("getItem", index);
      // 3
      var item = Map<String, dynamic>.from(channelResponse);

      // 4
      var galleryImage = GalleryImage(
          bytes: item['data'],
          id: item['id'],
          dateCreated: fromSwift(item['created']),
          location: item['location']);
      log.message('$index size of ${galleryImage.id} is ${galleryImage.bytes.length}');
      // 5
      _itemCache[index] = galleryImage;

      // 6
      return galleryImage;
    }
  }

  _selectItem(int index) async {
    var galleryImage = (await _getItem(index))!;
    log.message('clicking ${galleryImage.id}');
    setState(() {
      if (_isSelected(galleryImage.id)) {
        _selectedItems.removeWhere((anItem) => anItem.id == galleryImage.id);
      } else {
        _selectedItems.add(galleryImage);
      }
    });
  }

  _isSelected(String id) {
    return _selectedItems.where((item) => item.id == id).isNotEmpty;
  }

  // TODO: replace with actual image count
  int? _numberOfItems = 0;

  @override
  void initState() {
    super.initState();
    DateTime startingOn = DateTime(2000,02,25);
    _channel.invokeMethod<int>("getCountFromDate",toSwift(startingOn)).then((count) => setState(() {
//    _channel.invokeMethod<int>("getItemCount").then((count) => setState(() {
      _numberOfItems = count;
      log.message('Setting collection count to $count');
    }));
  }

  // TODO: Render image in card
  _buildItem(int index) => GestureDetector(
      onTap: () {
        _selectItem(index);
      },
      child: Card(
        elevation: 2.0,
        child: FutureBuilder(
            future: _getItem(index),
            builder: (context, snapshot) {
              GalleryImage item = snapshot?.data! as GalleryImage ;
              log.message('showing item ${item?.location} ${item?.dateCreated} ${item.safeFilename}');
              if (item != null) {
                return Container(
                  child: Image.memory(item.bytes, fit: BoxFit.cover),
            //      child: Text('${fromSwift(item.dateCreated)}'),
                  decoration: BoxDecoration(
                      border: Border.all(
                          color: Theme.of(context).primaryColor,
                          width: 2,
                          style: _isSelected(item.id)
                              ? BorderStyle.solid
                              : BorderStyle.none)),
                );
              }

              return Container();
            }),
      ));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_title),
      ),
      body: GridView.builder(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: _numberOfColumns),
          itemCount: _numberOfItems,
          itemBuilder: (context, index) {
            return _buildItem(index);
          }),
    );
  }
}

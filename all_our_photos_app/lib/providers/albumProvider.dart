import 'package:flutter/material.dart';
import 'package:aopmodel/aopmodel.dart';

class AlbumProvider with ChangeNotifier {
  AopAlbum? _aopAlbum;

  AopAlbum? get aopAlbum => _aopAlbum;

  void save() async {
    if (_aopAlbum == null) return;
    await _aopAlbum!.save();
    notifyListeners();
  } // of save

  void setAlbum(AopAlbum? album) {
    _aopAlbum = album;
    notifyListeners();
  }
}

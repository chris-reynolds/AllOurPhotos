/*
  Created by chrisreynolds on 2024-05-22
  
  Purpose: Provide a single snap and a list of snaps
*/

import 'package:aopcommon/aopcommon.dart';
import 'package:aopmodel/aop_classes.dart';
import 'package:flutter/material.dart';

class SnapProvider extends ChangeNotifier {
  final AopSnap _snap;
  AopSnap get snap => _snap;
  SnapProvider(this._snap) : super();
  void save() async {
    await _snap.save();
    notifyListeners();
  } // of save
} // of SnapProvider

class SnapListProvider extends ChangeNotifier {
  late List<AopSnap> _snapList;
  List<AopSnap> get snapList => _snapList;
  set snapList(List<AopSnap> newList) {
    _snapList = newList;
    notifyListeners();
  }

  SnapListProvider(this._snapList) : super();

  void addSnap(AopSnap snap) {
    _snapList.add(snap);
    notifyListeners();
  }

  void removeSnap(AopSnap snap) {
    _snapList.remove(snap);
    notifyListeners();
  }

  Future<void> updateSnap(AopSnap snap) async {
    try {
      snap.save();
      notifyListeners();
    } catch (ex) {
      log.error(ex.toString());
      rethrow;
    }
  }
}  // of SnapListProvider

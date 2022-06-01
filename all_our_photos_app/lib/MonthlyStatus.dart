/*
  Created by chris reynolds on 30/05/22
  
  Purpose: Central Global for handling the status of each Month

*/
import 'package:flutter/material.dart';

import 'utils/PersistentMap.dart';
import 'package:aopcommon/aopcommon.dart';

PersistentMap _monthlyStatus;

String currentUser;

class MonthlyStatus {
  static Future<void> init() async {
    currentUser = (config['sesuser'] as String).substring(0,1); // first letter
    _monthlyStatus = PersistentMap('monthly.txt');
    await _monthlyStatus.load();
  }

  static bool read(int yearNo,int monthNo) {
    if (_monthlyStatus == null)
      throw 'Monthly status not initialised';
    return _monthlyStatus[yearNo*100+monthNo].contains(currentUser);
  }
  static void write(int yearNo,int monthNo,bool newValue) {
    String stored = _monthlyStatus[yearNo * 100 + monthNo];
    bool oldValue = stored.contains(currentUser);
    if (oldValue == newValue) return; // nothing to change
    if (oldValue) stored = stored.replaceAll(currentUser, '');
    if (newValue) stored += currentUser;
    _monthlyStatus[yearNo * 100 + monthNo] = stored;
    _monthlyStatus.save().then((success) {
      if (!success) throw 'failed to write monthly progress';
    });
  } // write

  static IconData icon(int yearNo,int monthNo) {
    if (_monthlyStatus[yearNo*100+monthNo].isEmpty)
      return Icons.image;
    else if (_monthlyStatus[yearNo*100+monthNo]=='c')
      return Icons.elderly;
    else if (_monthlyStatus[yearNo*100+monthNo]=='j')
      return Icons.woman;
    else
      return Icons.mood;
  }
} // of MonthlyStatus
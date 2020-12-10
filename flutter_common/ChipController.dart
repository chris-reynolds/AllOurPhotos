/*
  Created by chrisreynolds on 2019-11-27
  
  Purpose: This is a central point for managing the chips used for annotation photos.

*/

import 'package:flutter/material.dart';
import 'package:aopcommon/aopcommon.dart';
import '../utils/WebFile.dart';

final String DEFAULT_CHIPS = "+,-,Annie,Ben,Josie,J+K,E+M,Sunset,Camping,Reynwars,Williams";
String remoteUrl;
bool logging = false;
WebFile remoteChipFile;

class ChipSet {
  static final DELIM = ',';
  Set<String> chips;

  ChipSet(String s) {
    if (s == null || s == '') {
      chips = <String>{};
    } else {
      chips = s.split(DELIM).toSet();
    }
    if (logging) {
      log.message('${chips.length} chips from ($s)');
    }
  }

  void add(String value) => chips.add(value);

  bool contains(String value) => chips.contains(value);

  void remove(String value) => chips.remove(value);

  void addAll(ChipSet more) => chips.addAll(more.chips);

  String toString() => chips.join(DELIM);
} // of chipSet

class ChipSetSummary {
  int _total = 0;
  Map<String,int> items = {};
  ChipSetSummary(ChipSet defaults) {
    defaults.chips.forEach((chip){
      items[chip] = 0;  //dont count base
    });
  }
  void merge(ChipSet chipset) {
    chipset.chips.forEach((chip){
      if (items.containsKey(chip))
        items[chip] += 1;
      else
        items[chip] = 1;
    });
    _total += 1;
  }
  eCoverage coverage(String chip) {
    if (!items.containsKey(chip) || _total==0)
      throw Exception('Invalid call for Chip ($chip)');
    var _usage = items[chip];
    if (_usage==0) return eCoverage.ecNone;
    else if (_usage==_total) return eCoverage.ecAll;
    else return eCoverage.ecSome;
  }  // of coverage
} // of ChipSetSummary


abstract class ChipController {
  static set remoteLocation(String url) => remoteUrl = url;

  static set enableLogging(bool value) => logging = value;

  static Future<ChipSet> load() async {
    remoteChipFile = await loadWebFile(remoteUrl, DEFAULT_CHIPS);
    return ChipSet(remoteChipFile.contents);
  }

  static Future<bool> save(ChipSet chips) async {
    remoteChipFile.contents = chips.toString();
    bool result = await saveWebFile(remoteChipFile, silent: true);
    if (logging) {
      log.message('Saving (${remoteChipFile.contents}) to ${remoteChipFile.url} result=$result');
    }
    return result;
  } // of save

}

enum eCoverage { ecNone, ecSome, ecAll }

Color coverageColor(eCoverage value) {
  if (value == eCoverage.ecNone)
    return Colors.red;
  else if (value == eCoverage.ecSome)
    return Colors.orange;
  else if (value == eCoverage.ecAll)
    return Colors.green;
  else
    return Colors.white;
}

String coverageText(eCoverage value) {
  switch (value) {
    case eCoverage.ecAll:
      return 'All';
    case eCoverage.ecSome:
      return 'Some';
    case eCoverage.ecNone:
      return 'None';
    default:
      return '??';
  }
} // coveragetext

class TriChip extends StatefulWidget {
  String _name;
  eCoverage _cover;

  TriChip(this._name, this._cover) : super();

  @override
  _TriChipState createState() => _TriChipState();
}

class _TriChipState extends State<TriChip> {
  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: CircleAvatar(
        backgroundColor: coverageColor(widget._cover),
        child: Text(coverageText(widget._cover)),
      ),
      label: Text(widget._name),
    );
  }
}

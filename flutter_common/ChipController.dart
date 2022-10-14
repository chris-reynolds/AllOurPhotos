/*
  Created by chrisreynolds on 2019-11-27
  
  Purpose: This is a central point for managing the chips used for annotation photos.

*/

//import 'package:flutter/material.dart';
import 'package:aopcommon/aopcommon.dart';
//import '../utils/WebFile.dart';

const String DEFAULT_CHIPS = "+,-,Annie,Ben,Josie,J+K,E+M,Sunset,Camping,Reynwars,Williams";
String remoteUrl;
bool logging = false;
WebFile remoteChipFile;

class ChipSet {
  static const DELIM = ',';
  Set<String> chips;

  ChipSet(String s) {
    if (s == null || s == '') {
      chips = <String>{};
    } else { // now extra tags with extraneous spaces
      var arr = s.split(DELIM);
      for (int ix=0; ix<arr.length; ix++) arr[ix] = arr[ix].trim();
      chips = arr.toSet();
    }
    if (logging) {
      log.message('${chips.length} chips from ($s)');
    }
  }

  bool add(String value) => chips.add(value.trim());

  bool contains(String value) => chips.contains(value.trim());

  bool remove(String value) => chips.remove(value.trim());

  void addAll(ChipSet more) => chips.addAll(more.chips);

  @override
  String toString() => chips.join(DELIM);
} // of chipSet

class ChipSetSummary {
  // ignore: unused_field
  int _total = 0;
  Map<String,int> items = {};
  ChipSetSummary(ChipSet defaults) {
    for (var chip in defaults.chips) {
      items[chip] = 0;  //dont count base
    }
  }
  void merge(ChipSet chipset) {
    for (var chip in chipset.chips) {
      if (items.containsKey(chip))
        items[chip] = items[chip]??0 + 1;
      else
        items[chip] = 1;
    }
    _total += 1;
  }
  /*
  eCoverage coverage(String chip) {
    if (!items.containsKey(chip) || _total==0)
      throw Exception('Invalid call for Chip ($chip)');
    var usage = items[chip];
    if (usage==0) return eCoverage.ecNone;
    else if (usage==_total) return eCoverage.ecAll;
    else return eCoverage.ecSome;
  }  // of coverage
  */

} // of ChipSetSummary


abstract class ChipProvider {
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
/*
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
  final String _name;
  final eCoverage _cover;

  const TriChip(this._name, this._cover) : super();

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
*/
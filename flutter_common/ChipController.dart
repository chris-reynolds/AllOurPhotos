/*
  Created by chrisreynolds on 2019-11-27
  
  Purpose: This is a central point for managing the chips used for annotation photos.

*/

import '../dart_common/WebFile.dart';
import '../dart_common/Logger.dart' as Log;


final String DEFAULT_CHIPS = "+,-,Annie,Ben,Josie,J+K,E+M,Sunset,Camping,Reynwars,Williams";
String remoteUrl;
bool logging = false;
WebFile remoteChipFile;

class ChipSet {
  static final DELIM = ',';
  Set<String> chips;
  ChipSet(String s) {
    if (s==null || s == '') {
      chips = <String>{};
    } else {
      chips = s.split(DELIM).toSet();
    }
    if (logging) {
      Log.message('${chips.length} chips from ($s)');
    }
  }
  void add(String value) => chips.add(value);
  bool contains(String value) => chips.contains(value);
  void remove(String value) => chips.remove(value);
  void addAll(ChipSet more) => chips.addAll(more.chips);
  String toString() => chips.join(DELIM);
}  // of chipSet

abstract class ChipController {
  static set remoteLocation(String url) => remoteUrl=url;
  static set enableLogging(bool value) => logging=value;
  static Future<ChipSet>load() async {
    remoteChipFile = await loadWebFile(remoteUrl, DEFAULT_CHIPS);
    return ChipSet(remoteChipFile.contents);
  }
  static Future<bool> save(ChipSet chips) async {
    remoteChipFile.contents = chips.toString();
    bool result = await saveWebFile(remoteChipFile,silent: true);
    if (logging) {
      Log.message('Saving (${remoteChipFile.contents}) to ${remoteChipFile.url} result=$result');
    }
    return result;
  } // of save

}


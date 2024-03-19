/// Config cmap using localstorage
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:aopcommon/aopcommon.dart' show log;

class Config {
  Map<String, dynamic> _map = {};
  final int id; // in case of multi
  bool dirty = false;
  String _key = 'config';
  SharedPreferences? _preferences;

  Config({this.id = 0});
  Iterable<String> get keys => _map.keys;

  void clear() => _map.clear();

  dynamic remove(Object? key) => _map.remove(key);

  dynamic operator [](Object? key) => _map[key];

  operator []=(Object key, dynamic value) {
    if (_map[key] == value) return;
    _map[key as String] = value;
    dirty = true;
  }

  void addAll(Map<String, dynamic> values) => _map.addAll(values);

  Future load(String skey) async {
    _key = skey;
    try {
      if (_preferences == null) {
        _preferences = await SharedPreferences.getInstance();
        _map = json.decode(_preferences?.getString(skey) ??
            '{"host":"localhost","port":"8000"}');
        log.debug('config has ${_map.length} entries');
      }
    } catch (ex) {
      log.error('failed get config $ex');
      // _map = Map<String,dynamic>[];
    }
  }

  Future save() async {
    if (_preferences != null) {
      await _preferences?.setString(_key, json.encode(_map));
    } else {
      throw Exception('Failed to save preferences');
    }
  }

  Map<String, dynamic> values() => _map;
} // of Config class

Config config = Config();

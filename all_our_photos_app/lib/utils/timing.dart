/// Created by Chris on 10/01/2019
import 'package:aopcommon/aopcommon.dart';

abstract class Timing {
  static final Map<String, DateTime> _timers = {};
  static DateTime start(String name) {
    DateTime now = DateTime.now();
    _timers[name] = now;
    return now;
  }

  static Duration check(String name) {
    DateTime now = DateTime.now();
    if (_timers[name] == null) throw "$name timer not found";
    return now.difference(_timers[name]!);
  } // of check

  static Duration stop(String name) {
    Duration result = check(name);
    _timers.remove(name); // delete once used
    return result;
  }

  static void logCheck(String name) =>
      log.message('Timing ms:$name  ${check(name).inMilliseconds}');
  static void logStop(String name) =>
      log.message('Timing ms:$name  ${stop(name).inMilliseconds}');
} // of timing
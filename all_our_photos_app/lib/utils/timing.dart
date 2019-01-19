

abstract class Timing {
  static Map<String,DateTime> _timers = {};
  static DateTime start(String name) {
    DateTime now = DateTime.now();
    _timers[name] = now;
    return now;
  }
  static Duration stop(String name) {
    DateTime now = DateTime.now();
    if (_timers[name] == null)
      throw "$name timer now found";
    DateTime started = _timers[name];
    _timers.remove(name); // delete once used
    return now.difference(started);
  }
  static void logStop(String name) => print('Timing ms:$name  ${stop(name).inMilliseconds}');
} // of timing
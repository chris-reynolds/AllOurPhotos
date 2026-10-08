/*
  Purpose: map the '@Place' caption tags to timezones, and work out how far a
  camera clock set to New Zealand time should be shifted to give local time at
  that place.

  The camera clock is a naive time with no zone.  It was set to NZ time, but it
  may not have followed NZ daylight saving, so two clock states are possible
  and both are reported:
    primary   the camera followed NZ time correctly
    alt       the camera stayed on the other NZ offset (forgot to change the clock)
  The shift is placeOffset - cameraOffset, so it is negative anywhere west of NZ.
*/

import 'dart:io';

import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

const homeZone = 'Pacific/Auckland';

class ZoneShift {
  final String zone;
  final int primaryMinutes, altMinutes;
  const ZoneShift(this.zone, this.primaryMinutes, this.altMinutes);
}

class PlaceZones {
  final Map<String, String> _zones = {}; // lower-case tag -> IANA zone

  /// Loads tag,zone,note rows.  A blank zone leaves the tag unmapped.
  PlaceZones.fromFile(String path) {
    tzdata.initializeTimeZones();
    final lines = File(path).readAsLinesSync();
    for (final line in lines.skip(1)) {
      if (line.trim().isEmpty) continue;
      final cells = _splitCsv(line);
      if (cells.length < 2 || cells[1].trim().isEmpty) continue;
      final zone = cells[1].trim();
      try {
        tz.getLocation(zone);
      } catch (_) {
        throw FormatException('$path: unknown timezone "$zone" for tag "${cells[0]}"');
      }
      _zones[cells[0].trim().toLowerCase()] = zone;
    }
  }

  /// Exact tag first, then each comma-separated part from the last
  /// ('Pisa,Italy' -> 'Pisa,Italy', 'Italy', 'Pisa').
  String? zoneFor(String tag) {
    final lower = tag.toLowerCase();
    if (_zones.containsKey(lower)) return _zones[lower];
    for (final part in lower.split(',').reversed) {
      if (_zones.containsKey(part)) return _zones[part];
    }
    return null;
  }
}

/// [raw] is the camera's naive time, read as New Zealand local time.
ZoneShift expectedShift(String zoneName, DateTime raw) {
  final nz = tz.getLocation(homeZone);
  final place = tz.getLocation(zoneName);
  final nzLocal =
      tz.TZDateTime(nz, raw.year, raw.month, raw.day, raw.hour, raw.minute, raw.second);
  final nzOffset = nzLocal.timeZoneOffset.inMinutes;
  final placeOffset = tz.TZDateTime.fromMillisecondsSinceEpoch(
          place, nzLocal.millisecondsSinceEpoch)
      .timeZoneOffset
      .inMinutes;
  final otherNzOffset = nzOffset == 780 ? 720 : 780;
  return ZoneShift(zoneName, placeOffset - nzOffset, placeOffset - otherNzOffset);
}

/// Splits one CSV line, honouring double quotes.
List<String> _splitCsv(String line) {
  final out = <String>[];
  final cell = StringBuffer();
  var quoted = false;
  for (var i = 0; i < line.length; i++) {
    final ch = line[i];
    if (ch == '"') {
      if (quoted && i + 1 < line.length && line[i + 1] == '"') {
        cell.write('"');
        i++;
      } else {
        quoted = !quoted;
      }
    } else if (ch == ',' && !quoted) {
      out.add(cell.toString());
      cell.clear();
    } else {
      cell.write(ch);
    }
  }
  out.add(cell.toString());
  return out;
}

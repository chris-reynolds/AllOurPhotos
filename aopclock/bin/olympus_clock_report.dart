/*
  Purpose: READ-ONLY report on Olympus camera clock errors.

  The cameras' clocks were not always changed for daylight saving or when
  travelling, so some photos carry the wrong local time.  This script writes
  one CSV row per "segment" of photos (a run with the same applied correction
  and no gap of more than [gapDays]) saying what correction is already applied
  and what correction looks most plausible.  It changes nothing in the database.

  Definitions
    raw      metadata.DateTimeOriginal - the camera's clock, never altered.
             (original_taken_date is NOT reliable: earlier fixes shifted it too.)
    applied  taken_date - raw, i.e. the correction already in the database.
    best     the whole-hour shift from raw that makes the hours-of-day look most
             like real life (daylight shooting, little between midnight and 5am).

  Place tags
    A caption starting '@Place' names where the photo was taken.  place_zones.csv
    maps each tag to an IANA timezone, and the expected clock shift is then
    exact (placeOffset - NZ offset on that date, daylight saving included).
    Two clock states are reported - the camera followed NZ time, or it stayed on
    the other NZ offset - and the hours-of-day pick between them only when they
    clearly prefer the alternative.  Segments with no mapped tag fall back to the
    hours-of-day fit alone.  tagged_photos says how many photos the zone rests on;
    the rest of the segment is assumed to have been taken in the same place.

  Limits worth knowing
    - Hours-of-day cannot see a 1 hour error, so DST is only flagged through the
      nz_dst column and the phone hint, never decided.
    - Search range is -25..+2 hours: NZ is the easternmost zone, so anywhere
      else is behind it.  (+5 would equal -19 in hours but give the wrong date.)
    - Segments with fewer than [minPhotos] photos get low_confidence.

  Usage:  dart run bin/olympus_clock_report.dart --out ../analysis/olympus_clock_report.csv
          (database settings come from ../pyserver/config.json; override with
          --host, --port, --database, --user, --password;
          --zones overrides the place table, default place_zones.csv)
*/

import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:aopclock/place_zones.dart';
import 'package:mysql_client/mysql_client.dart';

// ---- tuning -----------------------------------------------------------------

/// Cameras to examine: matched on the EXIF Make, NOT device_name, which varies
/// by import path (e.g. 'mbp', 'olympus em10') and has stray spaces.
const cameraMakeSql = "json_value(metadata,'\$.Make') like 'OLYMPUS%'";

/// Reference devices whose clocks set themselves (phones, tablets).  Used only
/// for the phone_* hint columns.  Add or remove patterns to taste.
const referencePatterns = [
  'MI 9', 'INE-LX2', 'SM-G780G', 'Chris s20', 'GT-I9300', 'HTC%', 'Moto%',
  'Chris ipad', 'Janet%ipad', 'janets ipad', 'Pixel%', 'iPhone%',
];

/// A real clock or timezone correction is never this large.  A bigger gap means
/// taken_date was set deliberately (historic photos, scans whose EXIF holds the
/// scan date), so the row says nothing about the camera clock and is ignored.
const maxPlausibleShiftHours = 72;
const gapDays = 5; // a longer silence starts a new segment
const minPhotos = 8; // below this the histogram is too thin to trust
// Whole hours tried from raw.  Camera clocks are on NZ time and NZ is the
// easternmost timezone, so anywhere else is BEHIND (UK -11..-13, Arizona -19,
// Hawaii -23) and the only places AHEAD are Tonga/Samoa (+1..+2).  A shift of
// +5 gives the same hours as -19 but a different DATE, so positive shifts beyond
// +2 are deliberately not tried.
const minShift = -25, maxShift = 2;
/// Choose the 'alt' clock state (camera stayed on the other NZ offset) only when
/// the hours-of-day clearly prefer it: enough photos and a real cost advantage.
const altMinPhotos = 15;
const altMargin = 0.15;
const plateauTolerance = 0.05; // per-photo cost within this of the best "fits"
const needsFixMargin = 0.5; // per-photo cost the applied shift must exceed best by

/// Cost of a photo landing in each local hour of day (0..23).
/// 7am-8pm is normal, shoulders are mildly odd, 0-4am is very unlikely.
const hourCost = <double>[
  3, 3, 3, 3, 3, 1.5, 0.5, // 00-06
  0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // 07-19
  0.5, 1, 1.5, 3, // 20-23
];

// ---- model ------------------------------------------------------------------

class Row {
  final int id;
  final String directory, device;
  final DateTime raw; // camera clock (UTC-flagged only to avoid DST surprises)
  final DateTime taken; // adjusted local time stored in the database
  final String? tag; // '@Place' at the start of the caption, without the '@'
  Row(this.id, this.directory, this.device, this.raw, this.taken, this.tag);

  /// To the nearest minute: seconds of drift between the two columns are noise.
  Duration get applied =>
      Duration(minutes: (taken.difference(raw).inSeconds / 60).round());
}

class Segment {
  final List<Row> rows = [];
  Segment(Row first) {
    rows.add(first);
  }
  Row get first => rows.first;
  Row get last => rows.last;

  /// The most common applied correction.  Photos filed under different import
  /// paths can interleave in time, so a segment may hold a mix.
  Duration get applied {
    final counts = <Duration, int>{};
    for (final r in rows) counts[r.applied] = (counts[r.applied] ?? 0) + 1;
    return counts.entries.reduce((a, b) => b.value > a.value ? b : a).key;
  }

  /// "0h:120 1h:30" - every applied correction in the segment with its count.
  String get appliedMix {
    final counts = <Duration, int>{};
    for (final r in rows) counts[r.applied] = (counts[r.applied] ?? 0) + 1;
    final keys = counts.keys.toList()..sort();
    return keys.map((d) => '${_hours(d)}h:${counts[d]}').join(' ');
  }
}

extension SegmentTags on Segment {
  /// 'Singapore:30 Dubai:21' - place tags in the order first seen, with counts.
  String get tags {
    final counts = <String, int>{};
    for (final r in rows) {
      if (r.tag != null) counts[r.tag!] = (counts[r.tag!] ?? 0) + 1;
    }
    return counts.entries.map((e) => '${e.key}:${e.value}').join(' ');
  }

  /// The timezone of the segment's tagged photos: the IANA name when every
  /// mapped tag agrees, null when no tag is mapped, 'MIXED' when they disagree.
  String? get zone {
    final zones = {
      for (final r in rows)
        if (r.tag != null && places.zoneFor(r.tag!) != null) places.zoneFor(r.tag!)!
    };
    return zones.isEmpty ? null : (zones.length == 1 ? zones.first : 'MIXED');
  }

  /// Tags in this segment that the place table does not know.
  String get unmappedTags => {
        for (final r in rows)
          if (r.tag != null && places.zoneFor(r.tag!) == null) r.tag!
      }.join(' ');
}

/// Exactly +-1 hour applied: the signature of the 'mbp' import artifact (or an
/// interim bug while the software was being developed).  Whole hours only, so a
/// genuine small correction in minutes is not mistaken for it.
bool isOneHourArtifact(Row r) => r.applied.inMinutes.abs() == 60;

String _hours(Duration d) {
  final h = d.inMinutes / 60;
  return h.toStringAsFixed(h == h.roundToDouble() ? 0 : 2);
}

late PlaceZones places;

// ---- main -------------------------------------------------------------------

Future<void> main(List<String> args) async {
  final outPath = _arg(args, '--out') ?? '../analysis/olympus_clock_report.csv';
  places = PlaceZones.fromFile(_arg(args, '--zones') ?? 'place_zones.csv');
  final conn = await _connect(
      _arg(args, '--config') ?? '../pyserver/config.json', args);
  try {
    final rows = await _loadRows(conn);
    final reference = await _loadReference(conn);
    stdout.writeln('${rows.length} Olympus photos, '
        '${reference.length} reference-device photos');

    final segments = _segment(rows);
    final lines = <String>[_header.join(',')];
    for (final s in segments) {
      lines.add(_reportLine(s, reference).map(_csv).join(','));
    }
    File(outPath).writeAsStringSync('${lines.join('\n')}\n');
    stdout.writeln('${segments.length} segments written to $outPath');
  } finally {
    await conn.close();
  }
}

String? _arg(List<String> args, String name) {
  final i = args.indexOf(name);
  return (i >= 0 && i + 1 < args.length) ? args[i + 1] : null;
}

/// Settings come from the config file; --host, --port, --database, --user and
/// --password override them, e.g. --host rpi4.local to read production.
/// (mysql_client rather than mysql1: mysql1 mis-reads replies from MySQL 8.)
Future<MySQLConnection> _connect(String configPath, List<String> args) async {
  final db = jsonDecode(File(configPath).readAsStringSync())['db'];
  final host = _arg(args, '--host') ?? db['host'];
  final database = _arg(args, '--database') ?? db['database'];
  stdout.writeln('Reading $database on $host');
  final conn = await MySQLConnection.createConnection(
      host: host,
      port: int.tryParse(_arg(args, '--port') ?? '') ?? db['port'] ?? 3306,
      userName: _arg(args, '--user') ?? db['user'],
      password: _arg(args, '--password') ?? db['password'],
      databaseName: database,
      // MySQL 8 (the Pi) needs TLS for its default login; local MariaDB has none.
      secure: !const ['localhost', '127.0.0.1'].contains(host));
  await conn.connect();
  return conn;
}

// ---- loading ----------------------------------------------------------------

/// Datetimes are fetched as text and parsed as UTC so no timezone or DST
/// conversion ever touches a camera-local time.
DateTime? _parse(String s) =>
    DateTime.tryParse('${s.replaceFirst(' ', 'T')}Z');

String _like(String column, List<String> patterns) =>
    '(${patterns.map((p) => "$column like '$p'").join(' or ')})';

Future<List<Row>> _loadRows(MySQLConnection conn) async {
  final r = await conn.execute('''
    select id, directory, trim(json_value(metadata,'\$.Model')),
           json_value(metadata,'\$.DateTimeOriginal') as raw_exif,
           date_format(taken_date,'%Y-%m-%d %H:%i:%s'), caption
    from aopsnaps
    where $cameraMakeSql and taken_date is not null
      and json_value(metadata,'\$.DateTimeOriginal') is not null''');
  final out = <Row>[];
  var ignored = 0;
  for (final row in r.rows) {
    final exif = row.colAt(3) ?? ''; // "2019:01:03 17:43:19"
    final fixed = exif.replaceFirst(':', '-').replaceFirst(':', '-');
    final raw = _parse(fixed), taken = _parse(row.colAt(4) ?? '');
    if (raw == null || taken == null) {
      stderr.writeln(
          'skipping id ${row.colAt(0)}: bad date exif="$exif" taken="${row.colAt(4)}"');
      continue;
    }
    if (taken.difference(raw).inHours.abs() > maxPlausibleShiftHours) {
      ignored++;
      continue;
    }
    out.add(Row(int.parse(row.colAt(0)!), row.colAt(1) ?? '', row.colAt(2) ?? '',
        raw, taken, _tag(row.colAt(5))));
  }
  if (ignored > 0) {
    stdout.writeln('ignored $ignored photo(s) whose taken_date differs from EXIF '
        'by more than $maxPlausibleShiftHours h (historic/scanned)');
  }
  out.sort((a, b) => a.raw.compareTo(b.raw));
  return out;
}

/// Reference photos: only taken_date, which for these devices is local time.
Future<List<DateTime>> _loadReference(MySQLConnection conn) async {
  final r = await conn.execute('''
    select date_format(taken_date,'%Y-%m-%d %H:%i:%s') from aopsnaps
    where ${_like('device_name', referencePatterns)}
      and taken_date > '2000-01-01' and taken_date < now()
    order by taken_date''');
  return [
    for (final row in r.rows)
      if (_parse(row.colAt(0) ?? '') case final d?) d
  ];
}

/// '@Singapore at the hotel' -> 'Singapore'; null if the caption is not tagged.
String? _tag(String? caption) {
  if (caption == null || !caption.startsWith('@')) return null;
  final t = caption.substring(1).split(RegExp(r'\s')).first.trim();
  return t.isEmpty ? null : t;
}

// ---- segmenting -------------------------------------------------------------

/// Segments are built per camera MODEL (each has its own clock), splitting on
///   - a silence of [gapDays] or more, and
///   - a change of @place tag (untagged photos inherit the current place),
/// then neighbouring pieces that the same clock shift explains equally well are
/// merged back, so one trip is not shredded into a segment per village.
/// The applied correction is deliberately NOT a split point: photos from
/// different import paths interleave in time.
List<Segment> _segment(List<Row> rows) {
  final byModel = <String, List<Row>>{};
  for (final r in rows) (byModel[r.device] ??= []).add(r);
  final out = <Segment>[];
  for (final modelRows in byModel.values) {
    modelRows.sort((a, b) => a.raw.compareTo(b.raw));
    final pieces = <Segment>[];
    Segment? cur;
    String? curTag;
    for (final r in modelRows) {
      final gap = cur != null && r.raw.difference(cur.last.raw).inDays >= gapDays;
      final newPlace = r.tag != null && curTag != null && r.tag != curTag;
      if (cur == null || gap || newPlace) {
        cur = Segment(r);
        pieces.add(cur);
        curTag = r.tag;
      } else {
        cur.rows.add(r);
        curTag = r.tag ?? curTag;
      }
    }
    out.addAll(_mergeAgreeing(pieces));
  }
  out.sort((a, b) => a.first.raw.compareTo(b.first.raw));
  return out;
}

/// Merges a piece into its predecessor when the two are close in time and one
/// clock shift fits them together about as well as it fits each alone.
List<Segment> _mergeAgreeing(List<Segment> pieces) {
  const mergeSlack = 0.1; // extra per-photo cost tolerated by merging
  final merged = <Segment>[];
  for (final p in pieces) {
    if (merged.isNotEmpty) {
      final prev = merged.last;
      final close = p.first.raw.difference(prev.last.raw).inDays < gapDays;
      final zoneA = prev.zone, zoneB = p.zone;
      final bothMapped =
          zoneA != null && zoneB != null && zoneA != 'MIXED' && zoneB != 'MIXED';
      if (close && bothMapped) {
        // The place table is firmer evidence than the hours-of-day histogram.
        if (zoneA == zoneB) {
          prev.rows.addAll(p.rows);
          continue;
        }
      } else if (close) {
        final both = [...prev.rows, ...p.rows];
        final separate = (_fit(prev.rows).bestCost * prev.rows.length +
                _fit(p.rows).bestCost * p.rows.length) /
            both.length;
        if (_fit(both).bestCost <= separate + mergeSlack) {
          prev.rows.addAll(p.rows);
          continue;
        }
      }
    }
    merged.add(p);
  }
  return merged;
}

// ---- scoring ----------------------------------------------------------------

/// Mean cost per photo if the camera clock were shifted by [shiftHours].
double _cost(List<Row> rows, int shiftHours) {
  var sum = 0.0;
  for (final r in rows) {
    sum += hourCost[r.raw.add(Duration(hours: shiftHours)).hour];
  }
  return sum / rows.length;
}

/// As [_cost] for a shift in minutes (some zones are not whole hours).
double _costMinutes(List<Row> rows, int minutes) {
  var sum = 0.0;
  for (final r in rows) {
    sum += hourCost[r.raw.add(Duration(minutes: minutes)).hour];
  }
  return sum / rows.length;
}

/// Mean cost for the correction already in the database (may not be whole hours).
double _costApplied(Segment s) {
  var sum = 0.0;
  for (final r in s.rows) {
    sum += hourCost[r.taken.hour];
  }
  return sum / s.rows.length;
}

/// The run of consecutive shifts around the best one whose cost is within
/// [plateauTolerance] of the minimum.  Cost is flat across any shift that keeps
/// every photo inside daylight hours, so the honest answer is a range, not a
/// single number.  When the range is wide, [best] is the shift nearest zero.
({int lo, int hi, int best, double bestCost}) _fit(List<Row> rows) {
  final costs = {for (var s = minShift; s <= maxShift; s++) s: _cost(rows, s)};
  final bestCost = costs.values.reduce(min);
  bool fits(int s) => costs[s]! <= bestCost + plateauTolerance;
  // Prefer the fitting shift nearest zero (ties: the more negative).
  final candidates = [for (final s in costs.keys) if (fits(s)) s]
    ..sort((a, b) {
      final byAbs = a.abs().compareTo(b.abs());
      return byAbs != 0 ? byAbs : a.compareTo(b);
    });
  final best = candidates.first;
  var lo = best, hi = best;
  while (lo > minShift && fits(lo - 1)) lo--;
  while (hi < maxShift && fits(hi + 1)) hi++;
  return (lo: lo, hi: hi, best: best, bestCost: bestCost);
}

/// Hint from reference devices: the whole-hour shift that best lines up the
/// hours-of-day activity of the camera with that of the phones around the same
/// dates.  Returns null if the phones took too few photos to say anything.
({int shift, int phoneCount, double overlap})? _phoneHint(
    Segment s, List<DateTime> reference) {
  final from = s.first.raw.subtract(const Duration(days: 2));
  final to = s.last.raw.add(const Duration(days: 2));
  final phones = reference.where((d) => !d.isBefore(from) && !d.isAfter(to)).toList();
  if (phones.length < minPhotos) return null;

  List<double> hist(Iterable<int> hours) {
    final h = List<double>.filled(24, 0);
    for (final x in hours) h[x]++;
    final total = h.fold<double>(0, (a, b) => a + b);
    return [for (final v in h) v / total];
  }

  final phoneHist = hist(phones.map((d) => d.hour));
  var bestShift = 0;
  var bestOverlap = -1.0;
  for (var shift = minShift; shift <= maxShift; shift++) {
    final h = hist(s.rows.map((r) => r.raw.add(Duration(hours: shift)).hour));
    var overlap = 0.0;
    for (var i = 0; i < 24; i++) overlap += min(h[i], phoneHist[i]);
    if (overlap > bestOverlap + 1e-9 ||
        (overlap > bestOverlap - 1e-9 && shift.abs() < bestShift.abs())) {
      bestOverlap = overlap;
      bestShift = shift;
    }
  }
  return (shift: bestShift, phoneCount: phones.length, overlap: bestOverlap);
}

/// True when [d] (a New Zealand local date) falls in NZ daylight time:
/// last Sunday of September to first Sunday of April.
bool _nzDst(DateTime d) {
  DateTime lastSunday(int y, int m) {
    var x = DateTime.utc(y, m + 1, 0);
    while (x.weekday != DateTime.sunday) x = x.subtract(const Duration(days: 1));
    return x;
  }

  DateTime firstSunday(int y, int m) {
    var x = DateTime.utc(y, m, 1);
    while (x.weekday != DateTime.sunday) x = x.add(const Duration(days: 1));
    return x;
  }

  return d.isBefore(firstSunday(d.year, 4)) || !d.isBefore(lastSunday(d.year, 9));
}

// ---- output -----------------------------------------------------------------

const _header = [
  'segment', 'camera', 'first_taken', 'last_taken', 'photos', 'directories', 'places',
  'first_id', 'last_id',
  'applied_h', 'applied_mix', 'artifact_1h_photos', 'night_pct_now', 'cost_now',
  'source', 'zone', 'tagged_photos', 'zone_shift_h', 'alt_shift_h', 'cost_zone', 'cost_alt',
  'fit_lo_h', 'fit_hi_h', 'hist_agrees', 'suggested_h', 'change_needed_h',
  'photos_to_change', 'nz_dst', 'phone_shift_h', 'phone_photos', 'phone_overlap',
  'unmapped_tags', 'verdict',
];

int _segmentNo = 0;

List<Object?> _reportLine(Segment s, List<DateTime> reference) {
  _segmentNo++;
  final rows = s.rows;
  final appliedMin = s.applied.inMinutes;
  final costNow = _costApplied(s);
  final fit = _fit(rows);
  final phone = _phoneHint(s, reference);
  final night = rows.where((r) => r.taken.hour < 5).length * 100 / rows.length;
  final artifacts = rows.where(isOneHourArtifact).length;

  // Target shift from raw, in minutes, and where it came from.
  final zone = s.zone;
  ZoneShift? zs;
  double? costZone, costAlt;
  int targetMin;
  String source;
  if (zone != null && zone != 'MIXED') {
    // The place decides; the histogram only decides between the two clock states.
    zs = expectedShift(zone, rows[rows.length ~/ 2].raw);
    costZone = _costMinutes(rows, zs.primaryMinutes);
    costAlt = _costMinutes(rows, zs.altMinutes);
    final useAlt = rows.length >= altMinPhotos && costAlt + altMargin < costZone;
    targetMin = useAlt ? zs.altMinutes : zs.primaryMinutes;
    source = useAlt ? 'zone_alt' : 'zone';
  } else {
    // No usable place tag: hours-of-day fit.  Where +-1h import artifacts exist
    // and raw itself looks plausible, the fix is just to restore the EXIF time.
    final restoreRaw = artifacts > 0 && fit.lo <= 0 && fit.hi >= 0;
    targetMin = (restoreRaw ? 0 : fit.best) * 60;
    source = 'histogram';
  }

  final toChange = rows.where((r) => r.applied.inMinutes != targetMin).length;
  final onlyArtifactsChange = rows
      .where((r) => r.applied.inMinutes != targetMin)
      .every(isOneHourArtifact);

  String verdict;
  if (source != 'histogram') {
    verdict = toChange == 0
        ? 'ok'
        : (targetMin == 0 && onlyArtifactsChange ? 'RESTORE_RAW_1H' : 'NEEDS_FIX');
  } else if (targetMin == 0 && artifacts > 0 && toChange > 0 && onlyArtifactsChange) {
    verdict = 'RESTORE_RAW_1H';
  } else if (artifacts > 0) {
    verdict = 'NEEDS_FIX'; // +-1h photos in a segment that raw does not explain
  } else if (rows.length < minPhotos) {
    verdict = 'low_confidence';
  } else if (costNow - fit.bestCost > needsFixMargin) {
    verdict = appliedMin == 0 ? 'NEEDS_FIX' : 'APPLIED_BUT_LOOKS_WRONG';
  } else {
    verdict = 'ok';
  }
  // For anything not needing action the histogram fit is informational only.
  final actionable = const {'RESTORE_RAW_1H', 'NEEDS_FIX', 'APPLIED_BUT_LOOKS_WRONG'}
      .contains(verdict);

  // Does the place-derived shift fit the hours of day, allowing an hour of slack
  // (the cost surface is flat across daylight hours)?  Blank when too few photos.
  final targetH = targetMin / 60;
  final histAgrees = (source == 'histogram' || rows.length < minPhotos)
      ? ''
      : (targetH >= fit.lo - 1 && targetH <= fit.hi + 1 ? 'yes' : 'NO');

  final dirs = {for (final r in rows) r.directory}.toList()..sort();
  String h(num minutes) => _hours(Duration(minutes: minutes.round()));
  return [
    _segmentNo,
    s.first.device,
    _fmt(s.first.taken),
    _fmt(s.last.taken),
    rows.length,
    dirs.length == 1 ? dirs.first : '${dirs.first}..${dirs.last}',
    s.tags,
    s.first.id,
    s.last.id,
    h(appliedMin),
    s.appliedMix,
    artifacts,
    night.toStringAsFixed(0),
    costNow.toStringAsFixed(2),
    source,
    zone ?? '',
    rows.where((r) => r.tag != null).length,
    zs == null ? '' : h(zs.primaryMinutes),
    zs == null ? '' : h(zs.altMinutes),
    costZone?.toStringAsFixed(2) ?? '',
    costAlt?.toStringAsFixed(2) ?? '',
    fit.lo,
    fit.hi,
    histAgrees,
    h(targetMin),
    h(targetMin - appliedMin),
    actionable ? toChange : 0,
    _nzDst(s.first.taken) ? 'yes' : '',
    phone?.shift ?? '',
    phone?.phoneCount ?? '',
    phone == null ? '' : phone.overlap.toStringAsFixed(2),
    s.unmappedTags,
    verdict,
  ];
}

String _fmt(DateTime d) => d.toIso8601String().replaceFirst('T', ' ').substring(0, 16);

String _csv(Object? v) {
  final s = '${v ?? ''}';
  return s.contains(RegExp(r'[",\n]')) ? '"${s.replaceAll('"', '""')}"' : s;
}

/*
  aopFullExport
  Exports green (and optionally amber) photos from AllOurPhotos to a local
  directory, with captions baked into EXIF UserComment / ImageDescription.
  Restartable: files already present in the output directory are skipped.

  Usage:
    dart run bin/aopfullexport.dart \
      --host 192.168.1.10 --port 8000 \
      --user chris --password secret \
      --ranking green \
      --from 2020-01-01 --to 2025-12-31 \
      --output ./export \
      --dir-format year-month   # or: year
*/

import 'dart:convert';
import 'dart:io';
import 'package:args/args.dart';
import 'package:http/http.dart' as http;

// ---------------------------------------------------------------------------
// Main
// ---------------------------------------------------------------------------
void main(List<String> args) async {
  final parser = ArgParser()
    ..addOption('host', defaultsTo: 'localhost', help: 'Server hostname or IP')
    ..addOption('port', defaultsTo: '8000', help: 'Server port')
    ..addOption('user', abbr: 'u', help: 'Username (required)')
    ..addOption('password', abbr: 'p', help: 'Password (required)')
    ..addOption('ranking',
        defaultsTo: 'green',
        allowed: ['green', 'both'],
        help: 'green = green only (ranking=3); both = green+amber (ranking>=2)')
    ..addOption('from', defaultsTo: '1900-01-01', help: 'Start date inclusive, e.g. 2020-01-01')
    ..addOption('to', defaultsTo: '2050-01-01', help: 'End date inclusive, e.g. 2025-12-31')
    ..addOption('output', defaultsTo: './export', help: 'Output directory')
    ..addOption('dir-format',
        defaultsTo: 'year-month',
        allowed: ['year-month', 'year'],
        help: 'Sub-directory grouping: year-month (e.g. 2023-05) or year (e.g. 2023)')
    ..addFlag('help', abbr: 'h', negatable: false);

  ArgResults parsed;
  try {
    parsed = parser.parse(args);
  } catch (e) {
    stderr.writeln('Error: $e');
    _printUsage(parser);
    exit(1);
  }

  if (parsed['help'] as bool) {
    _printUsage(parser);
    exit(0);
  }

  final user = parsed['user'] as String?;
  final password = parsed['password'] as String?;
  if (user == null || user.isEmpty || password == null || password.isEmpty) {
    stderr.writeln('Error: --user and --password are required.');
    _printUsage(parser);
    exit(1);
  }

  final host = parsed['host'] as String;
  final port = parsed['port'] as String;
  final ranking = parsed['ranking'] as String;
  final fromDate = parsed['from'] as String;
  final toDate = parsed['to'] as String;
  final outputDir = parsed['output'] as String;
  final dirFormat = parsed['dir-format'] as String;
  final minRanking = (ranking == 'green') ? 3 : 2;

  final baseUrl = 'http://$host:$port';
  final client = http.Client();

  try {
    // 1. Login
    stdout.writeln('Connecting to $baseUrl...');
    final sessionId = await _login(client, baseUrl, user, password);
    final preserve = '{"jam":"$sessionId"}';
    stdout.writeln('Logged in as $user (session $sessionId)');

    // 2. Fetch all snap metadata (JSON only — fast)
    stdout.write('Fetching snap list...');
    final whereClause = _buildWhere(minRanking, fromDate, toDate);
    final allSnaps = await _fetchAllSnaps(client, baseUrl, preserve, whereClause);
    stdout.writeln(' ${allSnaps.length} found.');

    if (allSnaps.isEmpty) {
      stdout.writeln('Nothing to export.');
      return;
    }

    // 3. Check which files already exist locally
    await Directory(outputDir).create(recursive: true);

    final toDownload = <Map<String, dynamic>>[];
    int alreadyDone = 0;
    int remainingBytes = 0;

    for (final snap in allSnaps) {
      final fileName = snap['file_name'] as String? ?? 'unknown';
      final subDir = _subDirName(snap['taken_date'] as String?, dirFormat);
      if (File('$outputDir/$subDir/$fileName').existsSync()) {
        alreadyDone++;
      } else {
        toDownload.add(snap);
        remainingBytes += (snap['media_length'] as int? ?? 0);
      }
    }

    // 4. Summary and confirmation
    final totalCount = allSnaps.length;
    final remaining = toDownload.length;
    if (alreadyDone > 0) {
      stdout.writeln(
          '$totalCount total, $alreadyDone already downloaded, $remaining remaining (~${_formatBytes(remainingBytes)}).');
    } else {
      stdout.writeln('$totalCount to download (~${_formatBytes(remainingBytes)}).');
    }

    if (remaining == 0) {
      stdout.writeln('All files already downloaded.');
      return;
    }

    stdout.write('Proceed? [y/N] ');
    final answer = stdin.readLineSync()?.trim().toLowerCase() ?? '';
    if (answer != 'y') {
      stdout.writeln('Aborted.');
      return;
    }

    // 5. Download missing files
    int downloaded = 0;
    int errors = 0;

    for (final snap in toDownload) {
      final id = snap['id'] as int;
      final fileName = snap['file_name'] as String? ?? 'unknown';
      final subDir = _subDirName(snap['taken_date'] as String?, dirFormat);

      _printProgress(downloaded, remaining);

      try {
        List<int> bytes;
        try {
          bytes = await _downloadSnap(client, baseUrl, preserve, id);
        } catch (e) {
          // Server may have crashed processing EXIF — fall back to raw file
          final serverDir = snap['directory'] as String? ?? '';
          stderr.writeln('\n  export_snap failed for $id, trying raw: $e');
          bytes = await _downloadRaw(
              client, baseUrl, preserve, serverDir, fileName);
        }
        final dir = Directory('$outputDir/$subDir');
        await dir.create(recursive: true);
        final outFile = File('$outputDir/$subDir/$fileName');
        await outFile.writeAsBytes(bytes);
        final takenDate = _parseDate(snap['taken_date'] as String?);
        if (takenDate != null) await outFile.setLastModified(takenDate);
        downloaded++;
      } catch (e) {
        errors++;
        stderr.writeln('\nError downloading snap $id ($fileName): $e');
      }
    }

    _printProgress(downloaded, remaining);
    stdout.writeln('');
    stdout.writeln('Done. $downloaded downloaded, $errors errors. Output: $outputDir');
  } catch (e) {
    stderr.writeln('\nFatal error: $e');
    exit(1);
  } finally {
    client.close();
  }
}

// ---------------------------------------------------------------------------
// HTTP helpers
// ---------------------------------------------------------------------------

Future<int> _login(
    http.Client client, String baseUrl, String user, String password) async {
  final uri = Uri.parse('$baseUrl/ses/$user/$password/aopFullExport');
  final response = await client.get(uri);
  if (response.statusCode != 200) {
    throw 'Login failed (${response.statusCode}): ${response.body}';
  }
  final data = json.decode(response.body) as Map<String, dynamic>;
  final sessionId = int.parse(data['jam'] as String);
  if (sessionId < 0) throw 'Login failed: invalid credentials';
  return sessionId;
}

Future<List<Map<String, dynamic>>> _fetchAllSnaps(http.Client client,
    String baseUrl, String preserve, String where) async {
  final all = <Map<String, dynamic>>[];
  const pageSize = 200;
  int offset = 0;
  while (true) {
    final page = await _fetchSnaps(
        client, baseUrl, preserve, where, pageSize, offset);
    all.addAll(page);
    if (page.length < pageSize) break;
    offset += page.length;
  }
  return all;
}

Future<List<Map<String, dynamic>>> _fetchSnaps(http.Client client,
    String baseUrl, String preserve, String where, int limit, int offset) async {
  final params = {
    'where': where,
    'orderby': 'taken_date',
    'limit': '$limit',
    'offset': '$offset',
  };
  final uri = Uri.parse('$baseUrl/snaps/').replace(queryParameters: params);
  final response = await client.get(uri, headers: {'Preserve': preserve});
  if (response.statusCode != 200) {
    throw 'snaps fetch failed (${response.statusCode}): ${response.body}';
  }
  final list = json.decode(response.body) as List<dynamic>;
  return list.cast<Map<String, dynamic>>();
}

Future<List<int>> _downloadSnap(
    http.Client client, String baseUrl, String preserve, int id) async {
  final uri = Uri.parse('$baseUrl/export_snap/$id');
  final response = await client
      .get(uri, headers: {'Preserve': preserve})
      .timeout(const Duration(seconds: 120));
  if (response.statusCode == 200) return response.bodyBytes;
  throw 'HTTP ${response.statusCode}: ${response.body}';
}

Future<List<int>> _downloadRaw(http.Client client, String baseUrl,
    String preserve, String directory, String fileName) async {
  final uri = Uri.parse('$baseUrl/photos/$directory/$fileName');
  final response = await client
      .get(uri, headers: {'Preserve': preserve})
      .timeout(const Duration(seconds: 120));
  if (response.statusCode == 200) return response.bodyBytes;
  throw 'HTTP ${response.statusCode}: ${response.body}';
}

// ---------------------------------------------------------------------------
// Utilities
// ---------------------------------------------------------------------------

// Returns the sub-directory name derived from the DB taken_date field.
// taken_date arrives as an ISO-8601 string, e.g. "2023-05-15T00:00:00" or
// "2023-05-15 00:00:00". We only need the leading YYYY-MM (or YYYY) portion.
DateTime? _parseDate(String? s) {
  if (s == null || s.isEmpty) return null;
  // Server returns "YYYY-MM-DD HH:MM:SS" — DateTime.parse needs a 'T' separator
  return DateTime.tryParse(s.replaceFirst(' ', 'T'));
}

String _subDirName(String? takenDate, String format) {
  if (takenDate == null || takenDate.length < 7) return 'unknown';
  if (format == 'year') return takenDate.substring(0, 4);
  return takenDate.substring(0, 7); // YYYY-MM
}

String _buildWhere(int minRanking, String fromDate, String toDate) {
  return "ranking >= $minRanking"
      " AND taken_date >= '$fromDate'"
      " AND taken_date <= '$toDate'";
}

String _formatBytes(int bytes) {
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
  if (bytes < 1024 * 1024 * 1024) {
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
  return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
}

void _printProgress(int done, int total) {
  if (total == 0) return;
  final pct = (done * 100 ~/ total).clamp(0, 100);
  const barWidth = 30;
  final filled = (barWidth * done ~/ total).clamp(0, barWidth);
  final bar = '=' * filled +
      (filled < barWidth ? '>' : '') +
      ' ' * (barWidth - filled - (filled < barWidth ? 1 : 0));
  stdout.write('\r[$bar] $done/$total ($pct%)  ');
}

void _printUsage(ArgParser parser) {
  stdout.writeln('Usage: dart run bin/aopfullexport.dart [options]');
  stdout.writeln(parser.usage);
}

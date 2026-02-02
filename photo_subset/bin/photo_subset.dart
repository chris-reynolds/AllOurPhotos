import 'dart:io';
import 'package:args/args.dart';
import 'package:path/path.dart' as p;

/// Creates a smaller development subset of a photo collection.
///
/// For non-April months: uses thumbnails instead of full-size photos.
/// For April months: keeps full-size photos.
/// Preserves all subdirectories (thumbnails, metadata, etc.)
void main(List<String> arguments) async {
  final parser = ArgParser()
    ..addOption('source', abbr: 's', help: 'Source photos directory', mandatory: true)
    ..addOption('output', abbr: 'o', help: 'Output directory for dev subset', mandatory: true)
    ..addOption('thumbs-dir', abbr: 't', help: 'Thumbnails subdirectory name', defaultsTo: 'thumbnails')
    ..addFlag('dry-run', abbr: 'n', help: 'Show what would be done without copying', defaultsTo: false)
    ..addFlag('help', abbr: 'h', help: 'Show usage information', negatable: false);

  ArgResults args;
  try {
    args = parser.parse(arguments);
  } catch (e) {
    print('Error: $e');
    printUsage(parser);
    exit(1);
  }

  if (args['help']) {
    printUsage(parser);
    exit(0);
  }

  final sourcePath = args['source'] as String;
  final outputPath = args['output'] as String;
  final thumbsDir = args['thumbs-dir'] as String;
  final dryRun = args['dry-run'] as bool;

  final sourceDir = Directory(sourcePath);
  if (!await sourceDir.exists()) {
    print('Error: Source directory does not exist: $sourcePath');
    exit(1);
  }

  final outputDir = Directory(outputPath);
  if (!await outputDir.exists()) {
    if (dryRun) {
      print('Would create output directory: $outputPath');
    } else {
      await outputDir.create(recursive: true);
      print('Created output directory: $outputPath');
    }
  }

  print('');
  print('Photo Subset Creator');
  print('====================');
  print('Source: $sourcePath');
  print('Output: $outputPath');
  print('Thumbnails dir: $thumbsDir');
  print('Dry run: $dryRun');
  print('');

  // Find all month directories (YYYY-MM format)
  final monthPattern = RegExp(r'^\d{4}-\d{2}$');
  final monthDirs = <Directory>[];

  await for (final entity in sourceDir.list()) {
    if (entity is Directory) {
      final name = p.basename(entity.path);
      if (monthPattern.hasMatch(name)) {
        monthDirs.add(entity);
      }
    }
  }

  monthDirs.sort((a, b) => p.basename(a.path).compareTo(p.basename(b.path)));
  print('Found ${monthDirs.length} month directories');
  print('');

  int totalFilesCopied = 0;
  int totalBytesOriginal = 0;
  int totalBytesCopied = 0;

  for (final monthDir in monthDirs) {
    final monthName = p.basename(monthDir.path);
    final isApril = monthName.endsWith('-04');
    final destMonthDir = Directory(p.join(outputPath, monthName));

    print('Processing $monthName ${isApril ? "(April - keeping full size)" : "(using thumbnails)"}');

    if (!dryRun && !await destMonthDir.exists()) {
      await destMonthDir.create(recursive: true);
    }

    // Process main directory files
    final thumbsPath = p.join(monthDir.path, thumbsDir);
    final thumbsDirObj = Directory(thumbsPath);
    final thumbsExist = await thumbsDirObj.exists();

    // Build a map of thumbnail files for quick lookup
    final thumbnailMap = <String, File>{};
    if (!isApril && thumbsExist) {
      await for (final entity in thumbsDirObj.list()) {
        if (entity is File) {
          final baseName = p.basename(entity.path);
          thumbnailMap[baseName] = entity;
        }
      }
    }

    // Process files in main directory
    await for (final entity in monthDir.list()) {
      if (entity is File) {
        final fileName = p.basename(entity.path);
        final destFile = File(p.join(destMonthDir.path, fileName));
        final originalSize = await entity.length();
        totalBytesOriginal += originalSize;

        if (isApril) {
          // April: copy full-size file
          if (dryRun) {
            print('  Would copy (full): $fileName');
          } else {
            await entity.copy(destFile.path);
          }
          totalBytesCopied += originalSize;
          totalFilesCopied++;
        } else {
          // Non-April: use thumbnail if available, otherwise skip or copy original
          if (thumbnailMap.containsKey(fileName)) {
            final thumbFile = thumbnailMap[fileName]!;
            final thumbSize = await thumbFile.length();
            if (dryRun) {
              print('  Would copy (thumb): $fileName (${_formatSize(originalSize)} -> ${_formatSize(thumbSize)})');
            } else {
              await thumbFile.copy(destFile.path);
            }
            totalBytesCopied += thumbSize;
            totalFilesCopied++;
          } else {
            // No thumbnail found - check if it's a video or other file
            final ext = p.extension(fileName).toLowerCase();
            if (_isVideoFile(ext)) {
              // Videos are only copied for April months (handled above)
              print('  Skipping video (non-April): $fileName');
            } else if (_isImageFile(ext)) {
              print('  Warning: No thumbnail for image $fileName, skipping');
            } else {
              // Non-media file, copy as-is
              if (dryRun) {
                print('  Would copy (other): $fileName');
              } else {
                await entity.copy(destFile.path);
              }
              totalBytesCopied += originalSize;
              totalFilesCopied++;
            }
          }
        }
      } else if (entity is Directory) {
        // Copy subdirectories as-is
        final subDirName = p.basename(entity.path);
        final destSubDir = Directory(p.join(destMonthDir.path, subDirName));

        if (dryRun) {
          print('  Would copy directory: $subDirName/');
        } else {
          await _copyDirectory(entity, destSubDir);
        }
      }
    }
  }

  print('');
  print('Summary');
  print('=======');
  print('Files processed: $totalFilesCopied');
  print('Original size: ${_formatSize(totalBytesOriginal)}');
  print('Output size: ${_formatSize(totalBytesCopied)}');
  if (totalBytesOriginal > 0) {
    final reduction = ((1 - totalBytesCopied / totalBytesOriginal) * 100).toStringAsFixed(1);
    print('Size reduction: $reduction%');
  }
  if (dryRun) {
    print('');
    print('(Dry run - no files were actually copied)');
  }
}

void printUsage(ArgParser parser) {
  print('Usage: dart run photo_subset -s <source> -o <output> [options]');
  print('');
  print('Creates a smaller development subset of a photo collection.');
  print('For non-April months, thumbnails replace full-size photos.');
  print('April months keep full-size photos for testing with real data.');
  print('');
  print('Options:');
  print(parser.usage);
  print('');
  print('Example:');
  print('  dart run photo_subset -s C:\\photos -o C:\\photos_dev');
  print('  dart run photo_subset -s /mnt/photos -o /mnt/photos_dev --dry-run');
}

bool _isImageFile(String ext) {
  const imageExtensions = {
    '.jpg', '.jpeg', '.png', '.gif', '.bmp', '.webp', '.heic', '.heif'
  };
  return imageExtensions.contains(ext);
}

bool _isVideoFile(String ext) {
  const videoExtensions = {
    '.mp4', '.mov', '.avi', '.mkv', '.webm', '.m4v', '.3gp'
  };
  return videoExtensions.contains(ext);
}

String _formatSize(int bytes) {
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
  if (bytes < 1024 * 1024 * 1024) return '${(bytes / 1024 / 1024).toStringAsFixed(1)} MB';
  return '${(bytes / 1024 / 1024 / 1024).toStringAsFixed(2)} GB';
}

Future<void> _copyDirectory(Directory source, Directory destination) async {
  if (!await destination.exists()) {
    await destination.create(recursive: true);
  }

  await for (final entity in source.list(recursive: false)) {
    final destPath = p.join(destination.path, p.basename(entity.path));

    if (entity is File) {
      await entity.copy(destPath);
    } else if (entity is Directory) {
      await _copyDirectory(entity, Directory(destPath));
    }
  }
}

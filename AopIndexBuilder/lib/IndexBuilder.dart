/**
 * Created by Chris on 25/09/2018.
 */
import 'dart:io';
import 'dart:async';
import 'package:path/path.dart' as path;
import './Logger.dart' as log;
import './ImgFile.dart';
import './StringUtils.dart';
import './JpegLoader.dart';

class IndexBuilder {
  String rootDir;
  IndexBuilder(String this.rootDir) {
     log.message('Registered root '+rootDir);
  } // of constructor

  buildAll() async {
    List<FileSystemEntity> rootEntries = Directory(rootDir).listSync();
    for (FileSystemEntity fse in rootEntries) {
      var fseStat = fse.statSync();
      if (fseStat.type == FileSystemEntityType.directory)
        await buildDir(fse,fseStat.modified);
    }
  } // of buildAll

  buildDir(FileSystemEntity directory,DateTime dirModified) async {
    DateTime indexModified;
    bool indexScanRequired = true;
    bool indexWriteRequired = false;
    List<ImgFile> indexEntries = <ImgFile>[];

    log.message('Starting Directory '+directory.path+' '+dirModified.toString());
    File indexFile = File(path.join(directory.path,INDEX_FILENAME));
    if (indexFile.existsSync()) {
      indexScanRequired = indexFile.lastModifiedSync().isBefore(dirModified);
      List<String> lines = indexFile.readAsLinesSync();
      lines.removeAt(0); // remove header
      lines.forEach((thisLine) {
        ImgFile thisEntry = ImgFile('','');
        thisEntry.fromTabDelimited(thisLine);
        indexEntries.add(thisEntry);
      });
    } // of indexLoad
    indexWriteRequired = false;
    log.message('Index start count=${indexEntries.length}');
    JpegLoader jpegLoader = JpegLoader();
    List<FileSystemEntity> fileList  = Directory(directory.path).listSync();
    for (FileSystemEntity fse in fileList) {
      String targetFilename = path.basename(fse.path);
      // check for desire file type
      String blah = right(targetFilename,4);
      if (['.jpg','.mov'].indexOf(right(targetFilename,4).toLowerCase()) >= 0) {
        String targetDir = path.relative(path.dirname(fse.path), from: rootDir);
        ImgFile existingEntry;
        try {
          existingEntry = indexEntries.singleWhere((thisEntry) =>
          thisEntry.filename == targetFilename);
        } catch (e) {
          existingEntry = null;
        } // of try/catch
        // add new Entry to index if required
        if (existingEntry == null) {
          ImgFile newEntry = ImgFile(targetDir, targetFilename);
          File theFile = File(fse.path);
          await jpegLoader.loadBuffer(theFile.readAsBytesSync());
          jpegLoader.saveToImgFile(newEntry);
          newEntry.lastModifiedDate = fse.statSync().modified;
          indexEntries.add(newEntry);
          indexWriteRequired = true;
        }
      }
    }  // of fileList loop
    log.message('Index end count=${indexEntries.length}');
    if (indexWriteRequired) {
      saveIndex(directory, indexEntries);
      log.message('Index written');
    }
    log.message('Finishing Directory '+directory.path+' scan:$indexScanRequired');
  } // of buildDir

  saveIndex(FileSystemEntity directory, List<ImgFile> fileList) {
    List<String> lines = <String>[];
    lines.add(ImgFileHeader);
    fileList.forEach((file) {
        lines.add(file.toTabDelimited());
    });
    File indexFile = File(path.join(directory.path,INDEX_FILENAME));
    indexFile.writeAsStringSync(lines.join("\n"));
  }


} // of IndexBuilder
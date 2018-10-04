/**
 * Created by Chris on 25/09/2018.
 */
import 'dart:io';
import 'package:path/path.dart' as path;
import './Logger.dart' as log;
import './ImgFile.dart';
import './StringUtils.dart';
import './JpegLoader.dart';


String rootDir;

String absPath(String dirName,String filename) => path.join(rootDir,dirName,filename);

class IndexBuilder {
  IndexBuilder(String thisRootDir) {
    rootDir = thisRootDir;
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



void addFile(String originalFilename,List<int> imageBuffer) {
  log.message('import new file ' + originalFilename);
  try {
    ImgFile newImage = new ImgFile('xxxx', originalFilename);
    JpegLoader()
      ..loadBuffer(imageBuffer)
      ..saveToImgFile(newImage);
    String newDirectoryName = ImgDirectory.directoryNameForDate(
        newImage.takenDate);
    newImage.dirname = newDirectoryName;
    String tempFilename = path.join(newDirectoryName, originalFilename);
    log.message('Import into directory :' + newDirectoryName);
    if (saveFileAs(newImage, imageBuffer: imageBuffer) ) {
      ImgDirectory imgDirectory = ImgCatalog.getDirectory(newDirectoryName);
      imgDirectory.files.add(newImage);
      imgDirectory.dirty = true;
    }
  } catch (ex) {
     throw ex+' while adding $originalFilename';
  }
} // of addFile

    bool saveFileAs(ImgFile newImage, {List<int> imageBuffer, File fromFile}) {
      bool result = true;
      String targetName = newImage.filename;
      int tries = 0;
      while (tries < 10) {
        tries += 1;
        ImgDirectory imgDirectory = ImgCatalog.getDirectory(newImage.dirname);
        ImgFile previousFile = imgDirectory.getFile(targetName);
        String absFilename = absPath(newImage.dirname,newImage.filename);
        if (previousFile == null) { // not found
          if (fromFile != null)
            fromFile.renameSync(absFilename);
          else
            File(absFilename).writeAsBytesSync(imageBuffer, flush: true);
        } else if (previousFile.contentHash != newImage.contentHash) {
          targetName = newImage.filename + '_c$tries'; // try a new target name
        } else {
          log.message('skipped importing as a duplicate of $targetName');
          result = false;
          break;
        }
      } // of while loop
      if (result)
        newImage.filename = targetName;
      return result;
    } // of saveNewFile

    void importTempFile (String originalFilename, String tempPath) {
      log.message('import temp file ' + originalFilename);
      try {
        ImgFile newImage = new ImgFile(tempPath, originalFilename);
        String tempFilename = path.join(tempPath, originalFilename);
        File newFile = File(tempFilename);
        JpegLoader()
          ..loadBuffer(newFile.readAsBytesSync())
          ..saveToImgFile(newImage);
        String newDirectoryName = ImgDirectory.directoryNameForDate(newImage.takenDate);
        log.message('Import into directory :' + newDirectoryName);
        // let fullDirectoryName = FilenameHelper.calcFilename(newDirectoryName)
        ImgDirectory imgDirectory = ImgCatalog.getDirectory(newDirectoryName);
// now move file to correct directory
        String targetName = path.join(newDirectoryName,originalFilename);
        int tries = 0;
        while (tries < 10) {
          tries += 1;
          ImgFile previousFile = imgDirectory.getFile(originalFilename);
          if (previousFile == null) { // not found
            newFile.renameSync(targetName);
            imgDirectory.files.add(newImage);
          } else if (previousFile.contentHash != newImage.contentHash) {
            targetName = originalFilename + '_c$tries'; // try a new target name
          } else {
            log.message('skipped importing as a duplicate of ' + targetName);
            break;
          }
        } // of while loop
      } catch (err) {
        err.message += ': Error on importing ' + originalFilename;
        throw err;
/**/
      } // of try/catch
    } // of importTempFile

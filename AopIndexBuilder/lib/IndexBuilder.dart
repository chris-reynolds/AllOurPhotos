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
    ImgDirectory.save = saveDirectoryToFileStore;
    ImgFile.save = saveImageToDirectory;
  } // of constructor

  buildAll() async {
    List<FileSystemEntity> rootSubdirectories = Directory(rootDir).listSync()
        ..retainWhere((fse) => FileSystemEntity.isDirectorySync(fse.path));
    String currentDirList = '~';
    for (FileSystemEntity fse in rootSubdirectories) {
      String subDirectoryName = path.split(fse.path).removeLast();
      currentDirList = currentDirList + subDirectoryName + '~';
      ImgDirectory thisIndexDirectory = ImgCatalog.getDirectory(subDirectoryName);
      if (thisIndexDirectory == null)
        thisIndexDirectory = ImgCatalog.newDirectory(subDirectoryName);
      await matchDirectoryAndIndex(fse,thisIndexDirectory);
    } // of subdirec tory loop
    // now check the top level index

    String indexFilename = path.join(rootDir,'aopTop.txt');
    String oldFileContents = '';
    File topIndexFile = File(indexFilename);
    if (topIndexFile.existsSync())
      oldFileContents = topIndexFile.readAsStringSync();
    if (oldFileContents != currentDirList)
      topIndexFile.writeAsStringSync(currentDirList);
  } // of buildAll

  void matchDirectoryAndIndex(FileSystemEntity directory,ImgDirectory indexDirectory)  async {
    bool indexScanRequired = true;
    bool indexWriteRequired = false;

    log.message('Starting Directory ${directory.path}');
    File indexFile = File(path.join(directory.path,INDEX_FILENAME));
    if (indexFile.existsSync()) {
      indexScanRequired = indexFile.lastModifiedSync().isBefore(indexDirectory.modifiedDate);
      List<String> lines = indexFile.readAsLinesSync();
       if (!indexDirectory.fromStrings(lines))
         log.error('Errors found while loading ${directory.path}');
      indexDirectory.modifiedDate = indexFile.lastModifiedSync();
    } // of indexLoad
    indexWriteRequired = false;
    log.message('Index start count=${indexDirectory.files.length}');
    JpegLoader jpegLoader = JpegLoader();
    List<FileSystemEntity> fileList  = Directory(directory.path).listSync();
    for (FileSystemEntity fse in fileList) {
      String targetFilename = path.basename(fse.path);
      // check for desire file type
      if (['.jpg','.movx'].indexOf(right(targetFilename,4).toLowerCase()) >= 0) {
        String targetDir = path.relative(path.dirname(fse.path), from: rootDir);
        ImgFile existingEntry = indexDirectory[targetFilename];
        // add new Entry to index if required
        if (existingEntry == null) {
          ImgFile newEntry = ImgFile(targetDir, targetFilename);
          File theFile = File(fse.path);
          await jpegLoader.loadBuffer(theFile.readAsBytesSync());
          if (jpegLoader.tags != null)
            jpegLoader.saveToImgFile(newEntry);
          newEntry.lastModifiedDate = fse.statSync().modified;
          indexDirectory.files.add(newEntry);
          indexWriteRequired = true;
        }
      }
    }  // of fileList loop
    log.message('Index end count=${indexDirectory.files.length}');
    if (indexWriteRequired) {
      saveDirectoryToFileStore(indexDirectory);
      indexWriteRequired = false;
      log.message('Index written');
    }
    log.message('Finishing Directory '+directory.path+' scan:$indexScanRequired');
  } // of buildDir

  save() {
    ImgCatalog.saveAll();
  }  // of save

} // of IndexBuilder

bool saveDirectoryToFileStore(ImgDirectory thisDirectory) {
  List<String> lines = thisDirectory.toStrings();
  File indexFile = File(absPath(thisDirectory.directoryName,INDEX_FILENAME));
  indexFile.writeAsStringSync(lines.join("\n"));
  thisDirectory.dirty = false;
  return true;
} // of saveDirectoryToFileStore

bool saveImageToDirectory(ImgFile thisFile) {
  ImgDirectory dir;
  if (thisFile.directory == null)  // make new directory if required
    dir = ImgCatalog.newDirectory(thisFile.dirname);
  else
    dir = thisFile.directory;
  ImgFile currentEntry = dir[thisFile.filename];
  if (currentEntry == null)
    dir.files.add(thisFile);
  dir.dirty = true;
  return true;
} // of saveImageToDirectory

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

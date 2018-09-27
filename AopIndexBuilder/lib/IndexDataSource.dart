/**
 * Created by Chris on 21/09/2018.
 */
import 'dart:core';
import 'dart:async';
import './Logger.dart' as log;

abstract class IndexDataSource {
  bool exists(String path)  {}
  Map stat(String path)  {}
  bool delete(String path)  {}
  List dirList(String path) {}
  void moveFile(String oldPath, String newPath) {}
  void forceDirectory(String path) {}
  List<int> readFile(String path) {}
  bool saveFile(String path,String fileType,Object data) {}
} // of IndexDataSource

IndexDataSource fs;

class FsFile {
  FsFile ({String this.filename, String this.directoryPath,
  DateTime this.createdOn, DateTime this.modifiedOn}) {
  } // of constructor
  String filename;
  String directoryPath;
  DateTime createdOn;
  DateTime modifiedOn;
} // of FsClass

class FsDirectory {
  bool _isLoaded = false;
  DateTime _modifiedDate;
  List<FsDirectory> _directories  = <FsDirectory>[];
  List<FsFile> _files  = <FsFile>[];
  String path = '';
  FsDirectory parent;

  FsDirectory (String path, [FsDirectory parent] )  {
    this.path = path;
    this.parent = parent;
    if (fs.exists(path)) {
      Map stats = fs.stat(path);
      if (stats['isDirectory']){
        this._modifiedDate = stats['modified'];
      } else {
        throw(this.path+ 'is a file not a directory');
      }
    } else {
      throw('Directory not found for ' + this.path);
    }
  } // of fromPath

  void loadDirectAndFiles()  {
    if (! this._isLoaded) {  // check one time only
      this._directories.length = 0;   //ensure empty
      this._files.length = 0;
      List fileNames = fs.dirList(path);
     fileNames.forEach((thisFile) {
        String fullName = path + '/' + thisFile;
        Map stats = fs.stat(fullName);
        if (stats['isDirectory'])
          directories.add(new FsDirectory(thisFile, this));
        else {
          DateTime createdOn  = stats['created'];
          DateTime modifiedOn  = stats['modified'];
          createdOn = (createdOn.isAfter(modifiedOn)) ? modifiedOn : createdOn;
          files.add(FsFile(filename: thisFile, directoryPath: this.fullPath,
          createdOn: createdOn, modifiedOn:modifiedOn ));
        }
      }); // of file loop
      this._isLoaded = true;
    } // of first time
  } // of loadDirectAndFiles

  List<FsDirectory> get directories {
    this.loadDirectAndFiles();
    _directories;
  } // of directories

  List<FsFile> get files {
    loadDirectAndFiles();
    return _files;
  } // of files

  String get fullPath {
    return  (parent?.path ?? '')+path;
  }

  walk(callback) {
    this.files.forEach((thisFile) => callback(thisFile));
    this.directories.forEach((thisDirectory) => thisDirectory.walk(callback));
  } // of walk

}  // of FSDirectory


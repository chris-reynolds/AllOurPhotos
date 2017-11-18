// provide getDirectories and getFiles
import * as fs from 'fs'




export class FsFile {
  constructor (public fileName:string, public directoryPath:string,
               public createdOn : Date, public modifiedOn : Date) {
  } // of constructor
} // of FsClass

export class FsDirectory {
    private _isLoaded : boolean = false;
    private _modifiedDate : Date;
    private _directories : Array<FsDirectory> = [];
    private _files : Array<FsFile> = [];
    private _fullpath = '';
    public static OS_Separator : string = '\\'
    constructor (public path: string,public parent: FsDirectory = null) {
        if (path.indexOf('/')>=0)
            FsDirectory.OS_Separator = '/';
        if (parent)
          this._fullpath = parent._fullpath+FsDirectory.OS_Separator+this.path;
        else
            this._fullpath = this.path;
        if (fs.existsSync(this._fullpath)) {
          let stats = fs.statSync(this._fullpath);
          if (stats.isDirectory()){
              this._modifiedDate = stats.mtime
          } else {
              throw new Error(this._fullpath+ 'is a file not a directory');
          }
        } else {
            throw new Error('Directory not found for ' + this._fullpath);
        }
    } // of constructor

    loadDirectAndFiles() :void {
      if (! this._isLoaded) {  // check one time only
        this._directories.length = 0;   //ensure empty
        this._files.length = 0;
        let fileNames = fs.readdirSync(this._fullpath);
        for (let fileIx = 0; fileIx < fileNames.length; fileIx++) {
          let fullName = this._fullpath + FsDirectory.OS_Separator + fileNames[fileIx];
          let stats = fs.lstatSync(fullName);
          if (stats.isDirectory())
            this._directories.push(new FsDirectory(fileNames[fileIx], this));
          else {
              let createdOn :Date = stats.birthtime
              let modifiedOn :Date = stats.mtime
              createdOn = (createdOn>modifiedOn) ? modifiedOn : createdOn
              this._files.push({'fileName': fileNames[fileIx], 'directoryPath': this.fullPath,
                'createdOn': createdOn, 'modifiedOn':modifiedOn });
          }
        } // of file loop
        this._isLoaded = true;
      } // of first time
    }; // of loadDirectAndFiles

    get directories() :Array<FsDirectory> {
      this.loadDirectAndFiles();
      return this._directories;
    } // of directories

    get files() : Array<FsFile> {
      this.loadDirectAndFiles();
      return this._files;
    } // of files

    get fullPath() {
        return  this._fullpath;
    }

    walk(callback) {
      this.files.forEach((thisFile) => callback(thisFile));
      this.directories.forEach((thisDirectory) => thisDirectory.walk(callback));
    } // of walk

}  // of FSDirectory

export class FsHelper {
  static deleteFile(fileName:string):void {
    try {
      fs.unlinkSync(fileName)
    } catch(e) {
      // swallow
    }
  } // of deleteFile

} // of FsHelper
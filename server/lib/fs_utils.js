// provide getDirectories and getFiles
let fs = require('fs');

class FSDirectory {
    constructor (root,parent) {
        this._sep = '\\'; // windows
        this._isLoaded = false;
        this._directories = [];
        this._files = [];
        this._fullpath = '';
        this._root = root;
        this._parent = parent;
        if (parent)
          this._fullpath = parent._fullpath+this._sep+this._root;
        else
            this._fullpath = this._root;
        if (fs.existsSync(this._fullpath)) {
          let stats = fs.statSync(this._fullpath);
          if (!stats.isDirectory())
              throw new Error(this._fullpath+ 'is a file not a directory');
        } else {
            throw new Error('Directory not found for ' + this._fullpath);
        }
    } // of constructor

    loadDirectAndFiles() {
      if (! this._isLoaded) {
        this._directories = [];
        this._files = [];
        let fileNames = fs.readdirSync(this._fullpath);
        for (let fileIx = 0; fileIx < fileNames.length; fileIx++) {
          let fullName = this._fullpath + this._sep + fileNames[fileIx];
          let stats = fs.statSync(fullName);
          if (stats.isDirectory(fullName))
            this._directories.push(new FSDirectory(fileNames[fileIx], this));
          else
            this._files.push({'fileName': fileNames[fileIx], 'fullName': fullName, 'stats': stats});
        } // of file loop
        this._isLoaded = true;
      } // of first time
    }; // of loadDirectAndFiles

    directories() {
      this.loadDirectAndFiles();
      return this._directories;
    } // of directories

    files() {
      this.loadDirectAndFiles();
      return this._files;
    } // of files

    path() {
        return  this._fullpath;
    }

    walk(callback) {
      this.files.forEach((thisFile) => callback(thisFile));
      this.directories.forEach((thisDirectory) => thisDirectory.walk(callback));
    } // of walk

}  // of FSDirectory


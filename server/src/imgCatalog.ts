import * as fs from 'fs'
import * as _  from 'lodash'
import {FsFile,FsDirectory} from './fs_utils'

class FilenameHelper {
    static root : string
    static sep : string
    static get separator() {
        if (process.cwd().indexOf('\\')>=0)
            return '\\'
        else
            return '/'
    } // of separator
    static calcFilename(path:string,name:string):string {
        return FilenameHelper.root + FilenameHelper.separator + path + FilenameHelper.separator + name
    }
}

class YearProfile {
    year :string
    months : string[]
} // of yearProfile

export default class ImgCatalog {
    private _rootDir : FsDirectory
    private directories : ImgDirectory[] = [];
    constructor(rootDir:FsDirectory) {
        this._rootDir = rootDir
        FilenameHelper.root = rootDir.fullPath
        rootDir.directories.forEach(thisDirectory => this.directories.push(new ImgDirectory(thisDirectory)))
    }
    getDirectory(dirName):ImgDirectory {
        let idx = _.findIndex(this.directories,['directoryName',dirName])
        return idx>-1 ? this.directories[idx] : null
    } // of getDirectory

    getYear(selectedYear) :YearProfile {
        let result = new YearProfile()
        result.year = selectedYear
        result.months = []
        this.directories.forEach(function (directory) {
            let thisYear = directory.directoryName.substr(0,4)
            let thisMonth = directory.directoryName.substr(5,2);
            if (thisYear==selectedYear && result.months.indexOf(thisMonth)==-1)
                result.months.push(thisMonth)
        }) // of foreach
        result.months.sort();
        return result
    } // of getYear

    getYears() : string[] {
        let result = []
        this.directories.forEach(function (directory) {
            let thisYear = directory.directoryName.substr(0,4)
            if (result.indexOf(thisYear)==-1)
                result.push(thisYear)
        }) // of foreach

        result = result.sort()
  //      for (let i=0;i<result.length;i++)
  //          result[i] = this.getYear(result[i]);
        return result;
    }  // of years

    addImage(stuff:string) {

    } // add Image

}  // of ImgCatalog

export class ImgDirectory {
  private static INDEXNAME : string = 'index.json'
  private _isLoaded : boolean = false
  private _isIndexDirty : boolean = false
  private _files : ImgFile[] = []
  private _indexMaintTime : Date
  private _directoryMaintTime : Date
  public directoryName:string

    public get files() : ImgFile[] {
      //throw new Error('TODO: ImgDirectory : get files()')
      return this._files
    }

    constructor(public directory:FsDirectory) {
      this.directoryName = directory.path
      let dirPath = FilenameHelper.calcFilename(this.directoryName,'.')
      let stats = fs.statSync(dirPath)
      this._directoryMaintTime = stats.mtime
       this.loadIndex()   // side effect loads the indexMaintTime
      if (this._indexMaintTime<this._directoryMaintTime)
        this.scanDirectory()
    } // of constructor

    loadIndex() {
      let indexPath = FilenameHelper.calcFilename(this.directoryName,ImgDirectory.INDEXNAME)
      if (!fs.existsSync(indexPath)) {
        this._indexMaintTime = new Date(1970,1,1)
        return
      }
      let indexFile = fs.readFileSync(indexPath,'utf8')
      let loadedObj = JSON.parse(indexFile)
      if (!Array.isArray(loadedObj))
          throw new Error('Invalid format for index of '+this.directoryName)
      loadedObj.forEach( img => this._files.push(img))
      let stats = fs.statSync(indexPath)
      this._indexMaintTime = stats.mtime
    } // of loadIndex

    saveIndex() {
      let indexPath = FilenameHelper.calcFilename(this.directoryName,ImgDirectory.INDEXNAME)
      fs.writeFileSync(indexPath,JSON.stringify(this._files))
    } // of saveIndex

    scanDirectory() {
    let isIndexDirty = false
      let self = this
      this.directory.files.forEach(function(thisFile:FsFile) {
        let idx = _.findIndex(self._files,['fileName',thisFile.fileName])
        if (idx==-1) {   // not already in index
          self._files.push(new ImgFile(thisFile.fileName))
          isIndexDirty = true
        }
      })
      if (isIndexDirty)
        this.saveIndex()
    } // scanDirectory

    getFile(fileName) {
        let idx = _.findIndex(this.files,['fileName',fileName])
        return idx>-1 ? this.files[idx] : {}
    }

} // of ImgDirectory

export class ImgFile {
  constructor (public fileName:string) {

  } // of constructor
} // of ImgFile
import * as fs from 'fs'
import * as _  from 'lodash'
import {FsFile,FsDirectory} from './fsUtils'
import {JpegHelper} from './jpegHelper'

class FilenameHelper {
    static root : string
    static sep : string
    static get separator() {
        if (process.cwd().indexOf('\\')>=0)
            return '\\'
        else
            return '/'
    } // of separator
    static calcFilename(path:string,name?:string):string {
      if (name)
        return FilenameHelper.root + FilenameHelper.separator + path + FilenameHelper.separator + name
      else
        return FilenameHelper.root + FilenameHelper.separator + path
    } // of calcFilename
    
    static directoryForDate(aDate:Date) {
      let yy = aDate.getFullYear()
      let mm = aDate.getMonth()+1
      return ''+yy+'-'+(mm>9?'':'0')+mm
    }
}  // of FilenameHelper

class YearProfile {
    year :string
    months : string[]
} // of yearProfile

export default class ImgCatalog {
    private _rootDir : FsDirectory
    static  _singleton :ImgCatalog
  private directories : ImgDirectory[] = [];

    static catalogSingleton() : ImgCatalog {
      if (ImgCatalog._singleton)
        return ImgCatalog._singleton
      else
        throw new Error('Catalog not yet initialised')
    }
    constructor(rootDir:FsDirectory) {
        this._rootDir = rootDir
        FilenameHelper.root = rootDir.fullPath
        ImgCatalog._singleton = this
        rootDir.directories.forEach(thisDirectory => this.directories.push(new ImgDirectory(thisDirectory)))
    }
    getDirectory(dirName:string,force?:Boolean):ImgDirectory {
        let idx = _.findIndex(this.directories,['directoryName',dirName])
        if (idx==-1 && force)  {
          let fullDirectoryName = FilenameHelper.calcFilename(dirName)
          // now move file to correct directory. create it is it doesn't exist
          if (!fs.existsSync(fullDirectoryName))
            fs.mkdirSync(fullDirectoryName)
          let fsDirectory = new FsDirectory(fullDirectoryName,)
        }
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



    static importTempFile(filename:string,tempPath:string,updateIndex:boolean=true) {
      let errMessage = ''
      console.log('import temp file '+filename)

      try {
        if (filename.substr(-4).toLowerCase()!='.jpg')
          throw new Error('Only *.jpg supported ')
        let jpegFile = new ImgJpeg(tempPath,'NO-URL-YET')
        if (!jpegFile.dateTaken)
          throw new Error('filename does not have a date taken:'+filename)
        let newDirectoryName = FilenameHelper.directoryForDate(jpegFile.dateTaken)
        let fullDirectory = FilenameHelper.calcFilename(newDirectoryName)
        // now move file to correct directory. create it is it doesn't exist
        if (!fs.existsSync(fullDirectory))
          fs.mkdirSync(fullDirectory)
        fs.renameSync(tempPath,FilenameHelper.calcFilename(newDirectoryName,filename))
        jpegFile.url = newDirectoryName + '/'+jpegFile.filename  // update new location
        if (updateIndex) {
          // first makesure we have a directory
          let imgDirectory = ImgCatalog.catalogSingleton().getDirectory(newDirectoryName)
          imgDirectory.addFile(jpegFile)
          imgDirectory.scanDirectory()
        }
      } catch(err){
        errMessage = err.message+  ': Error on '+filename
      }
      return errMessage;

    }

    registerJpg(filename:string,path:string) {
      // insert into or update catalog
      // update thumbnail if required
      // push updatedcatalog event to client

    } // registerJpg

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
        let idx = _.findIndex(self._files,['filename',thisFile.filename])
        if (idx==-1  && /\.jpg/.test(thisFile.filename.toLowerCase())  ) {   // not already in index
          self._files.push(new ImgFile(thisFile.filename,self.directory.path+'/'+thisFile.filename))
          isIndexDirty = true
        }
      })
      if (isIndexDirty)
        this.saveIndex()
    } // scanDirectory

    getFile(filename) {
        let idx = _.findIndex(this.files,['filename',filename])
        return idx>-1 ? this.files[idx] : {}
    }

    addFile(thisFile:ImgFile) {

    }

} // of ImgDirectory

export class ImgFile {
  constructor (public filename:string,public url:string) {
     console.log('ImgFile:'+this.url)
  } // of constructor
} // of ImgFile

export class ImgJpeg  extends ImgFile {
  private _exif = null
  constructor (public filename:string,public url:string) {
    super(filename,url)
  }

  get dateTaken() : Date {
    return new Date('1951-04-18')
  }
} // ImgJpeg
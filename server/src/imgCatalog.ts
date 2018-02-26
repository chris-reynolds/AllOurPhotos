import * as fs from 'fs'
import * as _  from 'lodash'
import {FsFile, FsDirectory} from './fsUtils'
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
    static filename(fullName:string):string {
      let tokens =  fullName.split(FilenameHelper.separator)
      return tokens[tokens.length-1]
    }
    static path(fullName:string):string {
      let filename =  FilenameHelper.filename(fullName)
      let fullPath = fullName.substr(0,fullName.length-filename.length-this.separator.length)
      if (this.root == fullPath.substr(0,this.root.length))
        fullPath = fullPath.substr(this.root.length+this.separator.length)
      return fullPath
    }
}  // of FilenameHelper

class YearProfile {
    year :string
    months : string[]
} // of yearProfile

type loggerFunc = (s:string) => void
export default class ImgCatalog {
    private _rootDir : FsDirectory
    static  _singleton :ImgCatalog
  public static logger:loggerFunc = undefined
  public static userMessage(s:string) {
      if (this.logger)
        this.logger(s)
  } // user message
  private directories : ImgDirectory[] = [];

    static catalogSingleton() : ImgCatalog {
      if (ImgCatalog._singleton)
        return ImgCatalog._singleton
      else
        throw new Error('Catalog not yet initialised')
    }
    constructor(rootDir:FsDirectory) {
      let thisDirectory : FsDirectory
      try {
        this._rootDir = rootDir
        FilenameHelper.root = rootDir.fullPath
        ImgCatalog._singleton = this
        for (let dirIx in rootDir.directories) {
          thisDirectory = rootDir.directories[dirIx]
          this.directories.push(new ImgDirectory(thisDirectory))
        }
      } catch(ex) {
        if (thisDirectory)
          ex.message+=' while scanning '+thisDirectory.path
        throw ex  // rethrow now we have added directory path
      }
    }

    getDirectory(dirName:string):ImgDirectory {
        let idx = _.findIndex(this.directories,['directoryName',dirName])
        if (idx>=0)
          return this.directories[idx]
        else {
          if (dirName.length!=7 || dirName.substr(4,4)!='-')
            throw new Error('Directory ('+dirName+') should be in the form yyyy-mm')
          let fullDirectoryName = FilenameHelper.calcFilename(dirName)
          // create it is it doesn't exist
          if (!fs.existsSync(fullDirectoryName))
            fs.mkdirSync(fullDirectoryName)
          let fsDirectory = new FsDirectory(fullDirectoryName)
          let imgDirectory = new ImgDirectory(fsDirectory)
          this.directories.push(imgDirectory)
          return imgDirectory
        }
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
        return result;
    }  // of years

  static importTempFile(originalFilename:string,tempPath:string) {
      ImgCatalog.userMessage('import temp file '+originalFilename)
      try {
        let newImage = new ImgFile(tempPath,originalFilename)
        newImage.loadProperties()
        let newDirectoryName = FilenameHelper.directoryForDate(newImage.dateTaken)
        ImgCatalog.userMessage('Import into directory :'+newDirectoryName)
       // let fullDirectoryName = FilenameHelper.calcFilename(newDirectoryName)
        let imgDirectory = ImgCatalog.catalogSingleton().getDirectory(newDirectoryName)
        // now move file to correct directory
        let targetName = originalFilename
        let tries = 0
        while (tries<10) {
          let previousFile = imgDirectory.getFile(originalFilename)
          if (previousFile=={}) {// not found
            fs.copyFileSync(tempPath, FilenameHelper.calcFilename(newDirectoryName, targetName))
            imgDirectory.addFile(new ImgFile(newDirectoryName,targetName))
          } else if (previousFile.contentHash!=newImage.contentHash) {
            targetName = originalFilename + '_c'+ (++tries) // try a new target name
          } else
            ImgCatalog.userMessage('skipped importing as a duplicate of '+targetName)
        } // of while loop
      } catch(err){
        err.message +=  ': Error on importing '+originalFilename
        throw err
      }  // of try/catch
    } // of importTempFile

  scanAllDirectories() {
      this.directories.forEach((eachDirectory):void => eachDirectory.scanDirectory())
  } // of scanAllDirectories

}  // of ImgCatalog

export class ImgDirectory {
  private static INDEXNAME : string = 'index.json'
  private _files : ImgFile[] = []
  private _indexMaintTime : Date
  private _directoryMaintTime : Date
  public directoryName:string

    public get files() : ImgFile[] {
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

    addFile(thisFile:ImgFile) {
      this._files.push(thisFile)
    }

    getFile(filename):ImgFile {
      let idx = _.findIndex(this.files,['filename',filename])
      return idx>-1 ? this.files[idx] : null
    }

    get indexPath() {
      return FilenameHelper.calcFilename(this.directoryName,ImgDirectory.INDEXNAME)
    } // of get indexpath

    loadIndex() {
      if (!fs.existsSync(this.indexPath)) {
        this._indexMaintTime = new Date(1970,1,1)
        return
      }
      let indexFile = fs.readFileSync(this.indexPath,'utf8')
      let loadedObj = JSON.parse(indexFile)
      if (!Array.isArray(loadedObj))
          throw new Error('Invalid format for index of '+this.directoryName)
      loadedObj.forEach( img => this._files.push(img))
      let stats = fs.statSync(this.indexPath)
      this._indexMaintTime = stats.mtime
    } // of loadIndex

    saveIndex() {
      fs.writeFileSync(this.indexPath,JSON.stringify(this._files))
    } // of saveIndex

    scanDirectory() {
      let isIndexDirty = false
      let thisFile: FsFile
      let self = this
      try {
        console.log('scanning directory ' + this.directoryName)
        for (let fileIx in this.directory.files) {
          thisFile = this.directory.files[fileIx]
          if (thisFile.filename=='100_0100.JPG') {
            console.log('stopping')
          }
          let thisImgFile = self.getFile(thisFile.filename)
          if (!thisImgFile && /\.jpg/.test(thisFile.filename.toLowerCase())) {   // not already in index but ends with jpg
            let thisImgFile = new ImgFile(self.directoryName, thisFile.filename)
            thisImgFile.loadProperties()
            self._files.push(thisImgFile)
            isIndexDirty = true
          }
        }
        thisFile = null
        if (isIndexDirty)
          this.saveIndex()
      } catch(ex) {
        if (thisFile)
          ex.message += ' while scanning file '+thisFile.filename
      }
    } // scanDirectory
} // of ImgDirectory

export class ImgFile {
  private _dirname : string
  public caption = '-'
  public dateTaken : Date
  public width : Number
  public height : Number
  public lastModifiedDate : string
  public rank = '3'
  public latitude = -1
  public longitude = -1
  public camera = 'unknown'
  public orientation = -1
  public owner = 'all'
  public imageType : string = 'jpg'
  public misplaced : boolean  = false    // if registered in wrong directory
  public hasThumbnail : boolean
//  rotation : RotationType
  public contentHash : string = ''


//  private _isJpeg : boolean = false
  constructor (dirname:string,public filename:string) {
    ImgCatalog.userMessage('create ImgFile:'+this.filename)
    this._dirname = dirname
//    this._isJpeg = (this.filename.toLowerCase().substr(-4)=='.jpg')
 //   this._properties = properties
  } // of constructor

  calcContentHash() : string {
    let result = '1' + this.width +':'+this.height+':'
    let mmss = 0
    if (this.dateTaken)
      mmss = this.dateTaken.getMinutes()*100+this.dateTaken.getSeconds()
    if (mmss==0)
      mmss = 9000 + Number((Math.random()*999).toFixed(0))
    result += mmss.toPrecision(4)
    // todo get some pixels rather than random numbers to breakup scanned images if the same
    return result
  } // of calcContentHash

  get fullFilename():string {
    return FilenameHelper.calcFilename(this._dirname,this.filename)
  }

  loadProperties() {  // allow outside force and inside just intime
      let fullExif = JpegHelper.loadExif(this.fullFilename)
      let exifProperties = JpegHelper.partialExtract(fullExif)
      _.merge(this,exifProperties)
    this.contentHash = this.calcContentHash()  // todo with git readonly property
  } // of loadProperties


} // of ImgFile

import * as fs from 'fs'
import * as _  from 'lodash'
import {FsFile, FsDirectory, FsHelper} from './fsUtils'
import {JpegHelper, PartialExif} from './jpegHelper'
import {Image} from "./entity/Image";
import {DbPhotos} from "./dbPhotos";



interface fileHandle {
  filename:string
  path:string
}
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
    private _dbPhotos:DbPhotos
    static  _singleton :ImgCatalog
  public static logger = undefined
  private static userMessage(s:string) {
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
    constructor(rootDir:FsDirectory,public dbPhotos:DbPhotos) {
        this._rootDir = rootDir
      this._dbPhotos = dbPhotos
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



    static async importTempFile(filename:string,tempPath:string,updateIndex:boolean=true) {
//      let errMessage = ''
      console.log('import temp file '+filename)
      try {
        let jpegDetails = JpegHelper.extractMetaData(tempPath);
        let newDirectoryName = FilenameHelper.directoryForDate(jpegDetails.dateTaken)
        console.log('Import into directory :'+newDirectoryName)
        let fullDirectory = FilenameHelper.calcFilename(newDirectoryName)
        // now move file to correct directory. create it is it doesn't exist
        if (!fs.existsSync(fullDirectory))
          fs.mkdirSync(fullDirectory)
        let newImage = new Image()
        newImage.loadMetadataFromJpeg(jpegDetails)
        newImage.directory = newDirectoryName
        newImage.filename = filename
        let alreadyStored = await ImgCatalog._singleton._dbPhotos.hasDuplicate(newImage)
        if (!alreadyStored) {
          fs.copyFileSync(tempPath, FilenameHelper.calcFilename(newDirectoryName, filename))
          await ImgCatalog._singleton._dbPhotos.imageRep.save(newImage)
        }
        if (updateIndex) {
          // first makesure we have a directory
          let imgDirectory = ImgCatalog.catalogSingleton().getDirectory(newDirectoryName)
          imgDirectory.addFile(new ImgFile(newDirectoryName,filename))
          imgDirectory.scanDirectory()
        }
      } catch(err){
        err.message +=  ': Error on importing '+filename
        throw err
      }
 //     return errMessage;

    }

  public static async registerDirectory(directory?:FsDirectory) {
      if (!directory)  // by default scan the whole tree
        directory = ImgCatalog._singleton._rootDir
    this.userMessage('Entering directory '+directory.fullPath)
    for  (let directoryIx in directory.directories)
      await this.registerDirectory(directory.directories[directoryIx])
    for  (let fileIx in directory.files) {
        let thisFile = directory.files[fileIx];
      if (thisFile.filename.toLowerCase().match(/.*jpg/) && !thisFile.directoryPath.toLowerCase().match(/.*thumbnail.*/)) {
        let newImage = await this.registerInternalJpg(thisFile.directoryPath + FilenameHelper.separator + thisFile.filename)
      }
    }
    this.userMessage('Leaving directory '+directory.fullPath)
  }

  static async registerInternalJpg(fullName:string):Promise<Image> {
    this.userMessage('import internal file '+fullName)
    try {
      let jpegDetails = JpegHelper.extractMetaData(fullName);
      let newImage = new Image()
      newImage.loadMetadataFromJpeg(jpegDetails)
      newImage.directory = FilenameHelper.path(fullName)
      newImage.filename = FilenameHelper.filename(fullName)
      let alreadyStored = await ImgCatalog._singleton._dbPhotos.hasDuplicate(newImage)
      if (!alreadyStored) {
        this.userMessage('saving '+fullName)
        try {
          await ImgCatalog._singleton._dbPhotos.imageRep.save(newImage)
        } catch(err){
          this.userMessage('FAILED:' + fullName+ ':' + err.message)
        }
      } else
        this.userMessage('skipping' + fullName)
      return newImage
    } catch(err){
      err.message +=  ': Error on importing '+fullName
      throw err
    }
    } // registerInternalJpg

    updateThumbnail() {

    }

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
          let thisImgFile = new ImgFile(self.directoryName,thisFile.filename)
          thisImgFile.loadProperties()
          self._files.push(thisImgFile)
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
      this._files.push(thisFile)
    }

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
//  private _isJpeg : boolean = false
  constructor (dirname:string,public filename:string) {
     console.log('ImgFile:'+this.filename)
    this._dirname = dirname
//    this._isJpeg = (this.filename.toLowerCase().substr(-4)=='.jpg')
 //   this._properties = properties
  } // of constructor

  get fullFilename():string {
    return FilenameHelper.calcFilename(this._dirname,this.filename)
  }

  loadProperties() {  // allow outside force and inside just intime
      let fullExif = JpegHelper.loadExif(this.fullFilename)
      let exifProperties = JpegHelper.partialExtract(fullExif)
      _.merge(this,exifProperties)
  } // of loadProperties


} // of ImgFile

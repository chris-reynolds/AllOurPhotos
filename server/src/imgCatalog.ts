import * as fs from 'fs'
import {FsFile,FsDirectory} from './fs_utils'

class YearProfile {
    year :string
    months : string[]
} // of yearProfile

export default class ImgCatalog {
    private _rootDir : FsDirectory
    private directories : ImgDirectory[];
    constructor(rootDir:FsDirectory) {
        this._rootDir = rootDir
    }
    getDirectory(dirName) {
        let idx = _.findIndex(this.directories,['directoryName',dirName])
        return idx>-1 ? this.directories[idx] : {}
    } // of getDirectory

    getYear(selectedYear) :YearProfile {
        let result = new YearProfile()
        result.year = selectedYear
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
        for (let i=0;i<result.length;i++)
            result[i] = this.getYear(result[i]);
        return result;
    }  // of years

    addImage(stuff:string) {

    } // add Image

}  // of ImgCatalog

export class ImgDirectory {
    private static INDEXNAME : string = 'index.json'
    private _isLoaded : boolean = false
    private _isIndexDirty : boolean = false

    public get files() : ImgFile[] {
        return null
    }
    constructor(public directoryName:string) {

    } // of constructor

    loadIndex() {

    } // of loadIndex

    saveIndex() {

    } // of saveIndex

    scanDirectory() {

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
import {DBMysql} from './dbMysql'
import {SqlBuilder} from './SqlBuilder'
import {Image} from './entity/Image'
import {User} from './entity/User'

export class DbSimple {
  sqb :SqlBuilder
  columnTypes :any
  constructor() {
    this.sqb = new SqlBuilder()
    this.columnTypes = {}
  }
  async insert(tableName:string,data:any) {
    let sqlText = this.sqb.insertStatement(tableName,data)
    let newId:number = await DBMysql.execute(sqlText)
    let newItem = await this.selectOne(tableName,newId)
    return newItem
  } // of insert

  async selectOne(tableName,id:number) {
    let sqlText = this.sqb.selectSomeStatement(tableName,id)
    let result = await DBMysql.getRows(sqlText)
    return result
  }

  async selectFirst(tableName,criteria) {
    let sqlText = this.sqb.selectOneStatement(tableName,criteria)
    let result = await DBMysql.getRows(sqlText)
    if (result.length==0)
      return null
    else
      return result
  } // of selectFirst

  async selectSome(tableName,criteria) {
    let sqlText = this.sqb.selectSomeStatement(tableName,criteria)
    let result = await DBMysql.getRows(sqlText)
    return result
  }
} // of class DbSimple

export class DbPhotos extends DbSimple  {
  defaultUser : User = {id:0,name:'no-one'}

  static async connect(config:any) {
    console.log('database adding')
    return await DBMysql.addDatabase('aop',config)
  } // of connect

  constructor() {
    super()
    this.columnTypes = photoColumnTypes()
  } // of constructor

  async addDefaultUser() {
    const DEFAULT_USERNAME = 'Default'
    if (DBMysql.isConnected  ) {
      this.defaultUser = await this.selectFirst('user','name='+DEFAULT_USERNAME)
      if (!this.defaultUser) {
        console.log("Inserting default user into the database...")
        const newUser = new User()
        newUser.name = DEFAULT_USERNAME
        await this.insert('user',newUser)
        console.log("Saved the new default user with id: " + newUser.id)
        this.defaultUser= newUser
      }
      console.log("Loading users from the database...")
      const users = await this.selectSome('user','1=1')
      console.log("Loaded users: ", users)
    } else
      console.log('No connection to add user!!!!!!!!!!!!')
  } // addDefaultUser


  fixDateUTC(d1:Date):Date {
    return new Date(
      d1.getUTCFullYear(),
      d1.getUTCMonth(),
      d1.getUTCDate(),
      d1.getUTCHours(),
      d1.getUTCMinutes(),
      d1.getUTCSeconds(),
      d1.getUTCMilliseconds())
  } // of fixDateUTC

  async hasDuplicate(anImage:Image) {
    if (anImage.id)
      throw new Error('todo check existing dups')
    else {
      let fixeddate = this.fixDateUTC(anImage.takenDate)
      try {
        let matchingCriteria = `directory='${anImage.directory} and filename='${anImage.filename}' and
          height=${anImage.height} and width=${anImage.width} and takenDate=${fixeddate}`
        console.log('looking for '+matchingCriteria)
        let similarImages:Image[] = await this.selectSome('image',matchingCriteria)
        if (similarImages.length>0)
          return true
        else
          return false
      } catch(err) {
        throw err
      }
    }
  }  // of hasDuplicate

}


function photoColumnTypes() {
  return {
    'album': {
      'name' : 's',
      'description' : 's',
      'userid' : 'n',
    },

    'album_item': {
      'albumid' : 'n',
      'imageid' : 'n',
    },

    'image': {
      'filename' : 's',
      'directory' : 's',
      'takendate' : 'd',
      'modifieddate' : 'd',
      'devicename' : 's',
      'caption' : 's',
      'ranking' : 'n',
      'longitude' : 'n',
      'latitude' : 'n',
      'rotation' : 's',
      'importsource' : 's',
      'hasthumbnail' : 'b',
      'taglist' : 's',
      'userid' : 'n',
      'sourceimageid' : 'n',
    },

    'user': {
      'name' : 's',
    }

  }

} // of photoColumnTypes
import _ from 'lodash'
import {isDate} from "util";
//import * as moment from "moment"
const QUOTE : string = "'"

type critString = string|Number

export class SqlBuilder {
  public testDate : Date // allows you to dicker with date for regression tests
  public columnTypes : any  // just an object hash table
  constructor(public dialect='mysql',public primaryColumn='id',public createdColumn ='createdDate',
              public updatedColumn='updatedDate',public system='',public hidePrefix='_') {
  } // of constructor
  get now() {
    return this.testDate || new Date()
  }

  safeDate(value) {
    let result
    try {
      result = QUOTE + value.toISOString() + QUOTE
    } catch (ex) {
      result =  value.toString()+'zzzz'
    }
    return result
//    else
//      return QUOTE + value + QUOTE
  } // of safeDate

  safeString(value) {
    if (!value)
      return 'NULL'
    else if (typeof value == 'string')
      return QUOTE + value.split("'").join("\'") + QUOTE
    else
      return QUOTE+value+QUOTE
  } // of safeDate

  toSqlString(value,columnType:string='s') {
    let result
    if (value==undefined)
      return 'NULL'
    switch (columnType.substr(0,1).toLowerCase())  {
      case 'd': result = this.safeDate(value); break
      case 'n': result = value; break
      case 's': result = this.safeString(value); break
    }
    return result
  } // of toSqlString

  extractValues(tablename:string,data:any):string[][] {
    let result = [[],[]]
    let column:string // declare here so they are in scope for the error trap
    try {
      let tableDef = this.columnTypes[tablename]
      for (column in data) {
        result[0].push(column)
        if (tableDef ) {
          let thisColValue = this.toSqlString(data[column], tableDef[column])
          result[1].push(thisColValue)
        } else
          result[1].push(data[column])
      }
      return result
    } catch(ex) {
      ex.message += "while extraction "+tablename+'['+column+']'
      throw ex
    }
  } // of extract values

  insertStatement(tablename:string,data:any):string {
    if (data[this.primaryColumn])
      throw new Error('Cant do an insert with an existing id')
    data[this.createdColumn] = this.now  // allows you to dicker with date for regression tests
    data[this.updatedColumn] = data[this.createdColumn]
    let extracted = this.extractValues(tablename,data)
    return `insert into ${this.system+tablename} (${extracted[0].join(',')}) values(${extracted[1].join(',')})`
  }

  updateStatement(tablename:string,data:any) {
    if (!data[this.primaryColumn])
      throw new Error('Cant do an update without an existing id')
    let oldStamp = data[this.updatedColumn]
    data[this.updatedColumn] =  this.now  // allows you to dicker with date for regression tests
    let extracted = this.extractValues(tablename,data)
    let result = `update ${this.system+tablename} set `
    let seperator = ''
    for (let i=0; i<extracted[0].length; i++){
      let fldName = extracted[0][i]
      let fldValue = extracted[1][i]
      if (fldName!=this.primaryColumn) {
        result += seperator + fldName + '=' + fldValue
        seperator = ','
      }
    }
    result +=
      ` where ${this.primaryColumn}=${data[this.primaryColumn]} and ${this.updatedColumn}=${this.safeDate(oldStamp)}`
    return result
  }
  deleteStatement(tablename:string,criteria:critString) {
    if (typeof criteria == 'number')
      criteria = this.primaryColumn+'='+criteria
    return `delete from ${this.system+tablename} where ${criteria}`
  }
  selectOneStatement(tablename:string,criteria:critString) {
    if (typeof criteria == 'number')
      criteria = this.primaryColumn+'='+criteria
    return `select first * from ${this.system+tablename} where ${criteria}`
  }

  selectSomeStatement(tablename:string,criteria:critString,columns='*') {
    if (typeof criteria == 'number')
      criteria = this.primaryColumn+'='+criteria
    return `select ${columns} from ${this.system+tablename} where ${criteria}`
  }
} // SqlBuilder

function test() {
  let sqb = new SqlBuilder()
  sqb.testDate = new Date(2018, 7, 6, 5, 4, 3, 2)
  sqb.system = 'aop'
  sqb.columnTypes = {
    'user': {createdDate: 'd', updatedDate: 'd'},
  }
/*  sqb.blah = {
    'album': {
      'name' : 's',
      'description' : 's',
      'ownerid' : 'n',
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
      'ownerid' : 'n',
      'sourceimageid' : 'n',
    },

    'owner': {
      'name' : 's',
    }

  }
*/
  let data2 = {id: 57, name: 'tom heinz', createdDate: sqb.testDate, updatedDate: sqb.testDate}
  let result = sqb.updateStatement('user', data2)
  let now = sqb.safeDate(sqb.testDate)
  let target = `update aopuser set name='${data2.name}',createdDate=${now},updatedDate=${now} where id=${data2.id} and updatedDate=${now}`
}

// test()
import _ from 'lodash'
import {isDate} from "util";
import * as moment from "moment"
const QUOTE : string = "'"

export default class SqlBuilder {
  public testDate : Date // allows you to dicker with date for regression tests
  public columnTypes : any  // just an object hash table
  constructor(public dialect='mysql',public primaryColumn='id',public createdColumn ='createdDate',
              public updatedColumn='updatedDate',public system='',public hidePrefix='_') {
  } // of constructor

  safeDate(value) {
//     if (isDate(value))
       let result = QUOTE + value.toISOString() + QUOTE
    return result
//    else
//      return QUOTE + value + QUOTE
  } // of safeDate

  safeString(value) {
    if (!value)
      return 'NULL'
    else
      return QUOTE + value.split("'").join("\'") + QUOTE
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
    let tableDef = this.columnTypes[tablename]
    for (let column in data) {
      result[0].push(column)
      if (tableDef ) {
        let thisColValue = this.toSqlString(data[column], tableDef[column])
        result[1].push(thisColValue)
      } else
        result[1].push(data[column])
    }
    return result
  } // of extract values

  insertStatement(tablename:string,data:any):string {
    if (data[this.primaryColumn])
      throw new Error('Cant do an insert with an existing id')
    data[this.createdColumn] = this.testDate || new Date()  // allows you to dicker with date for regression tests
    data[this.updatedColumn] = data[this.createdColumn]
    let extracted = this.extractValues(tablename,data)
    return `insert into ${this.system+tablename} (${extracted[0].join(',')}) values(${extracted[1].join(',')})`
  }
} // SqlBuilder
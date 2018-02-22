import * as mysql from 'mysql'
import {Connection} from "mysql";

export class AsyncConnection {

  constructor(public dbCon:Connection) {

  }
  get isConnected() :boolean {
    return this.dbCon.state=='connected'
  }
  async query (sql, values)  {
    return new Promise(function (resolve, reject) {
      this.dbCon.query(sql, values, function (err, rows,fields) {
        if (err)
          reject(err)
        else {
          console.log('FieldCount : '+fields.length)
          resolve(rows)
        }
      })  // query cb
    })
  }  // of query

} // of asyncConnection


export default class AmySql {
  static  async  connect(config) {
    return new Promise(function (resolve, reject) {
      let db:Connection;

      db = mysql.createConnection(config);

      db.connect((err) => {
        if (err) {
          reject(err);
        } else {
          resolve(new AsyncConnection(db));
        }
      })
    }) // of promise
  } // of connect
} // of amysql



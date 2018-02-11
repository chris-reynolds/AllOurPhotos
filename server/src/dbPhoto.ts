import mysql from 'async-mysql'

let main;

// async/await can be used only within an async function.
main = async () => {
  let mysql = require('async-mysql'),
    connection,
    rows;

  connection = await mysql.connect({
    host: "localhost",
    port: 3306,
    user: "root",
    password: "Instant00",
    database: "photo_dev",
  });

  rows = await connection.query('SELECT * from aopuser')
  console.log(JSON.stringify(rows))

  try {
    await connection.query('INVALID_QUERY');
    console.log('Never here')
  } catch (e) {
    console.log(e.message)
    throw e;
    // [Error: ER_PARSE_ERROR: You have an error in your SQL syntax; check the manual that corresponds to your MySQL server version for the right syntax to use near 'INVALID_QUERY' at line 1]
  }
};

/*
* Database functions
*/

let _connections = new Object();
let _defaultConnection = '';
let TIMEOUT = 60;
let DB_LOGGING = false;

export class DB {
  
  public static async addDatabase(dbName, connectionParams) {
    _connections[dbName.toLowerCase()] = await mysql.connect(connectionParams);
    if (!_defaultConnection)
      _defaultConnection = dbName.toLowerCase()
  } // of addDatabase
  

  public static setDefaultDatabase(dbName) {
    if (_connections[dbName.toLowerCase()] == undefined) { // not yet set up
      throw Error(dbName + ' not found in list of connections');
    } else
      _defaultConnection = dbName.toLowerCase();
  } // of setDefaultDatabase

 
// this works out the connection string

  private static getConnection(conAbbrev):any {
    let result = '';
    if (conAbbrev == undefined) {
      result = _connections[_defaultConnection];
      if (result == undefined)
        throw new Error('No default connection');
    } else
      result = _connections[conAbbrev.toLowerCase()];
    if (result == undefined || result == '') {
      throw new Error('Unknown connection "' + conAbbrev + '"');
    } else
      return result;
  } // of getConnection


// gets the first column of a query and returns it as an array

  public static async getIds(sqlText:string, conAbbrev?:string):Promise<string[]> {
    let aConnection = this.getConnection(conAbbrev)
    let rows = await aConnection.query(sqlText)
    console.log('SQL Ids :' + conAbbrev + ':' + sqlText)
    let result = []
    rows.map((row)=> {result.push(row[0])})
    return result
  } // of getIds

// gets a query and returns it as an array of objects with columnName style properties

  public static async getRows(sqlText:string, conAbbrev?:string) {
    let aConnection = this.getConnection(conAbbrev)
    if (DB_LOGGING) {
      if (conAbbrev != undefined)
        console.log(conAbbrev + ':' + sqlText);
      else
        console.log(sqlText);
    }
      let rows2 = await aConnection.query(sqlText)
      let result = rows2
/*      if (!rows.EOF)
        rows.MoveFirst();
      let fieldCount = rows.Fields.count;
      while (!rows.EOF) {
        let aRow = new Object();
        let fldIx;
        for (fldIx = 0; fldIx < fieldCount; fldIx++) {
          let thisField = rows(fldIx);
          try {
            // force all object properties to be uppercase
            aRow[thisField.Name.toUpperCase()] = thisField.Value;
          } catch (err) {
            console.log('bad field ' + thisField.Value);

          }
        } // of field loop
        result.push(aRow);
        rows.MoveNext;
      }  // of row loop
*/
      if (DB_LOGGING)
        console.log('Row Count = ' + result.length);
      return result;
  } // of getRows

// execute sql given by sqlText using connection given by connAbbrev

  public static async execute(sqlText:string, conAbbrev:string = _defaultConnection) {
    let aConnection = this.getConnection(conAbbrev)
    if (DB_LOGGING)
      console.log('SQL Text :' + conAbbrev + ':' + sqlText);
    try {
      let rowsAffected;
      let rows = await aConnection.query(sqlText)
      if (sqlText.substr(0, 6).toLowerCase() != 'insert')
        return rows[0][0];
      else {
        // get last identify for an insert
        let rows = await aConnection.query('select @@IDENTITY as LASTID')
        let lastId = rows[0][0];
        return lastId;
      }
    } catch (e) {
      throw new Error(e.message);
    }
  } // of execute
  

  safeNumeric(maybeNumber) {
    if (maybeNumber == undefined || isNaN(maybeNumber))
      return 0;
    else
      return maybeNumber;
  } // of safeNumeric

  /*
  // gets a parameter and adds any friendly sql to keep requests short
  // can take the following formats 
  //  99999  => converted to 'select * from keytable where keyName=99999
  //  whereCond => converted to 'select * from keytable where whereCond
  //  selectStatement  => left alone
  function checkSQL(id) {
    let sqlText;
    if (!isNan(id)) {
      sqlText = 'select t1.* from '+keyTable+' t1 where t1.'+keyName+'='+id;
    } else if (id.substr(0,6).toLowercase()=='select') {
      sqlText = id
    } else
      sqlText = 'select t1.* from '+keyTable+' t1 where '+id;  
    return sqlText;     
  }  // of checkSQL
    
  //  LINKED TABLE SUPPORT 
  let links = {Benefits:{tableName:'Rider',foreignKey:'POLNO',
                        filter:'RIDNO=RIDNOORG',orderby:'RIDNO'},
               Riders:{tableName:'Rider',foreignKey:'POLNO',orderby:'RIDNO'}
              }   
              
  //add another link to the links table            
  function addLink(linkName,aTableName,aForeignKey,aFilter,anOrderBy) {
    links[linkName] = {tableName:aTableName,foreignKey:aForeignKey,
                        filter:aFilter,orderby:anOrderBy}; 
  } // of addLink
  
  function getLinkedRows(linkName,id) {
    let oLink = links[linkName];
    if (oLink == null)
      t hrow new Error(200,'Unknown link '+linkName);
    if (isNaN(id))
      id = keyId;  
    let sqlText = 'select * from '+oLink.tableName+' where ('+oLink.foreignKey+
       '='+id+')';
    if (oLink.filter>'')
      sqlText += ' and ('+oLink.filter+')';
    if (oLink.orderBy>'')
      sqlText += ' order by '+oLink.orderBy;
    return getRows(sqlText);
  } // of getLinkedRows
  */


} // of class DB

/************************ TEST ROUTINES ***********************************/


async function XTest_getID() {
  DB.addDatabase('Bridge', 'Provider=SQLOLEDB.1;Data Source=sql02dev;User ID=sa;Password=Passw0rd;Initial Catalog=Fidelity_BridgePCMS;APP=TestComplete-PBA');
  DB.addDatabase('Jupiter', 'Provider=SQLOLEDB.1;Data Source=sql02dev;User ID=sa;Password=Passw0rd;Initial Catalog=JupiterPCMS;APP=TestComplete-PBA');
  DB.setDefaultDatabase('Bridge');
  let fred = await DB.getIds('select top 10 polno from policy where type_ in (70,71,72,73,74,75,76) and stat<>1');
  console.log(fred.length);
} // of getID_Test


async function XTest_getRows() {
  DB.addDatabase('Bridge', 'Provider=SQLOLEDB.1;Data Source=sql02dev;User ID=sa;Password=Passw0rd;Initial Catalog=Fidelity_BridgePCMS;APP=TestComplete-PBA');
  DB.addDatabase('Jupiter', 'Provider=SQLOLEDB.1;Data Source=sql02dev;User ID=sa;Password=Passw0rd;Initial Catalog=JupiterPCMS;APP=TestComplete-PBA');
  DB.setDefaultDatabase('Jupiter');
  let fred = await DB.getRows('select top 3 * from policy where type_ in (70,71,72,73,74,75,76) and stat<>1', 'Bridge');
  console.log(fred.length);
} // of getRows_Test

/*
function XTest_getLinkedRows() {
  let fred = getLinkedRows('Benefits',123456);
  Log.message('benefit count'+fred.length);
  let fred = getLinkedRows('Riders',123456);
  Log.message('rider count'+fred.length);
} // of getLinkedRows_Test
*/

main()
  .then(()=>{console.log('ok');process.exit()})
  .catch((e)=>{console.log('exception '+e.message);process.exit(16)})


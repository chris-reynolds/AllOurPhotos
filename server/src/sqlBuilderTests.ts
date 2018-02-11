import SqlBuilder from './sqlBuilder'
import { assert } from 'chai';



describe('sqlBuilder Tests', function(){
  let data1:any
  let data2:any
  let sqb = new SqlBuilder()
  sqb.testDate = new Date()
  sqb.system = 'aop'
  sqb.columnTypes = {'user': {createdDate:'d',updatedDate:'d'},
  }
  beforeEach(function () {
    data1 = {name:'fred bloggs'}
  });
  it('can build insert statement',function ( ){
    let result = sqb.insertStatement('user',data1)
    let now = sqb.safeDate(sqb.testDate)
    let target = `insert into aopuser (name,createdDate,updatedDate) values('${data1.name}',${now},${now})`
    assert.equal(result,target)
    return

  }) // it can build insert statement


}) // of describe sqlBuilder Tests


/*
let data1 = {"name":'fred bloggs'}
let data2:any
let sqb = new SqlBuilder()
sqb.testDate = new Date()
sqb.columnTypes = {'tbl': {"createdDate":'d',"updatedDate":'d'}}
let result = sqb.insertStatement('tbl',data1)
let now = sqb.safeDate(sqb.testDate)
let target = `insert into tbl (name,createdDate,updatedDate) values('${data1.name}',${now},${now})`
assert.equal(result,target)
*/
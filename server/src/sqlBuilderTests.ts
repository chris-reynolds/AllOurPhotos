import SqlBuilder from './sqlBuilder'
import { assert } from 'chai';



describe('sqlBuilder Tests', function(){
  let data1:any
  let data2:any
  let sqb = new SqlBuilder()
  sqb.testDate = new Date(2018,7,6,5,4,3,2)
  sqb.system = 'aop'
  sqb.columnTypes = {'user': {createdDate:'d',updatedDate:'d'},
  }
  beforeEach(function () {
    data1 = {name:'fred bloggs'}
    data2 = {id:57,name:'tom heinz',createdDate:sqb.testDate,updatedDate:sqb.testDate}
  });
  it('can build insert statement',function ( ){
    let result = sqb.insertStatement('user',data1)
    let now = sqb.safeDate(sqb.testDate)
    let target = `insert into aopuser (name,createdDate,updatedDate) values('${data1.name}',${now},${now})`
    assert.equal(result,target)
    return
  }) // it can build insert statement

  it('can build update statement',function ( ){
    let result = sqb.updateStatement('user',data2)
    let now = sqb.safeDate(sqb.testDate)
    let target = `update aopuser set name='${data2.name}',createdDate=${now},updatedDate=${now} where id=${data2.id} and updatedDate=${now}`
    assert.equal(result,target)
    return
  }) // it can build update statement
  
  it('can build delete statement',function ( ){
    let result = sqb.deleteStatement('user',555)
    let now = sqb.safeDate(sqb.testDate)
    let target = `delete from aopuser where id=555`
    assert.equal(result,target)
    return
  }) // it can build delete statement
  
  it('can build selectOne statement',function ( ){
    let result = sqb.selectOneStatement('user',666)
    let now = sqb.safeDate(sqb.testDate)
    let target = `select first * from aopuser where id=666`
    assert.equal(result,target)
    return
  }) // it can build selectOne statement

  it('can build selectSome statement',function ( ){
    let result = sqb.selectSomeStatement('user','bill=ben')
    let now = sqb.safeDate(sqb.testDate)
    let target = `select * from aopuser where bill=ben`
    assert.equal(result,target)
    return
  }) // it can build selectSome statement

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
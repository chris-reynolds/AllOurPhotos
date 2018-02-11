//import { assert } from 'chai';
import * as request from 'supertest'
import * as _  from 'lodash'
import { FsHelper } from './fsUtils';
import { AopWebServer} from "./aopWebServer";
import * as fs from "fs";
import {DbPhotos} from "./dbPhotos";
//import * as main from 'aopServerMain'
//const TESTDATA_DIR = 'c:\\projects\\AllOurPhotos\\testdata\\';
let ws:AopWebServer = null
let config:any = {}
function loadConfig() {
  let result:any = {}
  let configFileName = '..\\test' + '\\aopConfig.json'
  if (fs.existsSync(configFileName )) {
    let contents= fs.readFileSync(configFileName,'utf8')
    result = _.merge(result,JSON.parse(contents));
  }
  return result;
} // of loadConfig
/*
try {
  config = loadConfig();
  DbPhotos.connect(config.database)
    .then(()=>{
      ws = new AopWebServer(config.webserver)
    })
    .catch(err => {throw new Error(err)})
} catch (e) {
  console.error('TOP LEVEL ERROR :'+e.message+'\n'+e.stackTrace)
}
*/


describe('api catalog methods', function () {
  before(async function () {
    config = loadConfig();
    console.log(config.database)
    let db = await DbPhotos.connect(config.database);
    console.log('11111')
    ws = await new AopWebServer(config.webserver)
    console.log('2222')
  });
  beforeEach(function () {
    //Links.remove({});
  });

  it('can see years ', function (done) {
    request(ws.httpServer).get('/api/years')
      .set('Accept', 'application/json')
      .expect('Content-Type', /json/)
      .expect(/2017/)
      .expect(200, done);
  })
  it('can see months of valid year', function (done) {
    request(ws.httpServer).get('/api/year/2017')
      .set('Accept', 'application/json')
      .expect('Content-Type', /json/)
      .expect(/08/)
      .expect(200, done);
  })
  it('can return no months of invalid year', function (done) {
    request(ws.httpServer).get('/api/year/2016')
      .set('Accept', 'application/json')
      .expect('Content-Type', /json/)
      .expect(/\[]/)
      .expect(200, done);
  })
  it('can see a month ', function (done) {
    request(ws.httpServer).get('/api/month/2017/08')
      .set('Accept', 'application/json')
      .expect('Content-Type', /json/)
      .expect(/fileName/)
      .expect(200, done);
  })
  it('can return no pictures for invalid month', function (done) {
    request(ws.httpServer).get('/api/month/2016/08')
      .set('Accept', 'application/json')
      .expect('Content-Type', /json/)
      .expect(/\[]/)
      .expect(200, done);
  })
  it('can see retrieve valid image', function (done) {
    request(ws.httpServer).get('/images/2017-08/20170807_084420.jpg')
      .set('Accept', 'image/jpeg')
      .expect('Content-Type', /image/)
      .expect(200, done);
  })
  it('can see report invalid image request', function (done) {
    request(ws.httpServer).get('/images/2017-08/20170807_084420xxxxx.jpg')
      .set('Accept', 'image/jpeg')
      .expect('Content-Type', /text/)
      .expect(404, done);
  })
  it('can save image to existing year/month', function (done) {
    let testFilename = '20170807_083703_copy.jpg'
    FsHelper.deleteFile(config.imagesDir + '\\2017-08\\' + testFilename)
    request(ws.httpServer).post('/new_image/' + testFilename)
      .set('Accept', 'application/json')
      .attach(testFilename, config.webserver.imagesDir + testFilename)
      .expect('Content-Type', /json/)
      .expect(200, done);
  })
  it('can save image to non-existing month')
  it('can save image to non-existing year')
  it('can extract EXIF date taken')
  it('can extract EXIF location')
  it('can get picture name variation')
  it('can update caption')
  it('can update ranking')
  it('can update orientation')
  it('can list albums')
  it('can add albums')
  it('can remove album')
  it('can update album')
  it('can list an album')




}) // of describe


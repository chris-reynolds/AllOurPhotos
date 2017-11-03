import { assert } from 'chai';
import * as request from 'supertest'
import { FsDirectory } from './fs_utils';
import { AopWebServer} from "./aopWebServer";
//import * as main from 'aopServerMain'
//const TEST_PHOTO_DIR = 'c:\\projects\\AllOurPhotos\\testdata';

let config = {
  started:Date.now(),
  port:4444,
  serverDir : __dirname,
  clientDir : 'C:\\projects\\AllOurPhotos\\client',
  imagesDir : 'C:\\projects\\AllOurPhotos\\testdata',

}
 let ws = new AopWebServer(config)

describe('api catalog methods methods', function () {
  beforeEach(function () {
    //Links.remove({});
  });

  it('can see years ',function(done){
    request(ws.httpServer).get('/api/years')
      .set('Accept', 'application/json')
      .expect('Content-Type', /json/)
      .expect(/2017/)
      .expect(200, done);
  })
  it('can see months of valid year',function(done){
    request(ws.httpServer).get('/api/year/2017')
      .set('Accept', 'application/json')
      .expect('Content-Type', /json/)
      .expect(/08/)
      .expect(200, done);
  })
  it('can return no months of invalid year',function(done){
    request(ws.httpServer).get('/api/year/2016')
      .set('Accept', 'application/json')
      .expect('Content-Type', /json/)
      .expect(/\[\]/)
      .expect(200, done);
  })
  it('can see a month ',function(done){
    request(ws.httpServer).get('/api/month/2017/08')
      .set('Accept', 'application/json')
      .expect('Content-Type', /json/)
      .expect(/fileName/)
      .expect(200, done);
  })
  it('can return no pictures for invalid month',function(done){
    request(ws.httpServer).get('/api/month/2016/08')
      .set('Accept', 'application/json')
      .expect('Content-Type', /json/)
      .expect(/\[\]/)
      .expect(200, done);
  })
  it('can see retrieve image')
  it('can save image to existing year/month')
  it('can save image to non-existing month')
  it('can save image to non-existing year')
  it('can update caption')
  it('can update ranking')
  it('can update orientation')




}) // of describe

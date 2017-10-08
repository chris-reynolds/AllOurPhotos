import { assert } from 'chai';
import * as request from 'supertest'
import { FsDirectory } from './fs_utils';
import { AopWebServer} from "./aopWebServer";
//import * as main from 'aopServerMain'
const TEST_PHOTO_DIR = 'c:\\projects\\AllOurPhotos\\testdata';

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
      .expect(200, done);
  })
  it('can see months of valid year')
  it('can return no months of invalid year')
  it('can see a month ')
  it('can return no pictures for invalid month')
  it('can see retrieve image')
  it('can save image to existing year/month')
  it('can save image to non-existing month')
  it('can save image to non-existing year')
  it('can update caption')
  it('can update ranking')
  it('can update orientation')




}) // of describe

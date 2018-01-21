"use strict";
import * as fs from 'fs'
import * as _  from 'lodash'
import {AopWebServer} from './aopWebServer'
import {DbPhotos} from "./dbPhotos";

function loadConfig() {
  let result = {
    started:Date.now(),
    port:3333,
    serverDir : __dirname,
    clientDir : 'C:\\projects\\AllOurPhotos\\client',
    imagesDir : 'C:\\projects\\AllOurPhotos\\testdata',

  }
  let configFileName = __dirname + '\\aopConfig.json'
  if (fs.existsSync(configFileName )) {
    let contents= fs.readFileSync(configFileName,'utf8')
    result = _.merge(result,JSON.parse(contents));
  }
  return result;
} // of loadConfig

try {
  let config = loadConfig();
  DbPhotos.connect(config)
    .then(()=>{new AopWebServer(config)})
    .catch(err => {throw new Error(err)})
 // new AopWebServer(config);
} catch (e) {
  console.error('TOP LEVEL ERROR :'+e.message+'\n'+e.stackTrace)
}


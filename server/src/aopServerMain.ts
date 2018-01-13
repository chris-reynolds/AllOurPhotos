"use strict";
import * as fs from 'fs'
import * as _  from 'lodash'
import {AopWebServer} from './aopWebServer'

function loadConfig() {
  let result = {
    started:Date.now(),
    port:3333,
    serverDir : __dirname,
    clientDir : 'C:\\projects\\AllOurPhotos\\client',
    imagesDir : 'C:\\projects\\AllOurPhotos\\testdata',

  }
  let configFileName = __dirname + '\\config.json'
  if (fs.existsSync(configFileName )) {
    let contents= fs.readFileSync(configFileName,'utf8')
    result = _.merge(result,JSON.parse(contents));
  }
  return result;
} // of loadConfig

// start up

try {
  new AopWebServer(loadConfig());
} catch (e) {
  console.error('Top level error :'+e.message+'\n'+e.stackTrace)
}


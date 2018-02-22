"use strict";
import * as fs from 'fs'
import * as _  from 'lodash'
import {AopWebServer} from './aopWebServer'
import {DbPhotos} from "./dbPhotos";

function loadConfig() {
  let result:any = {}
  let configFileName = __dirname + '\\aopConfig.json'
  if (fs.existsSync(configFileName )) {
    let contents= fs.readFileSync(configFileName,'utf8')
    result = _.merge(result,JSON.parse(contents));
  }
  return result;
} // of loadConfig

try {
  let config = loadConfig();
  DbPhotos.connect(config.database)
    .then(new DbPhotos().addDefaultUser)
    .then(()=>{new AopWebServer(config.webserver)})
    .catch(err => {throw new Error(err)})
 // new AopWebServer(config);
} catch (e) {
  console.error('TOP LEVEL ERROR :'+e.message+'\n'+e.stackTrace)
}


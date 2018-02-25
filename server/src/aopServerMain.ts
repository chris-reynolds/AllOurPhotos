"use strict";
import * as fs from 'fs'
import * as _  from 'lodash'
import {AopWebServer} from './aopWebServer'

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
  new AopWebServer(config.webserver)

} catch (e) {
  console.error('TOP LEVEL ERROR :'+e.message+'\n'+e.stackTrace)
}


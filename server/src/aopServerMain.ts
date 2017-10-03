"use strict";
import * as fs from 'fs'
import * as _  from 'lodash'
import imgCatalog from './imgCatalog'
import {FsDirectory} from "./fs_utils";

var http = require('http');
//var FSDirectory = require('./lib/fs_utils.js');
var context = {dirname:__dirname,filename:__filename};
console.log('now executing '+__filename);
var imageDirectory: FsDirectory

function loadConfig() {
  let result = {
    started:Date.now(),
    port:3333,
    serverDir : context.dirname,
    clientDir : 'C:\\projects\\AllOurPhotos\\client',
    imagesDir : 'C:\\projects\\AllOurPhotos\\testdata',
    realDir : 'P:\\photos'

  }
  if (fs.existsSync('config.json')) {
    let contents= fs.readFileSync('config.json','utf8')
    result = _.merge(result,JSON.parse(contents).toJSON());
  }
  imageDirectory = new FsDirectory(result.realDir);
  imageDirectory.loadDirectAndFiles();
  return result;
} // of loadConfig

function responder(req,res) {
  let url = require('url');
  let thisReq = url.parse(req.url);
  let segments = thisReq.path.split('/');
  let root = segments[1];
  segments.shift();
  segments.shift();
  let shortPath = '/'+ segments.join('/');
  let now = new Date()
  console.log(''+now.getHours()+':'+now.getMinutes()+':'+now.getSeconds()+'  - root=',root,' shortpath=',shortPath);
  switch(root) {
    case '':
      serveStaticFile(res, config.clientDir + '/index.html', 'text/html');
      break;
    case 'images':
      serveStaticFile(res, config.imagesDir + shortPath, 'image/jpeg');
      break;
    case 'photos':
      serveStaticFile(res, config.realDir + shortPath, 'image/jpeg');
      break;
    case 'api':
      executeApiRequest(res,segments);
    default:
      let possFilename = config.clientDir+thisReq.path;
      if (fs.existsSync(possFilename)) {
        serveStaticFile(res, possFilename);
      } else {
        res.writeHead(404, {'Content-Type': 'text/plain'});
        res.end(possFilename+ ' not found' + config.started.toString());
      }
  } // of switch
} // of responder

function assert(expr,errmessage) {
  if (!expr) throw new Error(errmessage)
}

function compoundMonthKey(year,month) {
  assert((year>=1980) && (year<=2030),'Year most be at between 1980 and 2030')
  assert((month>0) && (month<=12),'Month must be between  and 12')
  let result = year.toString()+'-'+(100+month).toString().substr(-2)
  return result
} // of monthKey

function monthIndex(year,month) {
  let monthKey = compoundMonthKey(year,month)
  let thisMonth = imageDirectory.getDirectory(monthKey)
  if (thisMonth) {
    return thisMonth.files()
  } else
    return []
}  // of monthIndex

function executeApiRequest(res,segments) {
  try {
    let apiRequestType = segments[0].toLowerCase()
    if (apiRequestType=='month') {
      res.writeHead(200,'application/json')
      let contents = JSON.stringify(monthIndex(segments[1],segments[2]))
      res.end(contents)
    } else if (apiRequestType=='months') {
      res.writeHead(200,'application/json')
      let contents = JSON.stringify(imageDirectory.getMonths(segments[1]))
      res.end(contents)
    } else if (apiRequestType=='years') {
      res.writeHead(200,'application/json')
      let contents = JSON.stringify(imageDirectory.getYears())
      res.end(contents)

    }

  } catch (ex) {
    let exmessage = ex.message
    res.writeHead(500, {'Content-Type': 'text/plain'});
    res.end('Failed to execute. ' + segments.join('/')+ ' with '+exmessage);
  }

} // of executeApiRequest

function serveStaticFile(res, path, contentType:string='', responseCode:number = 200) {
  if (!contentType) {
    let extention = path.substr(path.lastIndexOf('.')+1).toLowerCase();
    switch(extention) {
      case 'css': contentType = 'text/css'; break;
      case 'js': contentType = 'application/javascript'; break;
      case 'json': contentType = 'application/json'; break;
      case 'vue': contentType = 'text/html'; break;
      case 'html': contentType = 'text/html'; break;
      default: contentType = 'text/plain'; break;
    };
  }

  fs.readFile(path, function(err,data) {
    if(err) {
      res.writeHead(500, { 'Content-Type': 'text/plain' });
      res.end('500 - Internal Error '+err.message+' '+path);
    } else {
      res.writeHead(responseCode,
        { 'Content-Type': contentType });
      res.end(data);
    }
  });
} // of serveStaticFile

class FSDirectory {
  constructor (root,parent) {
    this._sep = '\\'; // windows
    this._isLoaded = false;
    this._directories = [];
    this._files = [];
    this._fullpath = '';
    this._root = root;
    this._parent = parent;
    if (parent)
      this._fullpath = parent._fullpath+this._sep+this._root;
    else
      this._fullpath = this._root;
    if (fs.existsSync(this._fullpath)) {
      let stats = fs.statSync(this._fullpath);
      if (!stats.isDirectory())
        throw new Error(this._fullpath+ 'is a file not a directory');
    } else {
      throw new Error('Directory not found for ' + this._fullpath);
    }
  } // of constructor

  loadDirectAndFiles() {
    if (! this._isLoaded) {
      this._directories = [];
      this._files = [];
      let fileNames = fs.readdirSync(this._fullpath);
      for (let fileIx = 0; fileIx < fileNames.length; fileIx++) {
        let fullName = this._fullpath + this._sep + fileNames[fileIx];
        let stats = fs.statSync(fullName);
        if (stats.isDirectory(fullName))
          this._directories.push(new FSDirectory(fileNames[fileIx], this));
        else
          this._files.push({'filename': '/photos/'+this._root+'/'+fileNames[fileIx], 'fullname': fullName, 'stats': stats});
      } // of file loop
      this._isLoaded = true;
    } // of first time
  }; // of loadDirectAndFiles

  directories() {
    this.loadDirectAndFiles();
    return this._directories;
  } // of directories

  files() {
    this.loadDirectAndFiles();
    return this._files;
  } // of files

  path() {
    return  this._fullpath;
  }

  walk(callback) {
    this.files.forEach((thisFile) => callback(thisFile));
    this.directories.forEach((thisDirectory) => thisDirectory.walk(callback));
  } // of walk

}  // of FSDirectory


// start up
var config = loadConfig();
http.createServer(responder).listen(config.port);
console.log('Server started on localhost:'+config.port+'; press Ctrl-C to terminate....');
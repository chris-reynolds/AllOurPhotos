"use strict";
import * as fs from 'fs'
import ImgCatalog, {ImgDirectory} from './imgCatalog'
import {FsDirectory} from "./fsUtils";
import * as http from 'http'
import {Server} from "http";
import {ImageUploader} from "./imageUploader";

let  selfWS :AopWebServer  // record singleton for callback

export class AopWebServer {
  public imgCatalog : ImgCatalog
  public httpServer : Server
  constructor (public config:any){
    this.imgCatalog = new ImgCatalog(new FsDirectory(config.imagesDir))
    this.httpServer = http.createServer(this.responder)
    this.httpServer.listen(config.port);
    console.log('Server started on localhost:'+config.port+'; press Ctrl-C to terminate....');
    selfWS = this
  } // of constructor

  responder(req,res) {
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
        selfWS.serveStaticFile(res, selfWS.config.clientDir + '/index.html', 'text/html');
        break;
      case 'images':
        selfWS.serveStaticFile(res, selfWS.config.imagesDir + shortPath, 'image/jpeg');
        break;
      case 'new_image':
        (new ImageUploader()).newImageHandler(req,res)
        break
      case 'test':
        selfWS.serveStaticFile(res, selfWS.config.testDir + shortPath, 'text/html');
      case 'api':
        selfWS.executeApiRequest(res,segments)
        break
      case 'testform':
        res.writeHead(200, {"Content-Type": "text/html"});
        res.write(
          `<form action="/new_image/blah" method="post" enctype="multipart/form-data">
          <input type="file" multiple id="fileUpload">
          <input type="hidden" id="fileDates">
          <input type="submit" value="Upload">
          </form>
          <script>
/*        let fileInput = document.getElementById("fileUpload");
        let fileDates = document.getElementById("fileDates");
        fileInput.addEventListener("change", function(event) { 
          let files = event.target.files;
          let result = ''
          for (let i = 0; i < files.length; i++) {
            const date = new Date(files[i].lastModified);
            result += (files[i].name + " has a last modified date of " + date);
          }
          fileDates.value = result
        }); */
        </script>
`
        );
        res.end();
        break
      default:
        let possFilename = selfWS.config.clientDir+thisReq.path;
        if (fs.existsSync(possFilename)) {
          selfWS.serveStaticFile(res, possFilename);
        } else {
          res.writeHead(404, {'Content-Type': 'text/plain'});
          res.end(possFilename+ ' not found' + selfWS.config.started.toString());
        }
    } // of switch
  } // of responder

  assert(expr,errmessage) {
    if (!expr) throw new Error(errmessage)
  }

  compoundMonthKey(year,month) {
    selfWS.assert((year>=1980) && (year<=2030),'Year most be at between 1980 and 2030')
    selfWS.assert((month>0) && (month<=12),'Month must be between  and 12')
    return year.toString()+'-'+(100+month).toString().substr(-2)
  } // of monthKey

  monthIndex(year,month) {
    let monthKey = selfWS.compoundMonthKey(year,month)
    let thisMonth : ImgDirectory = selfWS.imgCatalog.getDirectory(monthKey)
    if (thisMonth) {
      thisMonth.files.forEach(thisFile => thisFile['url'] = thisMonth.directoryName+'/'+thisFile.filename)
      return {directory:thisMonth.directoryName,files:thisMonth.files}
    } else
      return {directory:'??'+year+'/'+month+'????',files:[]}
  }  // of monthIndex

  executeApiRequest(res,segments) {
    try {
      let apiRequestType = segments[0].toLowerCase()
      if (apiRequestType=='month') {
        if (segments.length!=3) throw new Error('month url requires 2 parameters')
        res.writeHead(200,{'Content-Type': 'application/json'})
        let contents = JSON.stringify(selfWS.monthIndex(segments[1],segments[2]))
        res.end(contents)
      } else if (apiRequestType=='year') {
        if (segments.length!=2) throw new Error('year url requires 1 parameters')
        res.writeHead(200,{'Content-Type': 'application/json'})
        let contents = JSON.stringify(selfWS.imgCatalog.getYear(segments[1]))
        res.end(contents)
      } else if (apiRequestType=='years') {
        if (segments.length!=1) throw new Error('years url requires 0 parameters')
        res.writeHead(200,{'Content-Type': 'application/json'})
        let contents = JSON.stringify(selfWS.imgCatalog.getYears())
        res.end(contents)

      }

    } catch (ex) {
      let exmessage = ex.message
      res.writeHead(500, {'Content-Type': 'text/plain'});
      res.end('Failed to execute. ' + segments.join('/')+ ' with '+exmessage + '\n' +ex.stack);
    }

  } // of executeApiRequest

    serveStaticFile(res, path, contentType:string='', responseCode:number = 200):void {
    if (!contentType) {
      let extention = path.substr(path.lastIndexOf('.')+1).toLowerCase();
      switch(extention) {
        case 'css': contentType = 'text/css'; break;
        case 'js': contentType = 'application/javascript'; break;
        case 'json': contentType = 'application/json'; break;
        case 'vue': contentType = 'text/html'; break;
        case 'html': contentType = 'text/html'; break;
        default: contentType = 'text/plain'; break;
      }
    }

    fs.readFile(path, function(err,data) {
      if(err) {
        res.writeHead(404, { 'Content-Type': 'text/plain' });
        res.end('404 - '+err.message);
      } else {
        res.writeHead(responseCode,
          { 'Content-Type': contentType });
        res.end(data);
      }
    });
  } // of serveStaticFile


} // of AopWebServer
"use strict";
import * as fs from 'fs'
import ImgCatalog, {ImgDirectory} from './imgCatalog'
import {FsDirectory} from "./fs_utils";
import * as http from 'http'
import * as Formidable from 'formidable'

export class ImageUploader {
  static newImageHandler(req,res) {
    let segments : string[] = req.url.split('/')
    let imageName = segments[segments.length-1]  // pick the right hand bit
    console.log('new Image URL is '+imageName)
    let form = new Formidable.IncomingForm()
    form.parse(req,function(err, fields, files) {
      for (let fileName in files) {
        console.log('Ive got a file3 ' + files[fileName].name + ' in ' + files[fileName].path);
      }
      })
    form.on('end',function() {
      res.writeHead(404, {'Content-Type': 'text/plain'});
      res.end('new image handler - still todooooooooooooo');

    })
  }


}

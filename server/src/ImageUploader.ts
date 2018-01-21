"use strict";
//import * as fs from 'fs'
import ImgCatalog from './imgCatalog'
//import {FsDirectory} from "./fsUtils";
//import * as http from 'http'
import * as Formidable from 'formidable'


export class ImageUploader {
//  errorMessage:string = ''
  public newImageHandler(req,res) {
    let self = this
    let segments : string[] = req.url.split('/')
    let imageName = segments[segments.length-1]  // pick the right hand bit
    console.log('new Image URL is '+imageName)
    let form = new Formidable.IncomingForm()
    form.multiples = true
    form.res = res
    form['myErrorMessage'] = ''
    form.on('file',function(fieldname:string,thisFile){
      if (thisFile && thisFile.name && thisFile.name.toLowerCase().match(/.*jpg/)) {
        try {
          ImgCatalog.importTempFile(thisFile.name, thisFile.path)
        } catch(ex) {
          this.myErrorMessage = 'Failed to upload '+thisFile.name+"\n" + ex.stack
        }
      }
    })
/*    form.on('end',function(fred) {
      if (this.myErrorMessage=='') {
        res.writeHead(404, {'Content-Type': 'text/plain'});
        res.end('new image handler - still todooooooooooooo');
      } else {
        res.writeHead(500, {'Content-Type': 'text/plain'});
        res.end('new image handler - failed:'+ "\n" + this.myErrorMessage);
      }
      })
 */
    form.parse(req,this.handleFormParser(form))
 /*   form.parse(req,function (err,fields,files){
      let outerForm = {errorMessage:''}
      for (let filename in files) {
        let thisFile = files[filename]
        console.log('Ive got a file ' + thisFile.name + ' in ' + thisFile.path);
        if (thisFile.name.toLowerCase().match(/.*jpg/)) {
          // let catalog = ImgCatalog.catalogSingleton
          try {
            ImgCatalog.importTempFile(thisFile.name,thisFile.path)
          } catch(ex) {
            outerForm.errorMessage = outerForm.errorMessage+ '\n' + ex.message
          } // of try/catch
        } // of
      } // file loop
    }) // return function and end of form.parse */
  } // of newImageHandler

  handleFormParser(outerForm):{(err,fields,files):void} {
    return function (err,fields,files){
      let uploadList =  files.fileUpload || []
      if (!Array.isArray(uploadList))
        uploadList = [uploadList]
      for (let filename in uploadList) {
        let thisFile = uploadList[filename]
        console.log('Ive got a file ' + thisFile.name + ' in ' + thisFile.path);
        if (thisFile.name.toLowerCase().match(/.*jpg/)) {
          // let catalog = ImgCatalog.catalogSingleton
          try {
            ImgCatalog.importTempFile(thisFile.name,thisFile.path)
          } catch(ex) {
            outerForm.errorMessage = outerForm.errorMessage+ '\n' + ex.message
          } // of try/catch
        } // of
      } // file loop
      if (outerForm.myErrorMessage=='') {
        outerForm.res.writeHead(404, {'Content-Type': 'text/plain'});
        outerForm.res.end('new image handler - still todooooooooooooo');
      } else {
        outerForm.res.writeHead(500, {'Content-Type': 'text/plain'});
        outerForm.res.end('new image handler - failed:'+ "\n" + outerForm.myErrorMessage);
      }

    } // return function
  } // of handleFormParser


}

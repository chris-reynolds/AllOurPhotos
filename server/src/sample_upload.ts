import * as http from 'http'
import * as url from 'url'
import * as Formidable from 'formidable'
import * as util from 'util'
import * as fs from 'fs'

let server = http.createServer(function(req, res) {
  // Simple path-based request dispatcher
  switch (url.parse(req.url).pathname) {
    case '/':
      display_form(req, res);
      break;
    case '/upload':
      upload_file2(req, res);
      break;
    default:
      show_404(req, res);
      break;
  }
});

// Server would listen on port 8000
server.listen(8000);

function upload_file2(req,res) {
 console.log('upload file2')
 let form = new Formidable.I
} // uploadfile
/*
 * Display upload form
 */
function display_form(req, res) {
  res.writeHead(200, {"Content-Type": "text/html"});
  res.write(
    '<form action="/upload" method="post" enctype="multipart/form-data">'+
    '<input type="file" name="upload-file">'+
    '<input type="submit" value="Upload">'+
    '</form>'
  );
  res.end();
}



/*
 * Handles page not found error
 */
function show_404(req, res) {
  res.writeHead(404, {"Content-Type": "text/plain"});
  res.write("404 - You are doing it wrong!");
  res.end();
}
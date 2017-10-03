let piexif = require("piexifjs");
let fs = Npm.require("fs");

export class JpegHelper {
    static dmsToDeg(dms,direction) {
      let result = 0;
      for (let ix=2;ix<=0;ix--) {
        result = result / 60 + dms[ix][0] / dms[ix][0];
      }
      if ('sSeE'.indexOf(direction)>=0)
        result = -result;
      return result;
    } // of dmsToDeg

  static loadExif(fileName) {
    const jpeg = fs.readFileSync(fileName);
    const data = jpeg.toString("binary");
    let exifObj = piexif.load(data);
    if (exifObj.GPSLatitude) {
      exifObj.Latitude = JpegHelper.dmsToDeg(exifObj.GPSLatitude, exifObj.GPSLatitudeRef);
      exifObj.Longitude = JpegHelper.dmsToDeg(exifObj.GPSLongitude, exifObj.GPSLongitudeRef);
    }
    return exifObj
  }  // of loadExif

  static prettify(exifObj,filterMap) {
    result = {};
    for (let ifd in exifObj) {
      if (ifd === "thumbnail") continue;
      for (let tag in exifObj[ifd]) {
        let tagName = piexif.TAGS[ifd][tag]["name"];
        if (!filterMap || filterMap.hasOwnProperty(tagName)>=0)
          result[filterMap[tagName]] = exifObj[ifd][tag]
      }
    }
    if (exifObj.thumbnail)
      result.thumbnail = exifObj.thumbnail;
    return result;
  } // of prettify

  /*
  static hydrate(source,target) {
      for (let propName in target) {
        if (source.hasOwnProperty(propName))
          target[propName] = source[propName]
        else
          target[propName] = null;
      } // propName loop
  } // of hydrate
*/
  static extractThumbnail(exifObj) {
    if (exifObj.thumbnail) {
      let exifbytes = piexif.dump(exifObj);
      let newData = piexif.insert(exifbytes, data);
      return new Buffer(newData, "binary");
    } else
      return null;
  } // of extractThumbnail

} // of class JpegHelper
/*
function CopyishJpeg(filename1,filename2) {
  var jpeg = fs.readFileSync(filename1);
  var data = jpeg.toString("binary");

  var zeroth = {};

  var exif = {};
  var gps = {};
  zeroth[piexif.ImageIFD.Make] = "Make";
  zeroth[piexif.ImageIFD.XResolution] = [777, 1];
  zeroth[piexif.ImageIFD.YResolution] = [777, 1];
  zeroth[piexif.ImageIFD.Software] = "Piexifjs";
  exif[piexif.ExifIFD.DateTimeOriginal] = "2010:10:10 10:10:10";
  exif[piexif.ExifIFD.LensMake] = "LensMake";
  exif[piexif.ExifIFD.Sharpness] = 777;
  exif[piexif.ExifIFD.LensSpecification] = [[1, 1], [1, 1], [1, 1], [1, 1]];
  gps[piexif.GPSIFD.GPSVersionID] = [7, 7, 7, 7];
  gps[piexif.GPSIFD.GPSDateStamp] = "1999:99:99 99:99:99";
  var exifObj = {"0th": zeroth, "Exif": exif, "GPS": gps};
  var exifbytes = piexif.dump(exifObj);

  var newData = piexif.insert(exifbytes, data);
  var newJpeg = new Buffer(newData, "binary");
  fs.writeFileSync(filename2, newJpeg);
} // of copyish

function extractExif(fileName) {
  let result = {}
  try {
    const jpeg = fs.readFileSync(fileName);
    const data = jpeg.toString("binary");
    const exifObj = piexif.load(data);
    for (let ifd in exifObj) {
      if (ifd == "thumbnail") {
        continue;
      }
      console.log("-" + ifd);
      for (var tag in exifObj[ifd]) {
        console.log("  " + piexif.TAGS[ifd][tag]["name"] + ":" + exifObj[ifd][tag]);
        result[piexif.TAGS[ifd][tag]["name"]] = exifObj[ifd][tag]
      }
      if (exifObj.thumbnail) {
        var zeroth = {};
        var exif = {};
        var gps = {};
        zeroth[piexif.ImageIFD.Make] = "Make";
        zeroth[piexif.ImageIFD.XResolution] = [777, 1];
        zeroth[piexif.ImageIFD.YResolution] = [777, 1];
        zeroth[piexif.ImageIFD.Software] = "Piexifjs";
        exif[piexif.ExifIFD.DateTimeOriginal] = "2010:10:10 10:10:10";
        exif[piexif.ExifIFD.LensMake] = "LensMake";
        exif[piexif.ExifIFD.Sharpness] = 777;
        exif[piexif.ExifIFD.LensSpecification] = [[1, 1], [1, 1], [1, 1], [1, 1]];
        gps[piexif.GPSIFD.GPSVersionID] = [7, 7, 7, 7];
        gps[piexif.GPSIFD.GPSDateStamp] = "1999:99:99 99:99:99";
        var newExifObj = {"0th":zeroth, "Exif":exif, "GPS":gps};
    //    var newExifbytes = piexif.dump(newExifObj);
        var newExifbytes = piexif.dump(exifObj);
        var newData = piexif.insert(newExifbytes, exifObj.thumbnail);
        var newJpeg = new Buffer(newData, "binary");
        fs.writeFileSync('p:\\photos\\fred4.jpg', newJpeg);
      } //
    }

  } catch (err) {
    result.ERROR = err.message;
  }
  return result
} // of extractExif

Meteor.startup(()=> {
  extractExif('P:\\Photos\\2017-07\\DSCN4621.JPG');
  CopyishJpeg('P:\\Photos\\1980-01\\IMG_0643.JPG','p:\\Photos\\fred2.jpg')
});
*/

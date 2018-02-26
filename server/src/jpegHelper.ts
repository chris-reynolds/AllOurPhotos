import * as fs from 'fs'
import * as _  from 'lodash'
import * as piexif from 'piexifjs'
import * as imageInfo from 'imageinfo'

const DEFAULT_TAKEN_DATE  = new Date('1900-01-01')

export class PartialExif {
  lastModifiedDate : Date
  dateTaken : Date
  latitude : Number
  longitude : Number
  camera : string
  orientation :number
  width : Number
  height : Number
}

export class JpegHelper {
    static dmsToDeg(dms,direction) {
      let result = 0;
      for (let ix of [2,1,0]) {
        result = result / 60 + (dms[ix][0] / dms[ix][1])
      }
      if ('sSeE'.indexOf(direction)>=0)
        result = -result;
      return result;
    } // of dmsToDeg


  static DateParse(s:string) :Date {
    if (s && s.length && s.length==19) {
      s = s.substr(0,4)+'-'+s.substr(5,2)+'-'+s.substr(8)
      return new Date(s)
    } else
      return null
  }


  static extractMetaData(fullName: string) {
      try {
        // temp path of an uplad might not end in jpg
//        if (fullName.substr(-4).toLowerCase() != '.jpg')
//          throw new Error('Only *.jpg supported ')
        let pictureBuffer = fs.readFileSync(fullName)
        let pictureBasicInfo = imageInfo(pictureBuffer)
        let exifData = JpegHelper.loadExif(fullName)
        let jpegDetails = JpegHelper.partialExtract(exifData)
        _.assign(jpegDetails, pictureBasicInfo)
        if (!jpegDetails.dateTaken)
          jpegDetails.dateTaken = DEFAULT_TAKEN_DATE
        return jpegDetails;
      } catch (ex){
        throw new Error(ex.message+' while extracting metadata from '+fullName)
      }
  } // extractMetaData

  static TrimNullChars(s:string):string {
      if (s)
        return s.replace(/\0/g, '')
    else
      return ''  // safely handle undefined
  } // of TrimNullChars

  static partialExtract(exifObj:any):PartialExif {
    let result = new PartialExif()
    if (_.isEmpty(exifObj))
       return result; // nothing to extract
    result.lastModifiedDate = exifObj.Exif[piexif.ExifIFD.DateTimeOriginal]
    result.dateTaken = JpegHelper.DateParse(exifObj.Exif[piexif.ExifIFD.DateTimeOriginal])
    let cameraMake = JpegHelper.TrimNullChars(exifObj['0th'][piexif.ImageIFD.Make])
    let cameraModel = JpegHelper.TrimNullChars(exifObj['0th'][piexif.ImageIFD.Model])
    if (cameraModel.indexOf(cameraMake)<0)   // no duplication
      result.camera = cameraMake+' '+cameraModel
    else
      result.camera = cameraModel
    result.orientation = exifObj['0th'][piexif.ImageIFD.Orientation]||0
    result.width = exifObj.Exif[piexif.ExifIFD.PixelXDimension]||0
    result.height = exifObj.Exif[piexif.ExifIFD.PixelYDimension]||0
    if (exifObj.GPS && exifObj.GPS[0] ) {
      result.latitude = JpegHelper.dmsToDeg(exifObj.GPS[2], exifObj.GPS[1]);
      result.longitude = JpegHelper.dmsToDeg(exifObj.GPS[4], exifObj.GPS[3]);
    }
    return result
  } // of aopExtract

  static loadExif(fileName) {
    const jpeg = fs.readFileSync(fileName);
    const data = jpeg.toString("binary");
    try {
      return piexif.load(data);
    } catch (ex) {
      console.log('unpacking problem in file '+fileName)
      return {}
    }
  }  // of loadExif

  static prettify(exifObj,filterMap) {
    let result = {};
    for (let ifd in exifObj) {
      if (ifd === "thumbnail") continue;
      for (let tag in exifObj[ifd]) {
        let tagName = piexif.TAGS[ifd][tag]["name"];
        if (!filterMap || filterMap.hasOwnProperty(tagName)>=0)
          result[filterMap[tagName]] = exifObj[ifd][tag]
      }
    }
    if (exifObj.thumbnail)
      result['thumbnail'] = exifObj.thumbnail;
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
  static extractThumbnail(exifObj,jpegdata) {
    if (exifObj.thumbnail) {
      let exifbytes = piexif.dump(exifObj);
      let newData = piexif.insert(exifbytes, jpegdata);
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


*/

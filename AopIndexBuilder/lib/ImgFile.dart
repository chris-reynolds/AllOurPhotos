/**
 * Created by Chris on 21/09/2018.
 */
import './Logger.dart' as log;
//import 'dart:core';
import 'dart:math' as Math;


const INDEX_FILENAME = 'index.tsv';

class ImgCatalog {
  static List<ImgDirectory> _directories = <ImgDirectory>[];

  static ImgDirectory getDirectory(String dirName) {
    for (ImgDirectory directory in _directories)
      if (directory.directoryName == dirName)
        return directory;
    return null;
  } // of getDirectory

  static ImgDirectory newDirectory(String dirName) {
    if (dirName.length!=7 || dirName.substring(4,4)!='-')
      throw ('Directory $dirName should be in the form yyyy-mm');
    if (getDirectory(dirName) != null)
      throw('Directory $dirName already exists');
    ImgDirectory result = ImgDirectory();
    result.directoryName = dirName;
    result.dirty = true;
    return result;
  } // of newDirectory

}  // of ImgCatalog

class ImgDirectory {
  List<ImgFile> files = <ImgFile>[];
  String directoryName;
  bool dirty = false;
  ImgFile getFile(String thisFilename) {
    for (ImgFile file in files)
      if (file.filename == thisFilename)
        return file;
     return null;
  } // of getFile

  static String directoryNameForDate(DateTime aDate) {
    int yy = aDate.year;
    int mm = aDate.month;
    return '$yy-${(mm <= 9) ? "0" : ""}$mm';
  }
}  // of ImgDirectory


class ImgFile {
  static const UNKNOWN_LONGLAT = 999.0;
  ImgFile (String this.dirname, String this.filename) {
    log.message('create ImgFile:'+fullFilename);
  } // of constructor

  String dirname;
  String filename;
  String caption = '-';
  DateTime takenDate;
  int byteCount;
  int width;
  int height;
  DateTime lastModifiedDate;
  int rank = 3;
  double latitude = UNKNOWN_LONGLAT;
  double longitude = UNKNOWN_LONGLAT;
  String location = '';
  String tags = '';
  String camera = 'unknown';
  int rotation = 0;
  String owner = 'all';
  String imageType = 'jpg';
  bool misplaced  = false;    // if registered in wrong directory
  bool hasThumbnail = false;
//  rotation : RotationType
  String contentHash  = '';
  DateTime deletedDate;

//  private _isJpeg : boolean = false

  String calcContentHash()  {
    String result = '1$byteCount:';
    int mmss = 0;
    if (takenDate != null)
      mmss = takenDate.minute*100+takenDate.second;
    if (mmss==0)
      mmss = 9000 + Math.Random().nextInt(999);
    result += '$mmss';
    // todo get some pixels rather than random numbers to breakup scanned images if the same
    return result;
  } // of calcContentHash

  String get fullFilename {
    return dirname+'/'+filename;
  }

  fromTabDelimited(String source) {
    List<String> fields = source.split('\t');
    if (fields.length != FIELD_COUNT)
      log.message('Invalid line :$source');
    else {
      for (String thisField in fields)
        if (thisField == 'null')
          thisField=null;
      dirname = fields[0];
      filename = fields[1];
      caption = fields[2];
      takenDate = DateTime.parse(fields[3]);
      byteCount = int.parse(fields[4]);
      width = int.parse(fields[5]);
      height = int.parse(fields[6]);
      lastModifiedDate = DateTime.parse(fields[7]);
      rank = int.parse(fields[8]);
      latitude = double.tryParse(fields[9])??-1.0;
      longitude = double.tryParse(fields[10])??-1.0;
      location = fields[11];
      tags = fields[12];
      camera = fields[13];
      rotation = int.parse(fields[14]);
      owner = fields[15];
      imageType = fields[16];
      hasThumbnail = (fields[17]=='y');
      contentHash = fields[18];
      deletedDate = DateTime.parse(fields[19]);
    }
  } // of fromTabDelimited

  String toTabDelimited() {
    String t='\t';
    return '$dirname$t$filename$t$caption$t$takenDate$t$byteCount$t$width$t'+
       '$height$t$lastModifiedDate$t$rank$t$latitude$t$longitude$t'+
        '$location$t$tags$t'+
    '$camera$t$rotation$t$owner$t$imageType$t${hasThumbnail?"y":"n"}$t'+
        '$contentHash$t$deletedDate';
  } // toMap

} // of ImgFile

const FIELD_COUNT = 20;
final ImgFileHeader = "dirname\tfilename\tcaption\ttakenDate\tbyteCount\twidth\t"+
    "height\tlastModifiedDate\trank\tlatitude\tlongitude\tlocation\ttags\t"+
    "camera\trotation\towner\timageType\thasThumbnail\tcontentHash\tdeletedDate";
/**
 * Created by Chris on 21/09/2018.
 */
import './Logger.dart' as log;
//import 'dart:core';
import 'dart:math' as Math;
import 'dart:collection';


const INDEX_FILENAME = 'index.tsv';

typedef  boolFunction = bool Function();
class ImgCatalog {
  static List<ImgDirectory> _directories = <ImgDirectory>[];

  static ImgDirectory getDirectory(String dirName) {
    for (ImgDirectory directory in _directories)
      if (directory.directoryName == dirName)
        return directory;
    return null;
  } // of getDirectory

  static ImgDirectory newDirectory(String dirName) {
    if (dirName.length!=7 || dirName.substring(4,5)!='-')
      throw ('Directory $dirName should be in the form yyyy-mm');
    if (getDirectory(dirName) != null)
      throw('Directory $dirName already exists');
    ImgDirectory result = ImgDirectory();
    result.directoryName = dirName;
    result.dirty = true;
    _directories.add(result);
    return result;
  } // of newDirectory

  static bool saveAll() {
    bool result = true;
    for (ImgDirectory dir in _directories)
      result = ImgDirectory.save(dir) && result;
    return result;
  } // of save

  static bool actOnAll(ImgFileAction thisAction) {
    bool result = true;
    for (ImgDirectory dir in _directories) {
      bool directoryResult = true;
      log.message('ActOnAll starting in ${dir.directoryName}');
      for (var thisImgFile in dir) {
        directoryResult =  thisAction(thisImgFile) && directoryResult;
      } // of file loop
      log.message('${directoryResult?"Passed":"Failed"} in ${dir.directoryName}');
      result = directoryResult && result;
    } // of directory loop
    return result;
  } // of actOnAll

  static clear() {
    _directories.length = 0;
  } // of clear
}  // of ImgCatalog

typedef ImgDirectoryAction = bool Function(ImgDirectory);
class ImgDirectory extends IterableBase{
  static ImgDirectoryAction save = (img) => throw "Directory Save handler not defined";
  List<ImgFile> files = <ImgFile>[];
  get iterator => files.iterator;
  String directoryName;
  DateTime modifiedDate = DateTime(1980); // way-back
  bool dirty = false;
  ImgFile getFile(String thisFilename,{bool force = false}) {
    for (ImgFile file in files)
      if (file.filename == thisFilename)
        return file;
      if (!force)
        return null;
      else {
        ImgFile newFile = ImgFile(directoryName, thisFilename);
        files.add(newFile);
        dirty = true;
        return newFile;
      }
  } // of getFile
  ImgFile operator [](String s) => getFile(s);
  static String directoryNameForDate(DateTime aDate) {
    int yy = aDate.year;
    int mm = aDate.month;
    return '$yy-${(mm <= 9) ? "0" : ""}$mm';
  }
  List<String> toStrings() {
    List<String>result = [];
    result.add(ImgFileHeaderLine);
    for (var file in files)
      result.add(file.toTabDelimited());
    return result;
  } // toStrings

  bool fromStrings(List<String> lines) {
    bool result = true;
    files.length = 0;
    lines.removeAt(0); // remove headerline
    for (var thisLine in lines) {
      ImgFile file = ImgFile('',''); // load blank
      if (file.fromTabDelimited(thisLine)) {
        files.add(file);
      } else {
        log.error('Problem in index line ${lines.indexOf(thisLine)}');
      }
    } // of line loop
    return result;
  } // of fromStrings
}  // of ImgDirectory

typedef ImgFileAction = bool Function(ImgFile);
class ImgFile {
  static const UNKNOWN_LONGLAT = 999.0;
  static ImgFileAction save = (img) => throw "Save handler not defined";
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
    result += '$mmss:$width:$height';
    // todo get some pixels rather than random numbers to breakup scanned images if the same
    return result;
  } // of calcContentHash

  String get fullFilename {
    return dirname+'/'+filename;
  }

  ImgDirectory get directory  => ImgCatalog.getDirectory(dirname);

  bool fromTabDelimited(String source) {
    List<String> fields = source.split('\t');
    if (fields.length != FIELD_COUNT) {
      log.message('Invalid line :$source');
      return false;
    } else {
      for (int fieldIx = 0; fieldIx < fields.length; fieldIx++) {
        if (fields[fieldIx] == 'null')
          fields[fieldIx] = null;
      }
      try {
        dirname = fields[0];
        filename = fields[1];
        caption = fields[2];
        takenDate = (fields[3] != null) ? DateTime.parse(fields[3]) : null;
        byteCount = (fields[4] != null) ? int.tryParse(fields[4]) : null;
        width = (fields[5] != null) ? int.tryParse(fields[5]) : null;
        height = (fields[6] != null) ? int.tryParse(fields[6]) : null;
        lastModifiedDate = DateTime.parse(fields[7]);
        rank = int.parse(fields[8]);
        latitude = double.tryParse(fields[9]) ?? -1.0;
        longitude = double.tryParse(fields[10]) ?? -1.0;
        location = fields[11];
        tags = fields[12];
        camera = fields[13];
        rotation = int.parse(fields[14]);
        owner = fields[15];
        imageType = fields[16];
        hasThumbnail = (fields[17] == 'y');
        contentHash = fields[18];
        deletedDate = (fields[19] != null) ? DateTime.parse(fields[19]) : null;
      } catch(ex) {
        log.error('failed to load an index line');
        rethrow;
      }
    }
    return true;
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
final ImgFileHeaderLine = "dirname\tfilename\tcaption\ttakenDate\tbyteCount\twidth\t"+
    "height\tlastModifiedDate\trank\tlatitude\tlongitude\tlocation\ttags\t"+
    "camera\trotation\towner\timageType\thasThumbnail\tcontentHash\tdeletedDate";
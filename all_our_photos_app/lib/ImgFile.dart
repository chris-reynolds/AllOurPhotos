/**
 * Created by Chris on 21/09/2018.
 */
import './Logger.dart' as log;
//import 'dart:math' as Math;
import 'dart:collection';
import 'dart:async';


const INDEX_FILENAME = 'index.tsv';

typedef  boolFunction = bool Function();
class ImgCatalog {
  static List<ImgDirectory> _directories = <ImgDirectory>[];

  static ImgDirectory getDirectory(String dirName,{bool forceInsert=false}) {
    for (ImgDirectory directory in _directories) {
      if (directory.directoryName == dirName)
        return directory;
    }
    if (forceInsert)
      return newDirectory(dirName);
    else
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

  static bool forEachDir(ImgDirectoryAction thisAction) {
    bool result = true;
    for (ImgDirectory dir in _directories) {
      bool directoryResult = thisAction(dir);
      result = directoryResult && result;
    } // of directory loop
    return result;
  } // of forEachDir

  static bool actOnAll(ImgFileAction thisAction) {
    bool result = true;
    for (ImgDirectory dir in _directories) {
      bool directoryResult = true;
///      log.message('ActOnAll starting in ${dir.directoryName}');
      for (var thisImgFile in dir) {
        directoryResult =  thisAction(thisImgFile) && directoryResult;
      } // of file loop
///      log.message('${directoryResult?"Passed":"Failed"} in ${dir.directoryName}');
      result = directoryResult && result;
    } // of directory loop
    return result;
  } // of actOnAll

  static Future<bool> asyncActOnAll(ImgFileFutureAction thisFutureAction) async {
    bool result = true;
    for (ImgDirectory dir in _directories) {
      bool directoryResult = true;
      log.message('awaitActOnAll starting in ${dir.directoryName}');
      for (var thisImgFile in dir) {
        bool f = await thisFutureAction(thisImgFile);
        directoryResult = f  && directoryResult;
      } // of file loop
      log.message('${directoryResult?"Passed":"Failed"} in ${dir.directoryName}');
      result = directoryResult && result;
    } // of directory loop
    return result;
  } // of asyncActOnAll

  static clear() {
    _directories.length = 0;
  } // of clear

  static get length => _directories.length;
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
    result.add(IMGFILECOLUMNHEADER);
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
    dirty = false;
    return result;
  } // of fromStrings
}  // of ImgDirectory

typedef ImgFileAction = bool Function(ImgFile);
typedef ImgFileFutureAction = Future<bool> Function(ImgFile);

class ImgFile {
  static const UNKNOWN_LONGLAT = 999.0;
  static ImgFileAction save = (img) => throw "Save handler not defined";
  ImgFile (this.dirname, this.filename, {bool forceInsert:false}) {
 //   log.message('create ImgFile:'+fullFilename);
    if (forceInsert)
      ImgDirectory directory = ImgCatalog.getDirectory(dirname,forceInsert:true);
    directory.files.add(this);
   } // of constructor

  void markDirty() {
    ImgCatalog.getDirectory(dirname).dirty = true;
  } // of markDirty

  String dirname;
  String filename;
  String _caption = '-';
  get caption => _caption;
  set caption(String value) {
    _caption = value;
    markDirty();
  }
  DateTime _takenDate;
  get takenDate => _takenDate;
  set takenDate(DateTime value) {
    _takenDate = value;
    markDirty();
  }
  int byteCount;
  int width;
  int height;
  DateTime lastModifiedDate;
  int _rank = 3;
  get rank => _rank;
  set rank(int value) {
    _rank = value;
    markDirty();
  }
  double latitude = UNKNOWN_LONGLAT;
  double longitude = UNKNOWN_LONGLAT;
  String _location = '';
  get location => _location;
  set location(String value) {
    _location = value;
    markDirty();
  }
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

  bool hasLonglat() => (longitude != UNKNOWN_LONGLAT) && (latitude != UNKNOWN_LONGLAT);
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
        latitude = double.tryParse(fields[9]) ?? UNKNOWN_LONGLAT;
        longitude = double.tryParse(fields[10]) ?? UNKNOWN_LONGLAT;
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
    // we need to ensure that the only tabs in the line are for field separation
    String t = '~@`@~';  // random unlikely string
    String tab = '\t';
    String result =  '$dirname$t$filename$t$caption$t$takenDate$t$byteCount$t$width$t'+
       '$height$t$lastModifiedDate$t$rank$t$latitude$t$longitude$t'+
        '$location$t$tags$t'+
    '$camera$t$rotation$t$owner$t$imageType$t${hasThumbnail?"y":"n"}$t'+
        '$contentHash$t$deletedDate';
    result = result.replaceAll(tab, " ");
    result = result.replaceAll(t,tab);
    return result;
  } // toMap

} // of ImgFile

const FIELD_COUNT = 20;
const IMGFILECOLUMNHEADER = "dirname\tfilename\tcaption\ttakenDate\tbyteCount\twidth\t"+
    "height\tlastModifiedDate\trank\tlatitude\tlongitude\tlocation\ttags\t"+
    "camera\trotation\towner\timageType\thasThumbnail\tcontentHash\tdeletedDate";
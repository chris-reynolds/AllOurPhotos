//
//  Model classes for All Our Photos generated by dartBO.txt on 29-Nov-2023 07:42:10 by chris
//
import 'dart:async';
import 'domain_object.dart';
//                                '*** Start Custom Code imports
// ignore_for_file: unnecessary_getters_setters
import 'dart:math' as math;
import 'package:path/path.dart' as path;
import 'package:aopcommon/aopcommon.dart';
//import '../utils/WebFile.dart';

//                                '*** End Custom Code

// Domain object providers
var albumProvider = DOProvider<AopAlbum>(
    "albums",
    [
      "name",
      "description",
      "first_date",
      "last_date",
      "user_id",
    ],
    AopAlbum.maker);
var albumItemProvider = DOProvider<AopAlbumItem>(
    "album_items",
    [
      "album_id",
      "snap_id",
    ],
    AopAlbumItem.maker);
var sessionProvider = DOProvider<AopSession>(
    "sessions",
    [
      "start_date",
      "end_date",
      "source",
      "user_id",
    ],
    AopSession.maker);
var snapProvider = DOProvider<AopSnap>(
    "snaps",
    [
      "file_name",
      "directory",
      "taken_date",
      "original_taken_date",
      "modified_date",
      "device_name",
      "caption",
      "ranking",
      "longitude",
      "latitude",
      "width",
      "height",
      "location",
      "rotation",
      "degrees",
      "import_source",
      "media_type",
      "imported_date",
      "media_length",
      "tag_list",
      "metadata",
      "session_id",
      "user_id",
    ],
    AopSnap.maker);
var userProvider = DOProvider<AopUser>(
    "users",
    [
      "name",
      "hint",
    ],
    AopUser.maker);

//-------------------------------------------------------------------
//----------------Album--------------------------------------
//-------------------------------------------------------------------
class AopAlbum extends DomainObject {
  late String name;
  String? description;
  DateTime? firstDate;
  DateTime? lastDate;
  int? _userId;

//                                '*** Start Custom Code privatealbum
//                                '*** End Custom Code
  // constructor
  AopAlbum({required Map<String, dynamic> data}) : super(data: data) {
    fromMap(data);
//                                '*** Start Custom Code album.create
    name = 'blah';
//                                '*** End Custom Code
  } // of constructor

//Associations
  Future<List<AopAlbumItem>> get albumItems async =>
      albumItemProvider.getWithFKey('album_id', id);
  Future<AopUser> get user async => userProvider.get(_userId);
  int? get userId => _userId;
  set userId(int? newId) {
    _userId = newId;
  } // of userId

//maker function for the provider
  static AopAlbum maker() {
    return AopAlbum(data: {});
  }

// To/From Map for persistence
  @override
  void fromMap(Map<String, dynamic> map) {
    if (map.isEmpty) return;
    id = map['id'];
    createdOn = fromDbDate(map['created_on']);
    updatedOn = fromDbDate(map['updated_on']);
    updatedUser = map['updated_user'];
    name = map['name'];
    description = map['description'];
    firstDate = fromDbDate(map['first_date']);
    lastDate = fromDbDate(map['last_date']);
    _userId = map['user_id'];
  } // fromMap

  @override
  Map<String, dynamic> toMap() {
    Map<String, dynamic> result = {};
    result['id'] = id;
    result['created_on'] = dbDate(createdOn);
    result['updated_on'] = dbDate(updatedOn);
    result['updated_user'] = updatedUser;
    result['name'] = name;
    result['description'] = description;
    result['first_date'] = dbDate(firstDate);
    result['last_date'] = dbDate(lastDate);
    result['user_id'] = _userId;
    return result;
  } // fromMap

  @override
  void fromRow(dynamic row) {
    String fld = 'unassigned';
    super.fromRow(row);
    try {
      fld = 'name';
      name = row[4];
      fld = 'description';
      description = row[5];
      fld = 'firstDate';
      firstDate = row[6];
      fld = 'lastDate';
      lastDate = row[7];
      fld = '_userId';
      _userId = row[8];
    } catch (ex) {
      throw Exception('Failed to assign field $fld : $ex');
    }
  } // from Row

  @override
  List<dynamic> toRow({bool insert = false}) {
    var result = [];
    if (insert) result = super.toRow();
    result.add(name);
    result.add(description);
    result.add(dbDate(firstDate!));
    result.add(dbDate(lastDate!));
    result.add(_userId);
    return result;
  } // to Row

  @override
  Future<int?> save({bool validate = true}) async {
    if (validate) await this.validate();
    if (isValid) {
      return await albumProvider.save(this);
    } else {
      throw Exception("Failed to save\n${lastErrors.join('\n')}");
    }
  } // of save

  @override
  Future<bool> delete() async {
    return await albumProvider.delete(this);
  } // of delete

//                                '*** Start Custom Code album custom procedures
  static Future<List<AopAlbum>> all() async {
    return albumProvider.getSome('1=1', orderBy: 'name');
  } // all Albums

  Future<List<AopSnap>> get snaps async {
    return snapProvider.getSome(
        'id in (select snap_id from aopalbum_items where album_id=$id)',
        orderBy: 'taken_date,caption,id');
  } //  snaps property

  Future<int> addSnaps(List<int> newSnapIds) async {
    int result = 0;
    List<AopAlbumItem> existingItems = await albumItems;
    for (int newId in newSnapIds) {
      bool found = false;
      for (AopAlbumItem item in existingItems) {
        if (item.snapId == newId) found = true;
      }
      if (!found) {
        AopAlbumItem newItem = AopAlbumItem(data: {});
        newItem.albumId = id;
        newItem.snapId = newId;
        await newItem.save();
        existingItems.add(newItem);
        result += 1;
      } // inserted newone
    }
    return result;
  } // of addSnaps

  Future<int> removeSnaps(List<AopSnap> oldSnaps) async {
    int result = 0;
    List<int?> oldSnapIds = idList(oldSnaps);
    List<AopAlbumItem> existingItems = await albumItems;
    for (AopAlbumItem thisItem in existingItems) {
      if (oldSnapIds.contains(thisItem.snapId)) {
        await thisItem.delete();
        result += 1;
      }
    }
    return result;
  } // of removeSnaps

  @override
  Future<void> validate() async {
    await super.validate(); // clear last errors
    if (name.length < 10) lastErrors.add('name must be 10 characters long');
    //  String yearStr = name.substring(0, 4);
    //  int yearNo = int.tryParse(yearStr) ?? -1;
    if (yearNo < 1900 || yearNo > 2099) {
      lastErrors.add('name should start with 4 digit year');
    }
  } // of validate

  int get yearNo {
    String yearStr = name.substring(0, 4);
    return int.tryParse(yearStr) ?? -1;
  } // of yearNo
//                                '*** End Custom Code
} // of class album

//-------------------------------------------------------------------
//----------------Album Item--------------------------------------
//-------------------------------------------------------------------
class AopAlbumItem extends DomainObject {
  int? _albumId;
  int? _snapId;

//                                '*** Start Custom Code privatealbum item
//                                '*** End Custom Code
  // constructor
  AopAlbumItem({required Map<String, dynamic> data}) : super(data: data) {
    fromMap(data);
//                                '*** Start Custom Code album item.create
//                                '*** End Custom Code
  } // of constructor

//Associations
  Future<AopAlbum> get album async => albumProvider.get(_albumId);
  int? get albumId => _albumId;
  set albumId(int? newId) {
    _albumId = newId;
  } // of albumId

  Future<AopSnap> get snap async => snapProvider.get(_snapId);
  int? get snapId => _snapId;
  set snapId(int? newId) {
    _snapId = newId;
  } // of snapId

//maker function for the provider
  static AopAlbumItem maker() {
    return AopAlbumItem(data: {});
  }

// To/From Map for persistence
  @override
  void fromMap(Map<String, dynamic> map) {
    if (map.isEmpty) return;
    id = map['id'];
    createdOn = fromDbDate(map['created_on']);
    updatedOn = fromDbDate(map['updated_on']);
    updatedUser = map['updated_user'];
    _albumId = map['album_id'];
    _snapId = map['snap_id'];
  } // fromMap

  @override
  Map<String, dynamic> toMap() {
    Map<String, dynamic> result = {};
    result['id'] = id;
    result['created_on'] = dbDate(createdOn);
    result['updated_on'] = dbDate(updatedOn);
    result['updated_user'] = updatedUser;
    result['album_id'] = _albumId;
    result['snap_id'] = _snapId;
    return result;
  } // fromMap

  @override
  void fromRow(dynamic row) {
    String fld = 'unassigned';
    super.fromRow(row);
    try {
      fld = '_albumId';
      _albumId = row[4];
      fld = '_snapId';
      _snapId = row[5];
    } catch (ex) {
      throw Exception('Failed to assign field $fld : $ex');
    }
  } // from Row

  @override
  List<dynamic> toRow({bool insert = false}) {
    var result = [];
    if (insert) result = super.toRow();
    result.add(_albumId);
    result.add(_snapId);
    return result;
  } // to Row

  @override
  Future<int?> save({bool validate = true}) async {
    if (validate) await this.validate();
    if (isValid) {
      return await albumItemProvider.save(this);
    } else {
      throw Exception("Failed to save\n${lastErrors.join('\n')}");
    }
  } // of save

  @override
  Future<bool> delete() async {
    return await albumItemProvider.delete(this);
  } // of delete

//                                '*** Start Custom Code album item custom procedures
//                                '*** End Custom Code
} // of class album Item

//-------------------------------------------------------------------
//----------------Session--------------------------------------
//-------------------------------------------------------------------
class AopSession extends DomainObject {
  DateTime? startDate;
  DateTime? endDate;
  String? source;
  int? _userId;

//                                '*** Start Custom Code privatesession
//                                '*** End Custom Code
  // constructor
  AopSession({required Map<String, dynamic> data}) : super(data: data) {
    fromMap(data);
//                                '*** Start Custom Code session.create
//                                '*** End Custom Code
  } // of constructor

//Associations
  Future<List<AopSnap>> get snaps async =>
      snapProvider.getWithFKey('session_id', id);
  Future<AopUser> get user async => userProvider.get(_userId);
  int? get userId => _userId;
  set userId(int? newId) {
    _userId = newId;
  } // of userId

//maker function for the provider
  static AopSession maker() {
    return AopSession(data: {});
  }

// To/From Map for persistence
  @override
  void fromMap(Map<String, dynamic> map) {
    if (map.isEmpty) return;
    id = map['id'];
    createdOn = fromDbDate(map['created_on']);
    updatedOn = fromDbDate(map['updated_on']);
    updatedUser = map['updated_user'];
    startDate = fromDbDate(map['start_date']);
    endDate = fromDbDate(map['end_date']);
    source = map['source'];
    _userId = map['user_id'];
  } // fromMap

  @override
  Map<String, dynamic> toMap() {
    Map<String, dynamic> result = {};
    result['id'] = id;
    result['created_on'] = dbDate(createdOn);
    result['updated_on'] = dbDate(updatedOn);
    result['updated_user'] = updatedUser;
    result['start_date'] = dbDate(startDate);
    result['end_date'] = dbDate(endDate);
    result['source'] = source;
    result['user_id'] = _userId;
    return result;
  } // fromMap

  @override
  void fromRow(dynamic row) {
    String fld = 'unassigned';
    super.fromRow(row);
    try {
      fld = 'startDate';
      startDate = row[4];
      fld = 'endDate';
      endDate = row[5];
      fld = 'source';
      source = row[6];
      fld = '_userId';
      _userId = row[7];
    } catch (ex) {
      throw Exception('Failed to assign field $fld : $ex');
    }
  } // from Row

  @override
  List<dynamic> toRow({bool insert = false}) {
    var result = [];
    if (insert) result = super.toRow();
    result.add(dbDate(startDate!));
    result.add(dbDate(endDate!));
    result.add(source);
    result.add(_userId);
    return result;
  } // to Row

  @override
  Future<int?> save({bool validate = true}) async {
    if (validate) await this.validate();
    if (isValid) {
      return await sessionProvider.save(this);
    } else {
      throw Exception("Failed to save\n${lastErrors.join('\n')}");
    }
  } // of save

  @override
  Future<bool> delete() async {
    return await sessionProvider.delete(this);
  } // of delete

//                                '*** Start Custom Code session custom procedures
  static Future<AopSession> createSession(
      // NOT USED
      String username,
      String password,
      String source) async {
    try {
      var login = await sessionProvider
          .rawRequest('/sessioncreate/{username}/{password}/{source}');
      AopSession session = AopSession(data: login);
      return session;
    } catch (ex) {
      log.error('Failed to create session : $ex');
      rethrow;
    }
  } // of create session
//                                '*** End Custom Code
} // of class session

//-------------------------------------------------------------------
//----------------Snap--------------------------------------
//-------------------------------------------------------------------
class AopSnap extends DomainObject {
  String? fileName;
  String? directory;
  DateTime? takenDate;
  DateTime? originalTakenDate;
  DateTime? modifiedDate;
  String? deviceName;
  String? caption;
  int? ranking;
  double? longitude;
  double? latitude;
  int? width;
  int? height;
  String? location;
  String? rotation;
  int degrees = 0;
  String? importSource;
  String? mediaType;
  DateTime? importedDate;
  int? mediaLength;
  String? tagList;
  String? metadata;
  int? _sessionId;
  int? _userId;

//                                '*** Start Custom Code privatesnap
//                                '*** End Custom Code
  // constructor
  AopSnap({required Map<String, dynamic> data}) : super(data: data) {
    fromMap(data);
//                                '*** Start Custom Code snap.create
    ranking ??= 2;
    mediaType ??= 'jpg';
    caption ??= '';
    deviceName ??= '';
    rotation ??= '0';
    tagList ??= '';
//                                '*** End Custom Code
  } // of constructor

//Associations
  Future<List<AopAlbumItem>> get albumItems async =>
      albumItemProvider.getWithFKey('snap_id', id);
  Future<AopSession> get session async => sessionProvider.get(_sessionId);
  int? get sessionId => _sessionId;
  set sessionId(int? newId) {
    _sessionId = newId;
  } // of sessionId

  Future<AopUser> get user async => userProvider.get(_userId);
  int? get userId => _userId;
  set userId(int? newId) {
    _userId = newId;
  } // of userId

//maker function for the provider
  static AopSnap maker() {
    return AopSnap(data: {});
  }

// To/From Map for persistence
  @override
  void fromMap(Map<String, dynamic> map) {
    if (map.isEmpty) return;
    id = map['id'];
    createdOn = fromDbDate(map['created_on']);
    updatedOn = fromDbDate(map['updated_on']);
    updatedUser = map['updated_user'];
    fileName = map['file_name'];
    directory = map['directory'];
    takenDate = fromDbDate(map['taken_date']);
    originalTakenDate = fromDbDate(map['original_taken_date']);
    modifiedDate = fromDbDate(map['modified_date']);
    deviceName = map['device_name'];
    caption = map['caption'];
    ranking = map['ranking'];
    longitude = map['longitude'];
    latitude = map['latitude'];
    width = map['width'];
    height = map['height'];
    location = map['location'];
    rotation = map['rotation'];
    degrees = map['degrees'];
    importSource = map['import_source'];
    mediaType = map['media_type'];
    importedDate = fromDbDate(map['imported_date']);
    mediaLength = map['media_length'];
    tagList = map['tag_list'];
    metadata = map['metadata'];
    _sessionId = map['session_id'];
    _userId = map['user_id'];
  } // fromMap

  @override
  Map<String, dynamic> toMap() {
    Map<String, dynamic> result = {};
    result['id'] = id;
    result['created_on'] = dbDate(createdOn);
    result['updated_on'] = dbDate(updatedOn);
    result['updated_user'] = updatedUser;
    result['file_name'] = fileName;
    result['directory'] = directory;
    result['taken_date'] = dbDate(takenDate);
    result['original_taken_date'] = dbDate(originalTakenDate);
    result['modified_date'] = dbDate(modifiedDate);
    result['device_name'] = deviceName;
    result['caption'] = caption;
    result['ranking'] = ranking;
    result['longitude'] = longitude;
    result['latitude'] = latitude;
    result['width'] = width;
    result['height'] = height;
    result['location'] = location;
    result['rotation'] = rotation;
    result['degrees'] = degrees;
    result['import_source'] = importSource;
    result['media_type'] = mediaType;
    result['imported_date'] = dbDate(importedDate);
    result['media_length'] = mediaLength;
    result['tag_list'] = tagList;
    result['metadata'] = metadata;
    result['session_id'] = _sessionId;
    result['user_id'] = _userId;
    return result;
  } // fromMap

  @override
  void fromRow(dynamic row) {
    String fld = 'unassigned';
    super.fromRow(row);
    try {
      fld = 'fileName';
      fileName = row[4];
      fld = 'directory';
      directory = row[5];
      fld = 'takenDate';
      takenDate = row[6];
      fld = 'originalTakenDate';
      originalTakenDate = row[7];
      fld = 'modifiedDate';
      modifiedDate = row[8];
      fld = 'deviceName';
      deviceName = row[9];
      fld = 'caption';
      caption = row[10];
      fld = 'ranking';
      ranking = row[11];
      fld = 'longitude';
      longitude = row[12];
      fld = 'latitude';
      latitude = row[13];
      fld = 'width';
      width = row[14];
      fld = 'height';
      height = row[15];
      fld = 'location';
      location = row[16];
      fld = 'rotation';
      rotation = row[17];
      fld = 'degrees';
      degrees = int.parse(row[18]);
      fld = 'importSource';
      importSource = row[19];
      fld = 'mediaType';
      mediaType = row[20];
      fld = 'importedDate';
      importedDate = row[21];
      fld = 'mediaLength';
      mediaLength = row[22];
      fld = 'tagList';
      tagList = row[23];
      fld = 'metadata';
      metadata = row[24];
      fld = '_sessionId';
      _sessionId = row[25];
      fld = '_userId';
      _userId = row[26];
    } catch (ex) {
      throw Exception('Failed to assign field $fld : $ex');
    }
  } // from Row

  @override
  List<dynamic> toRow({bool insert = false}) {
    var result = [];
    if (insert) result = super.toRow();
    result.add(fileName);
    result.add(directory);
    result.add(dbDate(takenDate!));
    result.add(dbDate(originalTakenDate!));
    result.add(dbDate(modifiedDate!));
    result.add(deviceName);
    result.add(caption);
    result.add(ranking);
    result.add(longitude);
    result.add(latitude);
    result.add(width);
    result.add(height);
    result.add(location);
    result.add(rotation);
    result.add(degrees);
    result.add(importSource);
    result.add(mediaType);
    result.add(dbDate(importedDate!));
    result.add(mediaLength);
    result.add(tagList);
    result.add(metadata);
    result.add(_sessionId);
    result.add(_userId);
    return result;
  } // to Row

  @override
  Future<int?> save({bool validate = true}) async {
    if (validate) await this.validate();
    if (isValid) {
      return await snapProvider.save(this);
    } else {
      throw Exception("Failed to save\n${lastErrors.join('\n')}");
    }
  } // of save

  @override
  Future<bool> delete() async {
    return await snapProvider.delete(this);
  } // of delete

//                                '*** Start Custom Code snap custom procedures

  static Future<bool?> nameExists(String apath, int fileSize) async {
    String fileName = path.basename(apath);
    var r = await snapProvider.rawExecute(
        'select count(*) from aopsnaps ' 'where file_name=? and media_Length=?',
        [fileName, fileSize]);
    var values = r.first.values;
    return values[0] > 0;
  } // of nameExists

  Future<bool?> nameClashButDifferentSize() async {
    var r = await snapProvider.rawExecute(
        'select count(*) from aopsnaps '
        'where directory=? and file_name=? and media_Length<>?',
        [directory, fileName, mediaLength]);
    var values = r.first.values;
    return values[0] > 0;
  } // of nameClashButDifferentSize

  static Future<bool?> dateTimeExists(DateTime taken, int? fileSize) async {
    DateTime startTime = taken.add(Duration(seconds: -2));
    DateTime endTime = taken.add(Duration(seconds: 2));
    var r = await snapProvider.rawExecute(
        'select count(*) from aopsnaps '
        "where (original_taken_date between ? and ?) and media_Length=?",
        [
          (formatDate(startTime, format: 'yyyy-mm-dd hh:nn:ss')),
          (formatDate(endTime, format: 'yyyy-mm-dd hh:nn:ss')),
          fileSize
        ]);
    var values = r.first.values;
    return values[0] > 0;
  } // of dateTimeExists

  static Future<bool?> nameSameDayExists(
      DateTime taken, String filename) async {
    String startTime = formatDate(taken.add(Duration(hours: -24)),
        format: 'yyyy-mm-dd hh:nn:ss');
    String endTime = formatDate(taken.add(Duration(hours: 24)),
        format: 'yyyy-mm-dd hh:nn:ss');
    // var r = await snapProvider.rawExecute(
    //     'select count(*) from aopsnaps '
    //     "where (original_taken_date between ? and ?) and file_name=?",
    //     [
    //       (formatDate(startTime, format: 'yyyy-mm-dd hh:nn:ss')),
    //       (formatDate(endTime, format: 'yyyy-mm-dd hh:nn:ss')),
    //       filename
    //     ]);
    // var values = r.first.values;
    // return values[0] > 0;
    var r = await snapProvider.rawRequest(
        'find/nameExists?start=$startTime&end=$endTime&filename=$filename');
    int count = r[0][0];
    return count > 0;
  } // of dateTimeExists

  static Future<bool?> sizeOrNameOrDeviceAtTimeExists(
      //ignore device
      DateTime taken,
      int fileSize,
      String filename,
      String deviceName) async {
    DateTime startTime = taken.add(Duration(milliseconds: -500));
    DateTime endTime = taken.add(Duration(milliseconds: 500));
    var r = await snapProvider.rawExecute(
        'select count(*) from aopsnaps '
        "where (original_taken_date between ? and ? or modified_date between ? and ?) "
//            "and (media_Length=? or file_name=? or device_name=?)",
        "and (media_Length=? or file_name=?)",
        [
          (formatDate(startTime, format: 'yyyy-mm-dd hh:nn:ss')),
          (formatDate(endTime, format: 'yyyy-mm-dd hh:nn:ss')),
          (formatDate(startTime, format: 'yyyy-mm-dd hh:nn:ss')),
          (formatDate(endTime, format: 'yyyy-mm-dd hh:nn:ss')),
          fileSize,
          filename,
//          deviceName
        ]);
    var values = r.first.values;
    return values[0] > 0;
  } // of sizeOrNameAtTimeExists

  static Future<dynamic> get existingLocations async {
    var r = await snapProvider.rawExecute(
        'select location,avg(longitude) as lng, avg(latitude) as lon from aopsnaps where latitude is not null and location is not null group by 1');
    return r;
  } // of existingLocations

  static Future<List<String>> get distinctLocations async {
    var r = await snapProvider.rawRequest('find/locations');
    //    'select distinct location from aopsnaps where location is not null');
    List<String> result = [];
    for (var row in r) {
      result.add(row[0] as String);
    }
    return result;
  } // of existingLocations

  static Future<dynamic> get monthGrid async {
    var r = await snapProvider.rawRequest('find/monthgrid');
    return r;
  } // of monthgrid

  static Future<int> getPreviousCropCount(String source) async {
    source = source.replaceAll('+', '%2B');
    var r = await snapProvider.rawRequest('find/cropCount?source=$source');
    return r[0][0];
  } // of yearGrid

  String get fullSizeURL {
    if (degrees == 0) {
      return '${WebFile.rootUrl}photos/$directory/$fileName';
    } else {
      return '${WebFile.rootUrl}rotate/$degrees/$directory/$fileName';
    }
  } // of fullSizeURL

  String get thumbnailURL {
    // thumbnail is always jpeg
    String thumbName = fileName ?? 'noname';
    if (!thumbName.toLowerCase().endsWith('.jpg')) {
      thumbName = path.setExtension(fileName!, '.jpg');
    }
    if (degrees == 0) {
      return '${WebFile.rootUrl}photos/$directory/thumbnails/$thumbName';
    } else {
      return '${WebFile.rootUrl}rotate/$degrees/$directory/thumbnails/$thumbName';
    }
//    return '${WebFile.rootUrl}rotate/$degrees/$directory/thumbnails/$thumbName';
  } // of thumbnailURL

  String get metadataURL {
    return '${WebFile.rootUrl}photos/$directory/metadata/$fileName.json';
  } // of metadataURL

  static Future<AopSnap> snapCropper(int id, int l, int t, int r, int b) async {
    String url = 'crop/$id/$l/$t/$r/$b';
    var resp = await snapProvider.rawRequest(url);
    return AopSnap(data: resp);
  } // of yearGrid

  void trimSetLocation(String? newLocation) {
    if (newLocation != null && newLocation.length > 200) {
      newLocation = newLocation.substring(newLocation.length - 200);
    }
    location = newLocation;
  } // of trimSetLocation

  double get angle => (degrees) * math.pi / 180; // radians

  void rotate(int direction) {
    int newRotation = angle.round() + direction;
    newRotation = newRotation % 360; // wrap 360
    rotation = 'dead';
  }

  bool get isVideo => mediaType == 'mp4' || mediaType == 'mov';

  //                                '*** End Custom Code
} // of class snap

//-------------------------------------------------------------------
//----------------User--------------------------------------
//-------------------------------------------------------------------
class AopUser extends DomainObject {
  late String name;
  String? _hint;

//                                '*** Start Custom Code privateuser
//                                '*** End Custom Code
  // constructor
  AopUser({required Map<String, dynamic> data}) : super(data: data) {
    fromMap(data);
//                                '*** Start Custom Code user.create
    name = 'blah';
//                                '*** End Custom Code
  } // of constructor

  String? get hint {
//                                '*** Start Custom Code user.gethint
//                                '*** End Custom Code
    return _hint;
  } // of get hint

  set hint(String? thishint) {
//                                '*** Start Custom Code user.sethint
//                                '*** End Custom Code
    _hint = thishint;
  } //  of set hint

//Associations
  Future<List<AopAlbum>> get albums async =>
      albumProvider.getWithFKey('user_id', id);
  Future<List<AopSession>> get sessions async =>
      sessionProvider.getWithFKey('user_id', id);
  Future<List<AopSnap>> get snaps async =>
      snapProvider.getWithFKey('user_id', id);

//maker function for the provider
  static AopUser maker() {
    return AopUser(data: {});
  }

// To/From Map for persistence
  @override
  void fromMap(Map<String, dynamic> map) {
    if (map.isEmpty) return;
    id = map['id'];
    createdOn = fromDbDate(map['created_on']);
    updatedOn = fromDbDate(map['updated_on']);
    updatedUser = map['updated_user'];
    name = map['name'];
    hint = map['hint'];
  } // fromMap

  @override
  Map<String, dynamic> toMap() {
    Map<String, dynamic> result = {};
    result['id'] = id;
    result['created_on'] = dbDate(createdOn);
    result['updated_on'] = dbDate(updatedOn);
    result['updated_user'] = updatedUser;
    result['name'] = name;
    result['hint'] = hint;
    return result;
  } // fromMap

  @override
  void fromRow(dynamic row) {
    String fld = 'unassigned';
    super.fromRow(row);
    try {
      fld = 'name';
      name = row[4];
      fld = 'hint';
      hint = row[5];
    } catch (ex) {
      throw Exception('Failed to assign field $fld : $ex');
    }
  } // from Row

  @override
  List<dynamic> toRow({bool insert = false}) {
    var result = [];
    if (insert) result = super.toRow();
    result.add(name);
    result.add(hint);
    return result;
  } // to Row

  @override
  Future<int?> save({bool validate = true}) async {
    if (validate) await this.validate();
    if (isValid) {
      return await userProvider.save(this);
    } else {
      throw Exception("Failed to save\n${lastErrors.join('\n')}");
    }
  } // of save

  @override
  Future<bool> delete() async {
    return await userProvider.delete(this);
  } // of delete

//                                '*** Start Custom Code user custom procedures
//                                '*** End Custom Code
} // of class user

//-------------------------------------------------------------------
//Custom Procedures
//                                '*** Start Custom Code customprocedures

//                                '*** End Custom Code

//initialization
//                                '*** Start Custom Code initialization
void init() {} // of customIncd it
//                                '*** End Custom Code

//finalization
//                                '*** Start Custom Code finalization
//                                '*** End Custom Code

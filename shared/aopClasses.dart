//
//  Model classes for All Our Photos generated by dartBO.txt on 31-May-2019 11:20:26 by chris
//
import 'dart:async';
import 'DomainObject.dart';

//                                '*** Start Custom Code imports
//import 'package:image/image.dart';
import 'package:path/path.dart' as Path;
//                                '*** End Custom Code

// Domain object providers
var albumProvider = DOProvider<AopAlbum>(
    "aopalbums",
    [
      "name",
      "description",
      "first_date",
      "last_date",
      "user_id",
    ],
    AopAlbum.maker);
var albumItemProvider = DOProvider<AopAlbumItem>(
    "aopalbum_items",
    [
      "album_id",
      "snap_id",
    ],
    AopAlbumItem.maker);
var sessionProvider = DOProvider<AopSession>(
    "aopsessions",
    [
      "start_date",
      "end_date",
      "source",
      "user_id",
    ],
    AopSession.maker);
var snapProvider = DOProvider<AopSnap>(
    "aopsnaps",
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
      "import_source",
      "media_type",
      "imported_date",
      "media_length",
      "tag_list",
      "session_id",
      "user_id",
    ],
    AopSnap.maker);
var userProvider = DOProvider<AopUser>(
    "aopusers",
    [
      "name",
      "hint",
    ],
    AopUser.maker);

//-------------------------------------------------------------------
//----------------Album--------------------------------------
//-------------------------------------------------------------------
class AopAlbum extends DomainObject {
  String name;
  String description;
  DateTime firstDate;
  DateTime lastDate;
  int _userId;

//                                '*** Start Custom Code privatealbum
//                                '*** End Custom Code
  // constructor
  AopAlbum({Map<String, dynamic> data}) : super(data: data) {
    if (data != null) fromMap(data);
//                                '*** Start Custom Code album.create
//                                '*** End Custom Code
  } // of constructor

//Associations
  Future<List<AopAlbumItem>> get albumItems async =>
      albumItemProvider.getWithFKey('album_id', this.id);

  Future<AopUser> get user async => userProvider.get(_userId);

  int get userId => this._userId;

  set userId(int newId) {
    this._userId = newId;
  } // of userId

//maker function for the provider
  static AopAlbum maker() {
    return AopAlbum();
  }

// To/From Map for persistence
  void fromMap(Map<String, dynamic> map) {
    this.id = map['id'];
    this.createdOn = map['created_on'];
    this.updatedOn = map['updated_on'];
    this.updatedUser = map['updated_user'];
    this.name = map['name'];
    this.description = map['description'];
    this.firstDate = map['firstDate'];
    this.lastDate = map['lastDate'];
    this._userId = map['userid'];
  } // fromMap

  Map<String, dynamic> toMap() {
    Map<String, dynamic> result = {};
    result['id'] = this.id;
    result['created_on'] = this.createdOn;
    result['updated_on'] = this.updatedOn;
    result['updated_user'] = this.updatedUser;
    result['name'] = this.name;
    result['description'] = this.description;
    result['first_date'] = this.firstDate;
    result['last_date'] = this.lastDate;
    result['userid'] = this._userId;
    return result;
  } // fromMap

  void fromRow(dynamic row) {
    String fld;
    super.fromRow(row);
    try {
      fld = 'name';
      this.name = row[4];
      fld = 'description';
      this.description = row[5];
      fld = 'firstDate';
      this.firstDate = row[6]?.toLocal();
      fld = 'lastDate';
      this.lastDate = row[7]?.toLocal();
      fld = '_userId';
      this._userId = row[8];
    } catch (ex) {
      throw Exception('Failed to assign field $fld : ' + ex.toString());
    }
  } // from Row

  List<dynamic> toRow({bool insert = false}) {
    var result = [];
    if (insert) result = super.toRow();
    result.add(name);
    result.add(description);
    result.add(firstDate?.toIso8601String());
    result.add(lastDate?.toIso8601String());
    result.add(_userId);
    return result;
  } // to Row

  @override
  Future<int> save({bool validate: true}) async {
    if (validate) await this.validate();
    if (isValid) {
      return await albumProvider.save(this);
    } else {
      throw Exception("Failed to save");
    }
  } // of save

  Future<bool> delete() async {
    return albumProvider.delete(this);
  } // of delete

//                                '*** Start Custom Code album custom procedures
  static Future<List<AopAlbum>> all() async {
    return albumProvider.getSome('1=1',orderBy:'name');
  } // all Albums

  Future<List<AopSnap>> get snaps async {
    return snapProvider.getSome(
        'id in (select snap_id from aopalbum_items where album_id=${this.id})');
  } //  snaps property

  Future<int> addSnaps(List<int> newSnapIds) async {
    int result = 0;
    List<AopAlbumItem> existingItems = await this.albumItems;
    for (int newId in newSnapIds) {
      bool found = false;
      for (AopAlbumItem item in existingItems)
        if (item.snapId == newId)
          found = true;
        if (!found) {
          AopAlbumItem newItem = AopAlbumItem();
          newItem.albumId = this.id;
          newItem.snapId = newId;
          await newItem.save();
          existingItems.add(newItem);
          result += 1;
        } // inserted newone
    }
    return result;
  } // of addSnaps

  Future<int> removeSnaps(List<int> oldSnapIds) async {
    int result = 0;
    List<AopAlbumItem> existingItems = await this.albumItems;
    for (AopAlbumItem thisItem in existingItems) {
      if (oldSnapIds.indexOf(thisItem.snapId)>=0) {
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
    String yearStr = name.substring(0, 4);
    int yearNo = int.tryParse(yearStr) ?? -1;
    if (yearNo < 1900 || yearNo > 2099)
      lastErrors.add('name should start with 4 digit year');
  } // of validate

//                                '*** End Custom Code
} // of class album

//-------------------------------------------------------------------
//----------------Album Item--------------------------------------
//-------------------------------------------------------------------
class AopAlbumItem extends DomainObject {
  int _albumId;
  int _snapId;

//                                '*** Start Custom Code privatealbum item
//                                '*** End Custom Code
  // constructor
  AopAlbumItem({Map<String, dynamic> data}) : super(data: data) {
    if (data != null) fromMap(data);
//                                '*** Start Custom Code album item.create
//                                '*** End Custom Code
  } // of constructor

//Associations
  Future<AopAlbum> get album async => albumProvider.get(_albumId);

  int get albumId => this._albumId;

  set albumId(int newId) {
    this._albumId = newId;
  } // of albumId

  Future<AopSnap> get snap async => snapProvider.get(_snapId);

  int get snapId => this._snapId;

  set snapId(int newId) {
    this._snapId = newId;
  } // of snapId

//maker function for the provider
  static AopAlbumItem maker() {
    return AopAlbumItem();
  }

// To/From Map for persistence
  void fromMap(Map<String, dynamic> map) {
    this.id = map['id'];
    this.createdOn = map['created_on'];
    this.updatedOn = map['updated_on'];
    this.updatedUser = map['updated_user'];
    this._albumId = map['albumid'];
    this._snapId = map['snapid'];
  } // fromMap

  Map<String, dynamic> toMap() {
    Map<String, dynamic> result = {};
    result['id'] = this.id;
    result['created_on'] = this.createdOn;
    result['updated_on'] = this.updatedOn;
    result['updated_user'] = this.updatedUser;
    result['albumid'] = this._albumId;
    result['snapid'] = this._snapId;
    return result;
  } // fromMap

  void fromRow(dynamic row) {
    String fld;
    super.fromRow(row);
    try {
      fld = '_albumId';
      this._albumId = row[4];
      fld = '_snapId';
      this._snapId = row[5];
    } catch (ex) {
      throw Exception('Failed to assign field $fld : ' + ex.toString());
    }
  } // from Row

  List<dynamic> toRow({bool insert = false}) {
    var result = [];
    if (insert) result = super.toRow();
    result.add(_albumId);
    result.add(_snapId);
    return result;
  } // to Row

  @override
  Future<int> save({bool validate: true}) async {
    if (validate) await this.validate();
    if (isValid) {
      return await albumItemProvider.save(this);
    } else {
      throw Exception("Failed to save");
    }
  } // of save

  Future<void> delete() async {
    return albumItemProvider.delete(this);
  } // of delete

//                                '*** Start Custom Code album item custom procedures
//                                '*** End Custom Code
} // of class album Item

//-------------------------------------------------------------------
//----------------Session--------------------------------------
//-------------------------------------------------------------------
class AopSession extends DomainObject {
  DateTime startDate;
  DateTime endDate;
  String source;
  int _userId;

//                                '*** Start Custom Code privatesession
//                                '*** End Custom Code
  // constructor
  AopSession({Map<String, dynamic> data}) : super(data: data) {
    if (data != null) fromMap(data);
//                                '*** Start Custom Code session.create
//                                '*** End Custom Code
  } // of constructor

//Associations
  Future<List<AopSnap>> get snaps async =>
      snapProvider.getWithFKey('session_id', this.id);

  Future<AopUser> get user async => userProvider.get(_userId);

  int get userId => this._userId;

  set userId(int newId) {
    this._userId = newId;
  } // of userId

//maker function for the provider
  static AopSession maker() {
    return AopSession();
  }

// To/From Map for persistence
  void fromMap(Map<String, dynamic> map) {
    this.id = map['id'];
    this.createdOn = map['created_on'];
    this.updatedOn = map['updated_on'];
    this.updatedUser = map['updated_user'];
    this.startDate = map['startDate'];
    this.endDate = map['endDate'];
    this.source = map['source'];
    this._userId = map['userid'];
  } // fromMap

  Map<String, dynamic> toMap() {
    Map<String, dynamic> result = {};
    result['id'] = this.id;
    result['created_on'] = this.createdOn;
    result['updated_on'] = this.updatedOn;
    result['updated_user'] = this.updatedUser;
    result['start_date'] = this.startDate;
    result['end_date'] = this.endDate;
    result['source'] = this.source;
    result['userid'] = this._userId;
    return result;
  } // fromMap

  void fromRow(dynamic row) {
    String fld;
    super.fromRow(row);
    try {
      fld = 'startDate';
      this.startDate = row[4]?.toLocal();
      fld = 'endDate';
      this.endDate = row[5]?.toLocal();
      fld = 'source';
      this.source = row[6];
      fld = '_userId';
      this._userId = row[7];
    } catch (ex) {
      throw Exception('Failed to assign field $fld : ' + ex.toString());
    }
  } // from Row

  List<dynamic> toRow({bool insert = false}) {
    var result = [];
    if (insert) result = super.toRow();
    result.add(startDate?.toIso8601String());
    result.add(endDate?.toIso8601String());
    result.add(source);
    result.add(_userId);
    return result;
  } // to Row

  @override
  Future<int> save({bool validate: true}) async {
    if (validate) await this.validate();
    if (isValid) {
      return await sessionProvider.save(this);
    } else {
      throw Exception("Failed to save");
    }
  } // of save

  Future<void> delete() async {
    return sessionProvider.delete(this);
  } // of delete

//                                '*** Start Custom Code session custom procedures
//                                '*** End Custom Code
} // of class session

//-------------------------------------------------------------------
//----------------Snap--------------------------------------
//-------------------------------------------------------------------
class AopSnap extends DomainObject {
  String fileName;
  String directory;
  DateTime takenDate;
  DateTime originalTakenDate;
  DateTime modifiedDate;
  String deviceName;
  String caption;
  int ranking;
  double longitude;
  double latitude;
  int width;
  int height;
  String location;
  String rotation;
  String importSource;
  String mediaType;
  DateTime importedDate;
  int mediaLength;
  String tagList;
  int _sessionId;
  int _userId;

//                                '*** Start Custom Code privatesnap
//                                '*** End Custom Code
  // constructor
  AopSnap({Map<String, dynamic> data}) : super(data: data) {
    if (data != null) fromMap(data);
//                                '*** Start Custom Code snap.create
    if (ranking == null) ranking = 2;
    if (mediaType == null) mediaType = 'jpg';
    if (caption == null) caption = '';
    if (deviceName == null) deviceName = '';
    if (rotation == null) rotation = '0';
    if (tagList == null) tagList = '';
//                                '*** End Custom Code
  } // of constructor

//Associations
  Future<List<AopAlbumItem>> get albumItems async =>
      albumItemProvider.getWithFKey('snap_id', this.id);

  Future<AopSession> get session async => sessionProvider.get(_sessionId);

  int get sessionId => this._sessionId;

  set sessionId(int newId) {
    this._sessionId = newId;
  } // of sessionId

  Future<AopUser> get user async => userProvider.get(_userId);

  int get userId => this._userId;

  set userId(int newId) {
    this._userId = newId;
  } // of userId

//maker function for the provider
  static AopSnap maker() {
    return AopSnap();
  }

// To/From Map for persistence
  void fromMap(Map<String, dynamic> map) {
    this.id = map['id'];
    this.createdOn = map['created_on'];
    this.updatedOn = map['updated_on'];
    this.updatedUser = map['updated_user'];
    this.fileName = map['fileName'];
    this.directory = map['directory'];
    this.takenDate = map['takenDate'];
    this.originalTakenDate = map['originalTakenDate'];
    this.modifiedDate = map['modifiedDate'];
    this.deviceName = map['deviceName'];
    this.caption = map['caption'];
    this.ranking = map['ranking'];
    this.longitude = map['longitude'];
    this.latitude = map['latitude'];
    this.width = map['width'];
    this.height = map['height'];
    this.location = map['location'];
    this.rotation = map['rotation'];
    this.importSource = map['importSource'];
    this.mediaType = map['mediaType'];
    this.importedDate = map['importedDate'];
    this.mediaLength = map['mediaLength'];
    this.tagList = map['tagList'];
    this._sessionId = map['sessionid'];
    this._userId = map['userid'];
  } // fromMap

  Map<String, dynamic> toMap() {
    Map<String, dynamic> result = {};
    result['id'] = this.id;
    result['created_on'] = this.createdOn;
    result['updated_on'] = this.updatedOn;
    result['updated_user'] = this.updatedUser;
    result['file_name'] = this.fileName;
    result['directory'] = this.directory;
    result['taken_date'] = this.takenDate;
    result['original_taken_date'] = this.originalTakenDate;
    result['modified_date'] = this.modifiedDate;
    result['device_name'] = this.deviceName;
    result['caption'] = this.caption;
    result['ranking'] = this.ranking;
    result['longitude'] = this.longitude;
    result['latitude'] = this.latitude;
    result['width'] = this.width;
    result['height'] = this.height;
    result['location'] = this.location;
    result['rotation'] = this.rotation;
    result['import_source'] = this.importSource;
    result['media_type'] = this.mediaType;
    result['imported_date'] = this.importedDate;
    result['media_length'] = this.mediaLength;
    result['tag_list'] = this.tagList;
    result['sessionid'] = this._sessionId;
    result['userid'] = this._userId;
    return result;
  } // fromMap

  void fromRow(dynamic row) {
    String fld;
    super.fromRow(row);
    try {
      fld = 'fileName';
      this.fileName = row[4];
      fld = 'directory';
      this.directory = row[5];
      fld = 'takenDate';
      this.takenDate = row[6]?.toLocal();
      fld = 'originalTakenDate';
      this.originalTakenDate = row[7]?.toLocal();
      fld = 'modifiedDate';
      this.modifiedDate = row[8]?.toLocal();
      fld = 'deviceName';
      this.deviceName = row[9];
      fld = 'caption';
      this.caption = row[10];
      fld = 'ranking';
      this.ranking = row[11];
      fld = 'longitude';
      this.longitude = row[12];
      fld = 'latitude';
      this.latitude = row[13];
      fld = 'width';
      this.width = row[14];
      fld = 'height';
      this.height = row[15];
      fld = 'location';
      this.location = row[16];
      fld = 'rotation';
      this.rotation = row[17];
      fld = 'importSource';
      this.importSource = row[18];
      fld = 'mediaType';
      this.mediaType = row[19];
      fld = 'importedDate';
      this.importedDate = row[20]?.toLocal();
      fld = 'mediaLength';
      this.mediaLength = row[21];
      fld = 'tagList';
      this.tagList = row[22];
      fld = '_sessionId';
      this._sessionId = row[23];
      fld = '_userId';
      this._userId = row[24];
    } catch (ex) {
      throw Exception('Failed to assign field $fld : ' + ex.toString());
    }
  } // from Row

  List<dynamic> toRow({bool insert = false}) {
    var result = [];
    if (insert) result = super.toRow();
    result.add(fileName);
    result.add(directory);
    result.add(takenDate?.toIso8601String());
    result.add(originalTakenDate?.toIso8601String());
    result.add(modifiedDate?.toIso8601String());
    result.add(deviceName);
    result.add(caption);
    result.add(ranking);
    result.add(longitude);
    result.add(latitude);
    result.add(width);
    result.add(height);
    result.add(location);
    result.add(rotation);
    result.add(importSource);
    result.add(mediaType);
    result.add(importedDate?.toIso8601String());
    result.add(mediaLength);
    result.add(tagList);
    result.add(_sessionId);
    result.add(_userId);
    return result;
  } // to Row

  @override
  Future<int> save({bool validate: true}) async {
    if (validate) await this.validate();
    if (isValid) {
      return await snapProvider.save(this);
    } else {
      throw Exception("Failed to save");
    }
  } // of save

  Future<void> delete() async {
    return snapProvider.delete(this);
  } // of delete

//                                '*** Start Custom Code snap custom procedures
  static Future<bool> exists(String path, int fileSize) async {
    String fileName = Path.basename(path);
    var r = await snapProvider.rawExecute(
        'select count(*) from aopsnaps ' +
            'where file_name=? and media_Length=?',
        [fileName, fileSize]);
    var values = r.first.values;
    return values[0] > 0;
  } // of exists

  static Future<dynamic> get existingLocations async {
    var r = await snapProvider.rawExecute('select location,avg(longitude) as lng, '+
        'avg(latitude) as lon from aopsnaps where latitude '+
        'is not null and location is not null group by 1');
    return r;
  } // of existingLocations

  static Future<dynamic> get monthGrid async {
    var r = await snapProvider.rawExecute('select * from vwmonthgrid');
    return r;
  } // of yearGrid

  // todo remove hardwired urls
  String get fullSizeURL {
    return 'http://192.168.1.251:3333/$directory/$fileName';
  } // of fullSizeURL

  String get thumbnailURL {
    return 'http://192.168.1.251:3333/$directory/thumbnails/$fileName';
  } // of thumbnailURL

//                                '*** End Custom Code
} // of class snap

//-------------------------------------------------------------------
//----------------User--------------------------------------
//-------------------------------------------------------------------
class AopUser extends DomainObject {
  String name;
  String _hint;

//                                '*** Start Custom Code privateuser
//                                '*** End Custom Code
  // constructor
  AopUser({Map<String, dynamic> data}) : super(data: data) {
    if (data != null) fromMap(data);
//                                '*** Start Custom Code user.create
//                                '*** End Custom Code
  } // of constructor

  String get hint {
//                                '*** Start Custom Code user.gethint
//                                '*** End Custom Code
    return this._hint;
  } // of get hint

  set hint(String thishint) {
//                                '*** Start Custom Code user.sethint
//                                '*** End Custom Code
    this._hint = thishint;
  } //  of set hint

//Associations
  Future<List<AopAlbum>> get albums async =>
      albumProvider.getWithFKey('user_id', this.id);

  Future<List<AopSession>> get sessions async =>
      sessionProvider.getWithFKey('user_id', this.id);

  Future<List<AopSnap>> get snaps async =>
      snapProvider.getWithFKey('user_id', this.id);

//maker function for the provider
  static AopUser maker() {
    return AopUser();
  }

// To/From Map for persistence
  void fromMap(Map<String, dynamic> map) {
    this.id = map['id'];
    this.createdOn = map['created_on'];
    this.updatedOn = map['updated_on'];
    this.updatedUser = map['updated_user'];
    this.name = map['name'];
    this.hint = map['hint'];
  } // fromMap

  Map<String, dynamic> toMap() {
    Map<String, dynamic> result = {};
    result['id'] = this.id;
    result['created_on'] = this.createdOn;
    result['updated_on'] = this.updatedOn;
    result['updated_user'] = this.updatedUser;
    result['name'] = this.name;
    result['hint'] = this.hint;
    return result;
  } // fromMap

  void fromRow(dynamic row) {
    String fld;
    super.fromRow(row);
    try {
      fld = 'name';
      this.name = row[4];
      fld = 'hint';
      this.hint = row[5];
    } catch (ex) {
      throw Exception('Failed to assign field $fld : ' + ex.toString());
    }
  } // from Row

  List<dynamic> toRow({bool insert = false}) {
    var result = [];
    if (insert) result = super.toRow();
    result.add(name);
    result.add(hint);
    return result;
  } // to Row

  @override
  Future<int> save({bool validate: true}) async {
    if (validate) await this.validate();
    if (isValid) {
      return await userProvider.save(this);
    } else {
      throw Exception("Failed to save");
    }
  } // of save

  Future<void> delete() async {
    return userProvider.delete(this);
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
void init() {} // of customInit
//                                '*** End Custom Code

//finalization
//                                '*** Start Custom Code finalization
//                                '*** End Custom Code

//
//  Model classes for All Our Photos generated by dartBO.txt on 18-Apr-2019 18:25:53 by chris
//
import 'dart:async';
import 'DomainObject.dart';
//                                '*** Start Custom Code imports
//import 'package:image/image.dart';

//                                '*** End Custom Code

// Domain object providers
var albumProvider = DOProvider<AopAlbum>("aopalbums",["name","description","first_date","last_date","user_id",],AopAlbum.maker);
var albumItemProvider = DOProvider<AopAlbumItem>("aopalbum_items",["album_id","snap_id",],AopAlbumItem.maker);
var fullImageProvider = DOProvider<AopFullImage>("aopfull_images",["contents",],AopFullImage.maker);
var sessionProvider = DOProvider<AopSession>("aopsessions",["start_date","end_date","source","user_id",],AopSession.maker);
var snapProvider = DOProvider<AopSnap>("aopsnaps",["file_name","directory","taken_date","modified_date","device_name","caption","ranking","longitude","latitude","location","rotation","import_source","media_type","imported_date","has_thumbnail","tag_list","full_image_id","session_id","source_snap_id","thumbnail_id","user_id",],AopSnap.maker);
var thumbnailProvider = DOProvider<AopThumbnail>("aopthumbnails",["contents",],AopThumbnail.maker);
var userProvider = DOProvider<AopUser>("aopusers",["name","hint",],AopUser.maker);

//-------------------------------------------------------------------
//----------------Album--------------------------------------
//-------------------------------------------------------------------
class AopAlbum extends DomainObject {

  String name;
  String description;
  DateTime firstDate;
  DateTime lastDate;
// todo  List<AopAlbumItem> _albumItems;
  int _userId;

//                                '*** Start Custom Code privatealbum
//                                '*** End Custom Code
  // constructor
  AopAlbum ({Map<String,dynamic> data}) : super(data:data) {
  if (data != null)
    fromMap(data);
//                                '*** Start Custom Code album.create
//                                '*** End Custom Code
  } // of constructor 


//Associations
  Future<List<AopAlbumItem>> get albumItems async => albumItemProvider.getWithFKey('albumID',this.id);
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
void fromMap(Map<String,dynamic> map) {
  this.id = map['id'];
  this.createdOn = map['created_on'];
  this.updatedOn = map['updated_on'];
  this.updatedUser = map['updated_user'];
  this.name = map['name']; 
  this.description = map['description']; 
  this.firstDate = map['firstDate']; 
  this.lastDate = map['lastDate']; 
  this._userId = map['userid'];
}  // fromMap 

Map<String,dynamic> toMap() {
  Map<String,dynamic> result = {};
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
}  // fromMap 

  void fromRow(dynamic row) {
    String fld;
	super.fromRow(row);
    try {
      fld = 'name';
      this.name = row[4];
      fld = 'description';
      this.description = row[5];
      fld = 'firstDate';
      this.firstDate = row[6];
      fld = 'lastDate';
      this.lastDate = row[7];
      fld = '_userId';
      this._userId = row[8]; 
    } catch (ex) {
      throw Exception('Failed to assign field $fld : '+ex.toString());
    }
  }  // from Row

  List<dynamic> toRow({bool insert=false}) {
	var result = [];
	if (insert)
		result = super.toRow();
	result.add(name);
	result.add(description);
	result.add(firstDate);
	result.add(lastDate);
	result.add(_userId);
  return result;
}  // to Row
 @override 
Future<int> save({bool validate:true}) {
  if (validate) this.validate();
  if (isValid) {
    return albumProvider.save(this);
  } else {
	throw Exception("Failed to save");
  } 
} // of save

Future<void> delete() async {
  return albumProvider.delete(this);
} // of delete

//*************************************************************
// Publish Operations
//*************************************************************


//                                '*** Start Custom Code album custom procedures
static AopAlbum fred() {
  return AopAlbum();
}
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
  AopAlbumItem ({Map<String,dynamic> data}) : super(data:data) {
  if (data != null)
    fromMap(data);
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
void fromMap(Map<String,dynamic> map) {
  this.id = map['id'];
  this.createdOn = map['created_on'];
  this.updatedOn = map['updated_on'];
  this.updatedUser = map['updated_user'];
  this._albumId = map['albumid'];
  this._snapId = map['snapid'];
}  // fromMap 

Map<String,dynamic> toMap() {
  Map<String,dynamic> result = {};
  result['id'] = this.id;
  result['created_on'] = this.createdOn;
  result['updated_on'] = this.updatedOn;
  result['updated_user'] = this.updatedUser;
  result['albumid'] = this._albumId;
  result['snapid'] = this._snapId;
  return result;
}  // fromMap 

  void fromRow(dynamic row) {
    String fld;
	super.fromRow(row);
    try {
      fld = '_albumId';
      this._albumId = row[4]; 
      fld = '_snapId';
      this._snapId = row[5]; 
    } catch (ex) {
      throw Exception('Failed to assign field $fld : '+ex.toString());
    }
  }  // from Row

  List<dynamic> toRow({bool insert=false}) {
	var result = [];
	if (insert)
		result = super.toRow();
	result.add(_albumId);
	result.add(_snapId);
  return result;
}  // to Row
 @override 
Future<int> save({bool validate:true}) {
  if (validate) this.validate();
  if (isValid) {
    return albumItemProvider.save(this);
  } else {
	throw Exception("Failed to save");
  } 
} // of save

Future<void> delete() async {
  return albumItemProvider.delete(this);
} // of delete

//*************************************************************
// Publish Operations
//*************************************************************


//                                '*** Start Custom Code album item custom procedures
//                                '*** End Custom Code
} // of class album Item
//-------------------------------------------------------------------
//----------------Full Image--------------------------------------
//-------------------------------------------------------------------
class AopFullImage extends DomainObject {

  List<int> contents;

//                                '*** Start Custom Code privatefull image
//                                '*** End Custom Code
  // constructor
  AopFullImage ({Map<String,dynamic> data}) : super(data:data) {
  if (data != null)
    fromMap(data);
//                                '*** Start Custom Code full image.create
//                                '*** End Custom Code
  } // of constructor 


//Associations

//maker function for the provider
static AopFullImage maker() {
  return AopFullImage();
} 
// To/From Map for persistence
void fromMap(Map<String,dynamic> map) {
  this.id = map['id'];
  this.createdOn = map['created_on'];
  this.updatedOn = map['updated_on'];
  this.updatedUser = map['updated_user'];
  this.contents = map['contents']; 
}  // fromMap 

Map<String,dynamic> toMap() {
  Map<String,dynamic> result = {};
  result['id'] = this.id;
  result['created_on'] = this.createdOn;
  result['updated_on'] = this.updatedOn;
  result['updated_user'] = this.updatedUser;
  result['contents'] = this.contents; 
  return result;
}  // fromMap 

  void fromRow(dynamic row) {
    String fld;
	super.fromRow(row);
    try {
      fld = 'contents';
      this.contents = row[4].toBytes();
    } catch (ex) {
      throw Exception('Failed to assign field $fld : '+ex.toString());
    }
  }  // from Row

  List<dynamic> toRow({bool insert=false}) {
	var result = [];
	if (insert)
		result = super.toRow();
	result.add(contents);
  return result;
}  // to Row
 @override 
Future<int> save({bool validate:true}) {
  if (validate) this.validate();
  if (isValid) {
    return fullImageProvider.save(this);
  } else {
	throw Exception("Failed to save");
  } 
} // of save

Future<void> delete() async {
  await fullImageProvider.delete(this);
} // of delete

//*************************************************************
// Publish Operations
//*************************************************************


//                                '*** Start Custom Code full image custom procedures
//                                '*** End Custom Code
} // of class full Image
//-------------------------------------------------------------------
//----------------Session--------------------------------------
//-------------------------------------------------------------------
class AopSession extends DomainObject {

  DateTime startDate;
  DateTime endDate;
  String source;
// todo  List<AopSnap> _snaps;
  int _userId;

//                                '*** Start Custom Code privatesession
//                                '*** End Custom Code
  // constructor
  AopSession ({Map<String,dynamic> data}) : super(data:data) {
  if (data != null)
    fromMap(data);
//                                '*** Start Custom Code session.create
//                                '*** End Custom Code
  } // of constructor 


//Associations
  Future<List<AopSnap>> get snaps async => snapProvider.getWithFKey('sessionID',this.id);
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
void fromMap(Map<String,dynamic> map) {
  this.id = map['id'];
  this.createdOn = map['created_on'];
  this.updatedOn = map['updated_on'];
  this.updatedUser = map['updated_user'];
  this.startDate = map['startDate']; 
  this.endDate = map['endDate']; 
  this.source = map['source']; 
  this._userId = map['userid'];
}  // fromMap 

Map<String,dynamic> toMap() {
  Map<String,dynamic> result = {};
  result['id'] = this.id;
  result['created_on'] = this.createdOn;
  result['updated_on'] = this.updatedOn;
  result['updated_user'] = this.updatedUser;
  result['start_date'] = this.startDate; 
  result['end_date'] = this.endDate; 
  result['source'] = this.source; 
  result['userid'] = this._userId;
  return result;
}  // fromMap 

  void fromRow(dynamic row) {
    String fld;
	super.fromRow(row);
    try {
      fld = 'startDate';
      this.startDate = row[4];
      fld = 'endDate';
      this.endDate = row[5];
      fld = 'source';
      this.source = row[6];
      fld = '_userId';
      this._userId = row[7]; 
    } catch (ex) {
      throw Exception('Failed to assign field $fld : '+ex.toString());
    }
  }  // from Row

  List<dynamic> toRow({bool insert=false}) {
	var result = [];
	if (insert)
		result = super.toRow();
	result.add(startDate);
	result.add(endDate);
	result.add(source);
	result.add(_userId);
  return result;
}  // to Row
 @override 
Future<int> save({bool validate:true}) {
  if (validate) this.validate();
  if (isValid) {
    return sessionProvider.save(this);
  } else {
	throw Exception("Failed to save");
  } 
} // of save

Future<void> delete() async {
  return sessionProvider.delete(this);
} // of delete

//*************************************************************
// Publish Operations
//*************************************************************


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
  DateTime modifiedDate;
  String deviceName;
  String caption;
  int ranking;
  double longitude;
  double latitude;
  String location;
  String rotation;
  String importSource;
  String mediaType;
  DateTime importedDate;
  bool hasThumbnail;
  String tagList;
// todo  List<AopAlbumItem> _albumItems;
  int _fullImageId;
  int _sessionId;
// todo  List<AopSnap> _snaps;
  int _sourceSnapId;
  int _thumbnailId;
  int _userId;

//                                '*** Start Custom Code privatesnap
//                                '*** End Custom Code
  // constructor
  AopSnap ({Map<String,dynamic> data}) : super(data:data) {
  if (data != null)
    fromMap(data);
//                                '*** Start Custom Code snap.create
  if (ranking==null)
    ranking = 3;
  if (mediaType==null)
    mediaType = 'jpg';
  if (hasThumbnail==null)
    hasThumbnail = false;
//                                '*** End Custom Code
  } // of constructor 


//Associations
  Future<List<AopAlbumItem>> get albumItems async => albumItemProvider.getWithFKey('snapID',this.id);
  Future<AopFullImage> get fullImage async => fullImageProvider.get(_fullImageId);
	int get fullImageId => this._fullImageId;
	set fullImageId(int newId) {
	  this._fullImageId = newId;
	} // of fullImageId
  Future<AopSession> get session async => sessionProvider.get(_sessionId);
	int get sessionId => this._sessionId;
	set sessionId(int newId) {
	  this._sessionId = newId;
	} // of sessionId
  Future<List<AopSnap>> get snaps async => snapProvider.getWithFKey('sourceSnapID',this.id);
  Future<AopSnap> get sourceSnap async => snapProvider.get(_sourceSnapId);
	int get sourceSnapId => this._sourceSnapId;
	set sourceSnapId(int newId) {
	  this._sourceSnapId = newId;
	} // of sourceSnapId
  Future<AopThumbnail> get thumbnail async => thumbnailProvider.get(_thumbnailId);
	int get thumbnailId => this._thumbnailId;
	set thumbnailId(int newId) {
	  this._thumbnailId = newId;
	} // of thumbnailId
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
void fromMap(Map<String,dynamic> map) {
  this.id = map['id'];
  this.createdOn = map['created_on'];
  this.updatedOn = map['updated_on'];
  this.updatedUser = map['updated_user'];
  this.fileName = map['fileName']; 
  this.directory = map['directory']; 
  this.takenDate = map['takenDate']; 
  this.modifiedDate = map['modifiedDate']; 
  this.deviceName = map['deviceName']; 
  this.caption = map['caption']; 
  this.ranking = map['ranking']; 
  this.longitude = map['longitude']; 
  this.latitude = map['latitude']; 
  this.location = map['location']; 
  this.rotation = map['rotation']; 
  this.importSource = map['importSource']; 
  this.mediaType = map['mediaType']; 
  this.importedDate = map['importedDate']; 
  this.hasThumbnail = map['hasThumbnail']; 
  this.tagList = map['tagList']; 
  this._fullImageId = map['full_imageid'];
  this._sessionId = map['sessionid'];
  this._sourceSnapId = map['source_snapid'];
  this._thumbnailId = map['thumbnailid'];
  this._userId = map['userid'];
}  // fromMap 

Map<String,dynamic> toMap() {
  Map<String,dynamic> result = {};
  result['id'] = this.id;
  result['created_on'] = this.createdOn;
  result['updated_on'] = this.updatedOn;
  result['updated_user'] = this.updatedUser;
  result['file_name'] = this.fileName; 
  result['directory'] = this.directory; 
  result['taken_date'] = this.takenDate; 
  result['modified_date'] = this.modifiedDate; 
  result['device_name'] = this.deviceName; 
  result['caption'] = this.caption; 
  result['ranking'] = this.ranking; 
  result['longitude'] = this.longitude; 
  result['latitude'] = this.latitude; 
  result['location'] = this.location; 
  result['rotation'] = this.rotation; 
  result['import_source'] = this.importSource; 
  result['media_type'] = this.mediaType; 
  result['imported_date'] = this.importedDate; 
  result['has_thumbnail'] = this.hasThumbnail; 
  result['tag_list'] = this.tagList; 
  result['fullImageid'] = this._fullImageId;
  result['sessionid'] = this._sessionId;
  result['sourceSnapid'] = this._sourceSnapId;
  result['thumbnailid'] = this._thumbnailId;
  result['userid'] = this._userId;
  return result;
}  // fromMap 

  void fromRow(dynamic row) {
    String fld;
	super.fromRow(row);
    try {
      fld = 'fileName';
      this.fileName = row[4];
      fld = 'directory';
      this.directory = row[5];
      fld = 'takenDate';
      this.takenDate = row[6];
      fld = 'modifiedDate';
      this.modifiedDate = row[7];
      fld = 'deviceName';
      this.deviceName = row[8];
      fld = 'caption';
      this.caption = row[9];
      fld = 'ranking';
      this.ranking = row[10];
      fld = 'longitude';
      this.longitude = row[11];
      fld = 'latitude';
      this.latitude = row[12];
      fld = 'location';
      this.location = row[13];
      fld = 'rotation';
      this.rotation = row[14];
      fld = 'importSource';
      this.importSource = row[15];
      fld = 'mediaType';
      this.mediaType = row[16];
      fld = 'importedDate';
      this.importedDate = row[17];
      fld = 'hasThumbnail';
      this.hasThumbnail = row[18]>0;
      fld = 'tagList';
      this.tagList = row[19];
      fld = '_fullImageId';
      this._fullImageId = row[20]; 
      fld = '_sessionId';
      this._sessionId = row[21]; 
      fld = '_sourceSnapId';
      this._sourceSnapId = row[22]; 
      fld = '_thumbnailId';
      this._thumbnailId = row[23]; 
      fld = '_userId';
      this._userId = row[24]; 
    } catch (ex) {
      throw Exception('Failed to assign field $fld : '+ex.toString());
    }
  }  // from Row

  List<dynamic> toRow({bool insert=false}) {
	var result = [];
	if (insert)
		result = super.toRow();
	result.add(fileName);
	result.add(directory);
	result.add(takenDate);
	result.add(modifiedDate);
	result.add(deviceName);
	result.add(caption);
	result.add(ranking);
	result.add(longitude);
	result.add(latitude);
	result.add(location);
	result.add(rotation);
	result.add(importSource);
	result.add(mediaType);
	result.add(importedDate);
	result.add(hasThumbnail);
	result.add(tagList);
	result.add(_fullImageId);
	result.add(_sessionId);
	result.add(_sourceSnapId);
	result.add(_thumbnailId);
	result.add(_userId);
  return result;
}  // to Row
 @override 
Future<int> save({bool validate:true}) {
  if (validate) this.validate();
  if (isValid) {
    return snapProvider.save(this);
  } else {
	throw Exception("Failed to save");
  } 
} // of save

Future<void> delete() async {
  await snapProvider.delete(this);
} // of delete

//*************************************************************
// Publish Operations
//*************************************************************


//                                '*** Start Custom Code snap custom procedures
//                                '*** End Custom Code
} // of class snap
//-------------------------------------------------------------------
//----------------Thumbnail--------------------------------------
//-------------------------------------------------------------------
class AopThumbnail extends DomainObject {

  List<int> contents;

//                                '*** Start Custom Code privatethumbnail
//                                '*** End Custom Code
  // constructor
  AopThumbnail ({Map<String,dynamic> data}) : super(data:data) {
  if (data != null)
    fromMap(data);
//                                '*** Start Custom Code thumbnail.create
//                                '*** End Custom Code
  } // of constructor 


//Associations

//maker function for the provider
static AopThumbnail maker() {
  return AopThumbnail();
} 
// To/From Map for persistence
void fromMap(Map<String,dynamic> map) {
  this.id = map['id'];
  this.createdOn = map['created_on'];
  this.updatedOn = map['updated_on'];
  this.updatedUser = map['updated_user'];
  this.contents = map['contents']; 
}  // fromMap 

Map<String,dynamic> toMap() {
  Map<String,dynamic> result = {};
  result['id'] = this.id;
  result['created_on'] = this.createdOn;
  result['updated_on'] = this.updatedOn;
  result['updated_user'] = this.updatedUser;
  result['contents'] = this.contents; 
  return result;
}  // fromMap 

  void fromRow(dynamic row) {
    String fld;
	super.fromRow(row);
    try {
      fld = 'contents';
      this.contents = row[4];
    } catch (ex) {
      throw Exception('Failed to assign field $fld : '+ex.toString());
    }
  }  // from Row

  List<dynamic> toRow({bool insert=false}) {
	var result = [];
	if (insert)
		result = super.toRow();
	result.add(contents);
  return result;
}  // to Row
 @override 
Future<int> save({bool validate:true}) {
  if (validate) this.validate();
  if (isValid) {
    return thumbnailProvider.save(this);
  } else {
	throw Exception("Failed to save");
  } 
} // of save

Future<void> delete() async {
  return thumbnailProvider.delete(this);
} // of delete

//*************************************************************
// Publish Operations
//*************************************************************


//                                '*** Start Custom Code thumbnail custom procedures
//                                '*** End Custom Code
} // of class thumbnail
//-------------------------------------------------------------------
//----------------User--------------------------------------
//-------------------------------------------------------------------
class AopUser extends DomainObject {

  String name;
	String  _hint;
// todo  List<AopAlbum> _albums;
// todo  List<AopSession> _sessions;
// todo  List<AopSnap> _snaps;

//                                '*** Start Custom Code privateuser
//                                '*** End Custom Code
  // constructor
  AopUser ({Map<String,dynamic> data}) : super(data:data) {
  if (data != null)
    fromMap(data);
//                                '*** Start Custom Code user.create
//                                '*** End Custom Code
  } // of constructor 


  String get hint  {
//                                '*** Start Custom Code user.gethint
//                                '*** End Custom Code
    return this._hint;
  }  // of get hint

  set hint(String thishint  ) { 
//                                '*** Start Custom Code user.sethint
//                                '*** End Custom Code
  this._hint = thishint;
}  //  of set hint

//Associations
  Future<List<AopAlbum>> get albums async => albumProvider.getWithFKey('userID',this.id);
  Future<List<AopSession>> get sessions async => sessionProvider.getWithFKey('userID',this.id);
  Future<List<AopSnap>> get snaps async => snapProvider.getWithFKey('userID',this.id);

//maker function for the provider
static AopUser maker() {
  return AopUser();
} 
// To/From Map for persistence
void fromMap(Map<String,dynamic> map) {
  this.id = map['id'];
  this.createdOn = map['created_on'];
  this.updatedOn = map['updated_on'];
  this.updatedUser = map['updated_user'];
  this.name = map['name']; 
  this.hint = map['hint']; 
}  // fromMap 

Map<String,dynamic> toMap() {
  Map<String,dynamic> result = {};
  result['id'] = this.id;
  result['created_on'] = this.createdOn;
  result['updated_on'] = this.updatedOn;
  result['updated_user'] = this.updatedUser;
  result['name'] = this.name; 
  result['hint'] = this.hint; 
  return result;
}  // fromMap 

  void fromRow(dynamic row) {
    String fld;
	super.fromRow(row);
    try {
      fld = 'name';
      this.name = row[4];
      fld = 'hint';
      this.hint = row[5];
    } catch (ex) {
      throw Exception('Failed to assign field $fld : '+ex.toString());
    }
  }  // from Row

  List<dynamic> toRow({bool insert=false}) {
	var result = [];
	if (insert)
		result = super.toRow();
	result.add(name);
	result.add(hint);
  return result;
}  // to Row
 @override 
Future<int> save({bool validate:true}) {
  if (validate) this.validate();
  if (isValid) {
    return userProvider.save(this);
  } else {
	throw Exception("Failed to save");
  } 
} // of save

Future<void> delete() async {
  return userProvider.delete(this);
} // of delete

//*************************************************************
// Publish Operations
//*************************************************************


//                                '*** Start Custom Code user custom procedures
//                                '*** End Custom Code
} // of class user

//-------------------------------------------------------------------
//Custom Procedures
//                                '*** Start Custom Code customprocedures
//                                '*** End Custom Code

//initialization
//                                '*** Start Custom Code initialization
//                                '*** End Custom Code

//finalization
//                                '*** Start Custom Code finalization
//                                '*** End Custom Code
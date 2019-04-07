//
//  Model classes for 
//
import 'dart:async';


abstract class BO {
	static String _TABLENAME;
	BO(BO aowner);
	int id;
	DateTime createdOn;
	DateTime updatedOn;
	String updatedUser;
}  // of abstract class BO

//                                '*** Start Custom Code imports
class Media {
// todo  Image _image;
// todo  Video _video;
  Media(dynamic content);

}
//                                '*** End Custom Code


//-------------------------------------------------------------------
//----------------Album--------------------------------------
//-------------------------------------------------------------------
class AopAlbum extends BO {
  List<AopAlbumItem> _albumItems;
  int _userid;

//                                '*** Start Custom Code privatealbum
//                                '*** End Custom Code
  // constructor
  AopAlbum (BO aOwner) : super(aOwner) {
//                                '*** Start Custom Code album.create
//                                '*** End Custom Code
  } // of constructor 

// simple public attributes
  String name;
  String description;
  DateTime firstDate;
  DateTime lastDate;
//-------------------------------------------------------------------

// To/From Map for persistence
static AopAlbum fromMap(BO owner, Map<String,dynamic> map) {
  var result  = AopAlbum(owner); 
  result.id = map['id'];
  result.createdOn = map['createdOn'];
  result.updatedOn = map['updatedOn'];
  result.updatedUser = map['updatedUser'];
  result.name = map['name']; 
  result.description = map['description']; 
  result.firstDate = map['firstDate']; 
  result.lastDate = map['lastDate']; 
  result._userid = map['userid'];
  return result;
}  // fromMap 

Map<String,dynamic> toMap() {
  Map<String,dynamic> result = {};
  result['id'] = this.id;
  result['createdOn'] = this.createdOn;
  result['updatedOn'] = this.updatedOn;
  result['updatedUser'] = this.updatedUser;
  result['name'] = this.name; 
  result['description'] = this.description; 
  result['firstDate'] = this.firstDate; 
  result['lastDate'] = this.lastDate; 
  result['userid'] = this._userid;
  return result;
}  // fromMap 


//*************************************************************
// Publish Operations
//*************************************************************


//                                '*** Start Custom Code album custom procedures
//                                '*** End Custom Code
} // of class album
//-------------------------------------------------------------------
//----------------Album Item--------------------------------------
//-------------------------------------------------------------------
class AopAlbumItem extends BO {
  int _albumid;
  int _snapid;

//                                '*** Start Custom Code privatealbum item
//                                '*** End Custom Code
  // constructor
  AopAlbumItem (BO aOwner) : super(aOwner) {
//                                '*** Start Custom Code album item.create
//                                '*** End Custom Code
  } // of constructor 

// simple public attributes
//-------------------------------------------------------------------

// To/From Map for persistence
static AopAlbumItem fromMap(BO owner, Map<String,dynamic> map) {
  var result  = AopAlbumItem(owner); 
  result.id = map['id'];
  result.createdOn = map['createdOn'];
  result.updatedOn = map['updatedOn'];
  result.updatedUser = map['updatedUser'];
  result._albumid = map['albumid'];
  result._snapid = map['snapid'];
  return result;
}  // fromMap 

Map<String,dynamic> toMap() {
  Map<String,dynamic> result = {};
  result['id'] = this.id;
  result['createdOn'] = this.createdOn;
  result['updatedOn'] = this.updatedOn;
  result['updatedUser'] = this.updatedUser;
  result['albumid'] = this._albumid;
  result['snapid'] = this._snapid;
  return result;
}  // fromMap 


//*************************************************************
// Publish Operations
//*************************************************************


//                                '*** Start Custom Code album item custom procedures
//                                '*** End Custom Code
} // of class album Item
//-------------------------------------------------------------------
//----------------Image--------------------------------------
//-------------------------------------------------------------------
class AopImage extends BO {

//                                '*** Start Custom Code privateimage
//                                '*** End Custom Code
  // constructor
  AopImage (BO aOwner) : super(aOwner) {
//                                '*** Start Custom Code image.create
//                                '*** End Custom Code
  } // of constructor 

// simple public attributes
  Media media;
  Media thumbnail;
//-------------------------------------------------------------------

// To/From Map for persistence
static AopImage fromMap(BO owner, Map<String,dynamic> map) {
  var result  = AopImage(owner); 
  result.id = map['id'];
  result.createdOn = map['createdOn'];
  result.updatedOn = map['updatedOn'];
  result.updatedUser = map['updatedUser'];
  result.media = map['media']; 
  result.thumbnail = map['thumbnail']; 
  return result;
}  // fromMap 

Map<String,dynamic> toMap() {
  Map<String,dynamic> result = {};
  result['id'] = this.id;
  result['createdOn'] = this.createdOn;
  result['updatedOn'] = this.updatedOn;
  result['updatedUser'] = this.updatedUser;
  result['media'] = this.media; 
  result['thumbnail'] = this.thumbnail; 
  return result;
}  // fromMap 


//*************************************************************
// Publish Operations
//*************************************************************


//                                '*** Start Custom Code image custom procedures
//                                '*** End Custom Code
} // of class image
//-------------------------------------------------------------------
//----------------Session--------------------------------------
//-------------------------------------------------------------------
class AopSession extends BO {
  List<AopSnap> _snaps;
  int _userid;

//                                '*** Start Custom Code privatesession
//                                '*** End Custom Code
  // constructor
  AopSession (BO aOwner) : super(aOwner) {
//                                '*** Start Custom Code session.create
//                                '*** End Custom Code
  } // of constructor 

// simple public attributes
  DateTime startDate;
  DateTime endDate;
  String source;
//-------------------------------------------------------------------

// To/From Map for persistence
static AopSession fromMap(BO owner, Map<String,dynamic> map) {
  var result  = AopSession(owner); 
  result.id = map['id'];
  result.createdOn = map['createdOn'];
  result.updatedOn = map['updatedOn'];
  result.updatedUser = map['updatedUser'];
  result.startDate = map['startDate']; 
  result.endDate = map['endDate']; 
  result.source = map['source']; 
  result._userid = map['userid'];
  return result;
}  // fromMap 

Map<String,dynamic> toMap() {
  Map<String,dynamic> result = {};
  result['id'] = this.id;
  result['createdOn'] = this.createdOn;
  result['updatedOn'] = this.updatedOn;
  result['updatedUser'] = this.updatedUser;
  result['startDate'] = this.startDate; 
  result['endDate'] = this.endDate; 
  result['source'] = this.source; 
  result['userid'] = this._userid;
  return result;
}  // fromMap 


//*************************************************************
// Publish Operations
//*************************************************************


//                                '*** Start Custom Code session custom procedures
//                                '*** End Custom Code
} // of class session
//-------------------------------------------------------------------
//----------------Snap--------------------------------------
//-------------------------------------------------------------------
class AopSnap extends BO {
  List<AopAlbumItem> _albumItems;
  int _imageid;
  int _sessionid;
  List<AopSnap> _snaps;
  int _sourceSnapid;
  int _userid;

//                                '*** Start Custom Code privatesnap
//                                '*** End Custom Code
  // constructor
  AopSnap (BO aOwner) : super(aOwner) {
//                                '*** Start Custom Code snap.create
//                                '*** End Custom Code
  } // of constructor 

// simple public attributes
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
//-------------------------------------------------------------------

// To/From Map for persistence
static AopSnap fromMap(BO owner, Map<String,dynamic> map) {
  var result  = AopSnap(owner); 
  result.id = map['id'];
  result.createdOn = map['createdOn'];
  result.updatedOn = map['updatedOn'];
  result.updatedUser = map['updatedUser'];
  result.fileName = map['fileName']; 
  result.directory = map['directory']; 
  result.takenDate = map['takenDate']; 
  result.modifiedDate = map['modifiedDate']; 
  result.deviceName = map['deviceName']; 
  result.caption = map['caption']; 
  result.ranking = map['ranking']; 
  result.longitude = map['longitude']; 
  result.latitude = map['latitude']; 
  result.location = map['location']; 
  result.rotation = map['rotation']; 
  result.importSource = map['importSource']; 
  result.mediaType = map['mediaType']; 
  result.importedDate = map['importedDate']; 
  result.hasThumbnail = map['hasThumbnail']; 
  result.tagList = map['tagList']; 
  result._imageid = map['imageid'];
  result._sessionid = map['sessionid'];
  result._sourceSnapid = map['sourceSnapid'];
  result._userid = map['userid'];
  return result;
}  // fromMap 

Map<String,dynamic> toMap() {
  Map<String,dynamic> result = {};
  result['id'] = this.id;
  result['createdOn'] = this.createdOn;
  result['updatedOn'] = this.updatedOn;
  result['updatedUser'] = this.updatedUser;
  result['fileName'] = this.fileName; 
  result['directory'] = this.directory; 
  result['takenDate'] = this.takenDate; 
  result['modifiedDate'] = this.modifiedDate; 
  result['deviceName'] = this.deviceName; 
  result['caption'] = this.caption; 
  result['ranking'] = this.ranking; 
  result['longitude'] = this.longitude; 
  result['latitude'] = this.latitude; 
  result['location'] = this.location; 
  result['rotation'] = this.rotation; 
  result['importSource'] = this.importSource; 
  result['mediaType'] = this.mediaType; 
  result['importedDate'] = this.importedDate; 
  result['hasThumbnail'] = this.hasThumbnail; 
  result['tagList'] = this.tagList; 
  result['imageid'] = this._imageid;
  result['sessionid'] = this._sessionid;
  result['sourceSnapid'] = this._sourceSnapid;
  result['userid'] = this._userid;
  return result;
}  // fromMap 


//*************************************************************
// Publish Operations
//*************************************************************


//                                '*** Start Custom Code snap custom procedures
//                                '*** End Custom Code
} // of class snap
//-------------------------------------------------------------------
//----------------User--------------------------------------
//-------------------------------------------------------------------
class AopUser extends BO {
  String  _hint;
  List<AopAlbum> _albums;
  List<AopSession> _sessions;
  List<AopSnap> _snaps;

//                                '*** Start Custom Code privateuser
//                                '*** End Custom Code
  // constructor
  AopUser (BO aOwner) : super(aOwner) {
//                                '*** Start Custom Code user.create
//                                '*** End Custom Code
  } // of constructor 

// simple public attributes
  String name;
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

//-------------------------------------------------------------------

// To/From Map for persistence
static AopUser fromMap(BO owner, Map<String,dynamic> map) {
  var result  = AopUser(owner); 
  result.id = map['id'];
  result.createdOn = map['createdOn'];
  result.updatedOn = map['updatedOn'];
  result.updatedUser = map['updatedUser'];
  result.name = map['name']; 
  result.hint = map['hint']; 
  return result;
}  // fromMap 

Map<String,dynamic> toMap() {
  Map<String,dynamic> result = {};
  result['id'] = this.id;
  result['createdOn'] = this.createdOn;
  result['updatedOn'] = this.updatedOn;
  result['updatedUser'] = this.updatedUser;
  result['name'] = this.name; 
  result['hint'] = this.hint; 
  return result;
}  // fromMap 


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

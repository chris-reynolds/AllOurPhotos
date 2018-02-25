//import {PartialExif} from "./jpegHelper";


export class Album {
  id: number;
  updatedDate: Date
  createdDate: Date
  name: string;
  description?: string;
  images:Image[]
  owner : User
}


export enum RotationType {
  None = 0,
  RotateLeft = 90,
  Invert = 180,
  RotateRight = 270
}


export class Image {
  id: number
  updated_on?: Date
  created_on?: Date
  updated_user? : string


  filename: string
  directory: string

  takenDate : Date
  modifiedDate? : Date
  deviceName? : string
  caption? : string
  importSource? : string
  ranking : Number = 0
  height : Number
  width : Number
  longitude? : Number
  latitude? : Number
  hasThumbnail : boolean
  rotation : RotationType
  contentHash : string = 'todo'
  owner? : User
  albums? : Album[]
  derived? :Image[]
  sourceImage? : Image
/*
  loadMetadataFromJpeg(exif:PartialExif) {
    this.takenDate = exif.dateTaken
    this.modifiedDate = null // todo
    this.deviceName = exif.camera
    this.caption = ''
    this.importSource = '' // todo
    this.height = exif.height
    this.width = exif.width
    this.longitude = exif.longitude
    this.latitude = exif.latitude
    this.hasThumbnail = false
    this.rotation = exif.orientation
  }
  */
}

export class User {

  id: number
  updated_on?: Date
  created_on?: Date
  updated_user? : string

  name: string

  albums?: Album[]
  images?: Image[]
} // of User

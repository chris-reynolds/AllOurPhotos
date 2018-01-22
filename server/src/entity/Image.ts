import {Column, Entity, ManyToMany, ManyToOne, OneToMany, PrimaryGeneratedColumn} from "typeorm";
import {Album} from "./Album"
import {User} from "./User"
import {PartialExif} from "../jpegHelper";

export enum RotationType {
  None = 0,
  RotateLeft = 90,
  Invert = 180,
  RotateRight = 270
}

@Entity()
export class Image {
  @PrimaryGeneratedColumn()
  id: number
  @Column({type:'varchar'})   filename: string
  @Column({type:'varchar',length:7})   directory: string

  @Column({type:'datetime'}) takenDate : Date
  @Column({type:'datetime',nullable:true}) modifiedDate? : Date
  @Column({type:'varchar',length:100,nullable:true}) deviceName? : string
  @Column({type:'varchar',length:100,nullable:true}) caption? : string
  @Column({type:'varchar',length:100,nullable:true}) importSource? : string
  @Column({type:'int'}) ranking : Number = 0
  @Column({type:'int'}) height : Number
  @Column({type:'int'}) width : Number
  @Column({type:'float',nullable:true}) longitude? : Number
  @Column({type:'float',nullable:true}) latitude? : Number
  @Column({type:'int',default:0}) hasThumbnail : boolean
  @Column({type:'int',default:0}) rotation : RotationType
  @Column({type:'varchar'}) contentHash : string = 'todo'
  @ManyToOne(type=>User , user => user.albums)
  owner : User
  @ManyToMany(type => Album, album => album.images)
  albums : Album[]
  @ManyToOne(type=>Image, image => image.sourceImage)
  derived :Image[]
  @OneToMany(type=>Image, image => image.derived)
  sourceImage? : Image

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
}

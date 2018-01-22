import {Column, Entity, ManyToMany, ManyToOne, OneToMany, PrimaryGeneratedColumn} from "typeorm";
import {Album} from "./Album"
import {User} from "./User"

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
  @Column()   filename: string
  @Column({length:7})   directory: string

  @Column() takenDate : Date
  @Column() modifiedDate : Date
  @Column({length:100}) deviceName : string
  @Column({length:100}) caption : string
  @Column({length:100}) importSource : string
  @Column({default:0,type:'int'}) ranking : Number
  @Column() longitude : Number
  @Column() latitude : Number
  @Column({default:true}) hasThumbnail : boolean
  @Column() rotation : RotationType
  @Column() contentHash : string
  @ManyToOne(type=>User , user => user.albums)
  owner : User
  @ManyToMany(type => Album, album => album.images)
  albums : Album[]
  @ManyToOne(type=>Image, image => image.sourceImage)
  derived :Image[]
  @OneToMany(type=>Image, image => image.derived)
  sourceImage? : Image
}

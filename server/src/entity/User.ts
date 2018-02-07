import {Entity, PrimaryGeneratedColumn, Column, OneToMany, UpdateDateColumn, CreateDateColumn} from "typeorm";
import {Album} from './Album'
import {Image} from "./Image"

@Entity()
export class User {

    @PrimaryGeneratedColumn()
                id: number
  @Column({type:"timestamp"})
  updatedDate: Date;
  @Column({type:"timestamp"})
  createdDate: Date;

    @Column({type:'varchar',length:50,unique:true})   name: string

//    @OneToMany(type => Album, album => album.owner)
    albums : Album[]
//    @OneToMany(type => Image, image => image.owner)
    images : Image[]
} // of User

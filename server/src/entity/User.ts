import {Entity, PrimaryGeneratedColumn, Column, OneToMany} from "typeorm";
import {Album} from './Album'
import {Image} from "./Image"

@Entity()
export class User {

    @PrimaryGeneratedColumn()
                id: number
    @Column()   name: string

//    @OneToMany(type => Album, album => album.owner)
    albums : Album[]
//    @OneToMany(type => Image, image => image.owner)
    images : Image[]
} // of User

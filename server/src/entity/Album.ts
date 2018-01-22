import {Column, Entity, ManyToMany, ManyToOne, PrimaryGeneratedColumn} from "typeorm";
import {Image} from "./Image";
import {User} from "./User";

@Entity()
export class Album {
  @PrimaryGeneratedColumn()
  id: number;
  @Column({type:'varchar',length:50,unique:true})   name: string;
  @Column({type:'varchar'})   description?: string;
  @ManyToMany(type => Image, image => image.albums)
  images:Image[]
  @ManyToOne(type=>User , user => user.albums)
  owner : User
}

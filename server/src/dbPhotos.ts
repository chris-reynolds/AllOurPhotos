import "reflect-metadata";
import {createConnection, Connection, ConnectionManager, EntityManager, Repository} from "typeorm";
import {User} from "./entity/User";
import {Image} from "./entity/Image";
import {Album} from "./entity/Album";

var gConnection: Connection
var gEM

/* Lets try and isolate our app from typeorm a bit */
class DbSimple {
//   conn : Connection

   constructor() {
   } // of constructor
  static async connect(config:any) {
    const connection = await createConnection(config);
    gConnection = connection
    gEM = gConnection.manager
//    const users = await connection.getRepository(User).createQueryBuilder("user").getMany();
  } // of connect


} // of DbSimple

export class DbPhotos extends DbSimple {
  defaultUser : User
  userRep : Repository<User>
  imageRep : Repository<Image>
  albumRep : Repository<Album>
  constructor() {
    super()
    this.userRep = gConnection.getRepository(User)
    this.imageRep = gConnection.getRepository(Image)
    this.albumRep = gConnection.getRepository(Album)
//    this.addDefaultUser()
//      .catch(error => console.log(error));
  } // of constructor

  async addDefaultUser() {
    const DEFAULT_USERNAME = 'Default'
    if (gConnection && gConnection.isConnected && this.userRep) {
      this.defaultUser = await this.userRep.findOne({'name': DEFAULT_USERNAME})
      if (!this.defaultUser) {
        console.log("Inserting default user into the database...")
        const newUser = new User()
          newUser.name = DEFAULT_USERNAME
        await this.userRep.save(newUser);
        console.log("Saved the new default user with id: " + newUser.id)
        this.defaultUser= newUser
      }
      console.log("Loading users from the database...")
      const users = await this.userRep.createQueryBuilder("user").getMany()
      console.log("Loaded users: ", users)
    } else
      console.log('No connection to add user!!!!!!!!!!!!')
  } // addDefaultUser


  fixDateUTC(d1:Date):Date {
    return new Date(
      d1.getUTCFullYear(),
      d1.getUTCMonth(),
      d1.getUTCDate(),
      d1.getUTCHours(),
      d1.getUTCMinutes(),
      d1.getUTCSeconds(),
      d1.getUTCMilliseconds())
  } // of fixDateUTC
  async hasDuplicate(anImage:Image) {
    if (anImage.id)
      throw new Error('todo check existing dups')
    else {
      let fixeddate = this.fixDateUTC(anImage.takenDate)
      try {
        let similarImages:Image[] = await this.imageRep.find({directory:anImage.directory,filename:anImage.filename,
          height:anImage.height,width:anImage.width, takenDate:fixeddate})
        if (similarImages.length>0)
          return true
        else
          return false
      } catch(err) {
        throw err
      }
    }
  }
}
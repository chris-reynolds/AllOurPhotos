import "reflect-metadata";
import {createConnection,Connection,ConnectionManager,EntityManager} from "typeorm";
import {User} from "./entity/User";

var gConnection: Connection
var gEM

/*
(async function() {
  console.log(await Promise.resolve('hello world'));
  gConnection = await createConnection({
    type: "mysql",
    host: "localhost",
    port: 3306,
    username: "root",
    password: "Instant00",
    database: "photos"
  });
})();
*/


/* Lets try and isolate our app from typeorm a bit */
class DbSimple {
   conn : Connection
   em() : EntityManager {
     return this.conn.manager
     }
   constructor() {
/*     (async function() {
       console.log(await Promise.resolve('hello world2'));
       gConnection = await createConnection({
         type: "mysql",
         host: "localhost",
         port: 3306,
         username: "root",
         password: "Instant00",
         database: "photos"
       });
     })();
     (this.connect())()
 */
//createConnection().then(async connection => {
       this.addUser()
        //.then( ()=> console.log('after addUser'))
          .catch(error => console.log(error));
   } // of constructor
  static async connect(config:any) {
    const connection = await createConnection({
        type: "mysql",
        host: "localhost",
        port: 3306,
        username: "root",
        password: "Instant00",
        database: "photos",
      entities: [
        User
      ],
      "synchronize": true,
    });
    gConnection = connection
    gEM = gConnection.manager
    const users = await connection.getRepository(User).createQueryBuilder("user").getMany();
  } // of connect

  async addUser() {
     if (gConnection && gConnection.isConnected) {
       console.log("Inserting another new user into the database...");
       const user = new User();
       user.firstName = "Timber6";
       user.lastName = "Saw6";
       // if (gConnection.isConnected)
       user.cameras = gConnection.isConnected ? "is connected" : "stuffed"
       await gEM.save(user);
       console.log("Saved a new user with id: " + user.id);

       console.log("Loading users from the database...");
       const users = await gEM.find(User);
       console.log("Loaded users: ", users);
     } else
       console.log('No connection to add user!!!!!!!!!!!!')
  } // addUser

} // of DbSimple

export class DbPhotos extends DbSimple {


}
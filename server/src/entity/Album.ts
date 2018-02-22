import {Image} from "./Image";
import {User} from "./User";

export class Album {
  id: number;
  updatedDate: Date
  createdDate: Date
   name: string;
  description?: string;
  images:Image[]
  owner : User
}

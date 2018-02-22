import {Album} from './Album'
import {Image} from "./Image"

export class User {

  id: number
  updated_on?: Date
  created_on?: Date
  updated_user? : string

  name: string

  albums?: Album[]
  images?: Image[]
} // of User

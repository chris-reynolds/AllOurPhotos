/*
  Created by chrisreynolds on 2019-11-13
  
  Purpose: Simple interface to enpose callback

*/
typedef CallBack = void Function();
abstract class ListProvider<T> {
  // allows the ListProvider to signal to the consumer that the list might have changed
  CallBack onRefreshed;
  List<T> get items;
}


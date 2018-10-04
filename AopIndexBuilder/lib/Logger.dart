/**
 * Created by Chris on 21/09/2018.
 */

typedef LoggerFunc = void Function(String s);

void _message(s) {
  print('----------- $s');   // print to console
} // of message

LoggerFunc message = _message;  // setup default logger
LoggerFunc error = _message; // setup default error logger

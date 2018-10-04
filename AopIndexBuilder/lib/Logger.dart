/**
 * Created by Chris on 21/09/2018.
 */

typedef LoggerFunc = void Function(String s);

void _message(s) {
  print('----------- $s');   // print to console
} // of message

void _error(s) {
  print('--ERROR---- $s');   // print to console
} // of message

LoggerFunc message = _message;  // setup default logger
LoggerFunc error = _error; // setup default error logger

/// Created by Chris on 21/09/2018.

typedef LoggerFunc = void Function(String s);

enum eLogLevel {llMessage,llError}

eLogLevel logLevel = eLogLevel.llMessage;

// setup default loggers
LoggerFunc onMessage = (s) => print('----------- $s');

LoggerFunc onError = (s) => onMessage('--- ERROR ---- $s');


void message(String s) {
  if (logLevel == eLogLevel.llMessage)
    onMessage(s);
}
void error(String s) {
  onError(s);
}

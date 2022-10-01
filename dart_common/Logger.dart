/// Created by Chris on 21/09/2018.

typedef LoggerFunc = void Function(String s);

enum eLogLevel {llMessage,llError}

eLogLevel logLevel = eLogLevel.llMessage;

// setup default loggers
LoggerFunc onMessage = (s) => print('----------- $s');

LoggerFunc onError = (s) => onMessage('--- ERROR ---- $s');

List<String> logHistory = [];

void message(String s) {
  logHistory.add(s);
  if (logHistory.length>100)
    logHistory.removeAt(0);
  if (logLevel == eLogLevel.llMessage)
    onMessage(s);
}
void error(String s) {
  onError(s);
}


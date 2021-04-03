import 'dart:io';
import 'dart:convert' show jsonDecode, utf8, jsonEncode;
import 'package:path/path.dart' as Path;
import 'Logger.dart' as Log;

Map<String,dynamic> config = {};
String finalFileName = 'Unassigned';



Future<void> loadConfig([String commandLineFilename]) async {
//  String os = Platform.operatingSystem;
  String programName = Platform.script.toFilePath();
  String defaultName = programName.replaceAll('\.dart', '\.config\.json'); //.substring(5);
  defaultName = defaultName.replaceAll('\.aot', '\.config\.json');
  defaultName = Path.basename(defaultName);
  String actualFilename = commandLineFilename ?? defaultName;
//  if (Path.dirname(actualFilename)=='.')
//    actualFilename = Path.join((await getApplicationDocumentsDirectory()).path,actualFilename); todo restore
  if (!FileSystemEntity.isFileSync(actualFilename)) {
    Log.message('Invalid configuration name $actualFilename');
    config = {'dbname':'allourphotos_dev','dbport':'3306'};
  } else {
    String configContents = File(actualFilename).readAsStringSync(encoding: utf8);
    try {
      config = jsonDecode(configContents);
    } catch (err,st) {
      throw 'Corrupt configuration file $actualFilename \n $st';
    } // of catch
  }
  finalFileName = actualFilename;
} // of loadConfig

Future<void> saveConfig() async {
    final serialized = jsonEncode(config);
    try {
      await File(finalFileName).writeAsString(serialized);
    } catch (ex) {
      Log.error('Failed to save config to $finalFileName \n with error $ex');
      rethrow;
    }
    return;
} // of saveConfig
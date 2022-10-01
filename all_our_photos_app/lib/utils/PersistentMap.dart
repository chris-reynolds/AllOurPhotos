/*
  Created by chris reynolds on 30/05/22
  
  Purpose: 

*/
import './WebFile.dart';

class PersistentMap {
  final String _url;
  WebFile _webFile;
  final _contents = <int,String>{};

  PersistentMap(this._url);
  load() async {
    _webFile = (await loadWebFile(_url,''));
    String response = _webFile.contents;

    _contents.clear();
    response.split('\n').forEach((line) {
      int delimPos = line.indexOf('=');
      if (delimPos>0) {
        int key = int.parse(line.substring(0,delimPos));
        String value = line.substring(delimPos+1);
        _contents[key] = value;
      }
    }); // of foreach line
  }

  Future<bool> save() async {
    _webFile.contents = toString();
    return await saveWebFile(_webFile);
  }

  @override
  String toString() {
    String result = '';
    _contents.forEach((key, value) { result += '$key=$value\n';});
    return result;
  }
  void clear() => _contents.clear();


  String operator [](int key) => _contents[key]??'';

  void operator []=(int key, String value) {
    _contents[key] = value;
  }

  String remove(Object key) => _contents.remove(key);

  Iterable<int> get keys => _contents.keys;

} // of PersistentMap


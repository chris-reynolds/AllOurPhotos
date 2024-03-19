/*
  Created by chrisreynolds on 2019-09-27
  
  Purpose: This can take the fate of each file and report summaries

*/

enum Fate { Uploaded, Duplicate, Error }

class FileFate {
  String filename;
  Fate fate;
  String reason;
  FileFate(this.filename, this.fate, {this.reason = ''}) {
    fateList.add(this);
  }
}

List<FileFate> fateList = [];

Map<String, int> summary() {
  var result = <String, int>{};
  for (var fileFate in fateList) {
    if (!result.containsKey(fileFate.fate.name))
      result[fileFate.fate.name] = 1;
    else
      result[fileFate.fate.name] = result[fileFate.fate.name]! + 1;
  }
  return result;
}

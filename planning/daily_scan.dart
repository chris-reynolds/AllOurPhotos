/*
This is a dailyscanner program to pick up metrics for project control
Author: chris Reynolds
Date: 29th March 2019
 */

import 'dart:io';

final String DELIMITER = ',';
final DateTime STARTDATE = DateTime(2019,4,1);
final DateTime ENDDATE = DateTime(2019,10,1);
final int PROJECTDURATION = ENDDATE.difference(STARTDATE).inDays;


void main() async {
  int loc = await directoryLinesOfCode('../all_our_photos_app/lib');
  CSVFile bugFile = CSVFile('./BugList.csv');
  var bugList = Bug.loadBugs(bugFile.lines);
  int bugOsCount = bugList.where((bug) => bug.isOutstanding).length;
  CSVFile taskFile = CSVFile('./TaskList.csv');
  var taskList = Task.loadTasks(taskFile.lines);
  int totalTaskSize = 0;
  double totalTaskOutstanding = 0.0;
  for (var task in taskList) {
    totalTaskSize += task.sizeInUnits;
    totalTaskOutstanding += task.outstandingInUnits;
  }
  addToFile('metrics.log', ',$loc,${taskList.length},$totalTaskSize,$totalTaskOutstanding,${bugList.length},$bugOsCount,0,0,0,0');
  //if (DateTime.now().weekday == DateTime.saturday)
    Task.saveCarPark(taskList);
} // of main

String pad(String s,int width) {
  return '$s                                                            '.substring(0,width);
} // of pad

double timeSpentRatio() => DateTime.now().difference(STARTDATE).inDays/PROJECTDURATION;

String displayPair(double doneQty,double totalQty) {
  int percentage = (doneQty*100/totalQty).round();
  return '${doneQty.round()}/${totalQty.round()} = $percentage%';
} // of displayPair

class CSVFile {
  List<String> columnNames;
  List<String> lines = [];
  CSVFile(String filename) {
    lines = File(filename).readAsStringSync().split('\n');
    if (lines.length < 1)
      throw Exception('CSV Files need at least one line for the header');
    columnNames = lines[0].split(',');
    lines.removeAt(0);
  } // of constructor

} // of CSVFile


class Bug {
  String number;
  String description;
  String severity = 'M';   // high/medium/low
  DateTime created;
  DateTime closed;

  static List<Bug> loadBugs(List<String> lines) {
    var result = <Bug>[];
    for (int lineIx=0 ; lineIx<lines.length; lineIx++)
      if (lines[lineIx].length>0)
      try {
        result.add(Bug.fromLine(lines[lineIx].split(DELIMITER)));
      } catch(ex) {
        throw Exception('Failed on bug line ${lineIx+1} with error $ex');
      }
    return result;
  } // loadBugs

  Bug.fromLine(List<String> thisLine) {
    number = thisLine[0];
    description = thisLine[1];
    if (thisLine.length>2  && thisLine[2].length>0 )
      severity = thisLine[2]  ?? '';
    if (thisLine.length>3)
      created = DateTime.parse(thisLine[3]);
    if (thisLine.length>4  && thisLine[4].length > 0)
      closed =  DateTime.parse(thisLine[4]);
  } // of constructor from Line
  bool get isOutstanding => closed == null;
}

class Task {
  String number;
  String description;
  String size ='M';   // big,medium,small
  String progress = 'U';  // unstarted,inprogress,designing,programming,testing,finished
  String group;
  DateTime finishedOn;

  static List<Task> loadTasks(List<String> lines) {
    var result = <Task>[];
    for (int lineIx=0 ; lineIx<lines.length; lineIx++)
      if (lines[lineIx].length>0)
      try {
        result.add(Task.fromLine(lines[lineIx].split(DELIMITER)));
      } catch(ex) {
        throw Exception('Failed on task line ${lineIx+1} with error $ex');
      }
    return result;
  } // loadTasks
  
  Task.fromLine(List<String> thisLine) {
    number = thisLine[0];
    description = thisLine[1];
    if (thisLine.length>2 && thisLine[2].length>0)
      size = thisLine[2].toUpperCase() ?? '';
    if (thisLine.length>3 && thisLine[3].length>0)
      progress = thisLine[3].toUpperCase() ?? '';
    if (thisLine.length>4)
      group = thisLine[4] ?? '';
    if (thisLine.length>5  && thisLine[5].length>0)
      finishedOn =  DateTime.parse(thisLine[5]);
  } // of constructor from Line
  bool get isDone => finishedOn != null;
  int get sizeInUnits {
    if (number=='') return 0;
    if (size=='L') return 9;
    if (size=='M') return 3;
    if (size=='S') return 1;
    throw Exception('Invalid task size for $number - $description');
  } // of sizeInUnits

  int get progressInPercent {
    // unstarted,inprogress,designing,programming,testing,finished
    if (finishedOn != null) return 100;  // has a finshedOnDate
    if (progress=='I') return 10;
    if (progress=='D') return 20;
    if (progress=='P') return 50;
    if (progress=='T') return 80;
    if (progress=='F') return 100;
    return 0;
  } // progressInUnits

  double get outstandingInUnits {
    return sizeInUnits*(1-0.01*progressInPercent);
  } // of outstandingInUnits

  static void saveCarPark(List<Task> taskList) {
    String filename = './carpark'+DateTime.now().toString().substring(0,10)+'.log'; // todo : add date to filename
    List sections = [];
    double totalSize = 0.0, totalDone = 0.0;
    for (var task in taskList) {
      if (task.group.length > 0 || task.sizeInUnits > 0) {
        var foundSectionIx = -1;
        for (int sectionIx = 0; sectionIx < sections.length; sectionIx++)
          if (sections[sectionIx][0] == task.group)
            foundSectionIx = sectionIx;
        if (foundSectionIx == -1) {
          sections.add([task.group, 0.0, 0.0]);
          foundSectionIx = sections.length - 1; // point to last item
        }
        sections[foundSectionIx][1] += task.sizeInUnits;
        sections[foundSectionIx][2] += task.sizeInUnits- task.outstandingInUnits;
        totalSize += task.sizeInUnits;
        totalDone += task.sizeInUnits-task.outstandingInUnits;
      }
    }
    String todo = '--------------------------------------------------------------------';
    String done = '*********************************************************************';
    var logFile = File(filename).openWrite();
    for (var section in sections)
      logFile.writeln('${pad(section[0],12)}'+done.substring(0,(section[2]).round())+
           todo.substring(0,(section[1]-section[2]).round())+pad('',60-section[1].round())+displayPair(section[2], section[1]));
    logFile.writeln();
    logFile.writeln('${pad('              ',72)}'+displayPair(totalDone, totalSize));
    logFile.writeln('Velocity = ${((totalDone/totalSize)*100/timeSpentRatio()).round()}% '+
        'needed to finish by ${ENDDATE.toString().substring(0,10)}');
    logFile.close();
  } // saveCarPark
}  // of Task

void addToFile(String filename,String contents,{bool timestamp:true}) {
  String _timestampStr = '';
  if (timestamp)
    _timestampStr = DateTime.now().toString()+' ';
  try {
    File file = File(filename);
    file.openWrite(mode: FileMode.append)
      ..writeln('$_timestampStr$contents')
      ..close();
  } catch(ex) {
    print(ex.toString());
  }
} // of addToFile

Future<int> directoryLinesOfCode(String rootDir) async {
  int result = 0;
  Directory dir = Directory(rootDir);
  List<FileSystemEntity> fseList = dir.listSync(recursive: true);
  for (FileSystemEntity fse in  fseList) {
    FileSystemEntityType type = await FileSystemEntity.type(fse.path);
    if (type == FileSystemEntityType.file  && fse.path.length>6 &&
        fse.path.substring(fse.path.length-5)=='.dart')
      result += fileLinesOfCode(fse as File);
  } // of file loop
  return result;
} // of lines of code

int fileLinesOfCode(File thisFile) {
  String contents = thisFile.readAsStringSync();
  // remove multiline comments
  List<String> tempList = contents.split('\/\*');
  for (int ix = 0 ; ix<tempList.length; ix++) {
    int terminator = tempList[ix].indexOf('\*\/');
    if (terminator>0)
      tempList[ix] = tempList[ix].substring(terminator+2); // todo check for contig multi comments
  }
  List<String> lines = tempList.join().split('\n');
  // loop backwards so we can delete lines cleanly
  for (int ix=lines.length-1; ix>=0; ix--) {
    String thisLine =  lines[ix].trim();
    if (thisLine.length==0  || (thisLine.length>2 && thisLine.substring(0,2) == '//'))
      lines.removeAt(ix);
  }
  return lines.length;
} // of fileLinesOfCode







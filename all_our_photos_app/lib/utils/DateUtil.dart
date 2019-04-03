

String left(String s,int length) => s.substring(0,length);
String right(String s,int length) => s.substring(s.length-2);

final monthNames = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
String formatDate(DateTime aDate,{String format} ) {
  String result = format;
  result = result.replaceAll('dd', 'TODO');
  result = result.replaceAll('d', aDate.day.toString());
  result = result.replaceAll('mmm', monthNames[aDate.month-1]);
  result = result.replaceAll('mm', right((aDate.month+100).toString(),2));
  result = result.replaceAll('m', aDate.month.toString());
  result = result.replaceAll('yyyy', aDate.year.toString());
  result = result.replaceAll('yy', right((aDate.year).toString(),2));
  result = result.replaceAll('dd', 'TODO');
  result = result.replaceAll('dd', 'TODO');

  return result;
}
DateTime dateTimeFromExif(String exifString)  {
try {
String tmp = exifString.substring(0,4)+'-'+exifString.substring(5,7)+
'-'+exifString.substring(8);
return DateTime.parse(tmp);
} catch(ex) {
return null;
} // of try catch
}  // dateTimeFromExit


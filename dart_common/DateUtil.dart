/*
  Created by Chris on 30th May 2019

  Purpose: Date utilities
*/

const _daysInMonth = const [0, 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31];
final _monthNames = 'Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec'.split(' ');
int _iMin(int x, int y) => (x < y) ? x : y;

bool isLeapYear(int value) =>
    value % 400 == 0 || (value % 4 == 0 && value % 100 != 0);

int daysInMonth(int year, int month) {
  var result = _daysInMonth[month];
  if (month == 2 && isLeapYear(year)) result++;
  return result;
}

DateTime addMonths(DateTime dt, int value) {
  var r = value % 12;
  var q = (value - r) ~/ 12;
  var newYear = dt.year + q;
  var newMonth = dt.month + r;
  if (newMonth > 12) {
    newYear++;
    newMonth -= 12;
  }
  var newDay = _iMin(dt.day, daysInMonth(newYear, newMonth));
  if (dt.isUtc) {
    return new DateTime.utc(newYear, newMonth, newDay, dt.hour, dt.minute,
        dt.second, dt.millisecond, dt.microsecond);
  } else {
    return new DateTime(newYear, newMonth, newDay, dt.hour, dt.minute,
        dt.second, dt.millisecond, dt.microsecond);
  }
} // addMonth

String formatDate(DateTime aDate, {String format = 'yyyy-mm-d'}) {
  String _right2(String s) => s.substring(s.length - 2);
  String n99(int value) => _right2((value + 100).toString());
  String result = format;
  try {
    result = result.replaceAll('dd', n99(aDate.day));
    result = result.replaceAll('d', aDate.day.toString());
    result = result.replaceAll('mmm', _monthNames[aDate.month - 1]);
    result = result.replaceAll('mm', n99(aDate.month + 100));
    result = result.replaceAll('m', aDate.month.toString());
    result = result.replaceAll('yyyy', aDate.year.toString());
    result = result.replaceAll('yy', n99(aDate.year));
    result = result.replaceAll('hh', n99(aDate.hour));
    result = result.replaceAll('nn', n99(aDate.minute));
    result = result.replaceAll('ss', n99(aDate.second));
  } catch(ex) {
    print(ex);
  }
  return result;

}

DateTime parseDMY(String inputStr,{bool allowYearOnly:false}) {
  if (allowYearOnly)
    while (inputStr.split('/').length<3)
      inputStr = '1/$inputStr';
  List<String> bits = inputStr.trim().split(' ');
  List<String> dateBits;
  if (bits[0].indexOf('/')>0) { // assume d/m/yy
    dateBits = bits[0].split('/');
    if (dateBits.length !=3) throw "Must be in the form d/m/y";
    if (dateBits[0].length==1) dateBits[0]='0'+dateBits[0];
    if (dateBits[1].length==1) dateBits[1]='0'+dateBits[1];
    if (dateBits[2].length==2)
      if (dateBits[2].compareTo('50')>0)
        dateBits[2]='19'+dateBits[2];
        else
          dateBits[2]='20'+dateBits[2];
    bits[0] = '${dateBits[2]}-${dateBits[1]}-${dateBits[0]}';
  }
  String workStr = bits.join(' '); // join the time back on, if any
  return DateTime.parse(workStr);
}

DateTime dateTimeFromExif(String exifString) {
  try {
    String tmp = exifString.substring(0, 4) +
        '-' +
        exifString.substring(5, 7) +
        '-' +
        exifString.substring(8);
    return DateTime.parse(tmp);
  } catch (ex) {
    return null;
  } // of try catch
} // dateTimeFromExit
/**
 * Created by Chris on 21/09/2018.
 */


String left(String s, int count) {
  if (s.length<=count)
    return s;
  else
    return s.substring(0,count);
} // of left

String right(String s, int count) {
  if (s.length<=count)
    return s;
  else
    return s.substring(s.length-count);
} // of left

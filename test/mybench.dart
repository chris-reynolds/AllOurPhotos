import 'dart:io';
import 'dart:math';

class PhotoInfo {
  PhotoInfo(this.name,this.tags,this.rank) {
  }
  String name;
  String tags;
  int rank;
  toString() => '"$name","$tags",$rank';
} // of photoInfo

Random rand = Random();
const int MAX_PICS = 10000;
const tagList = ['Janet','Chris','Italy','France','Wales','Ben','Annie','Josie','Spring','Summer','Autumn',
	'Jan','Feb','March','April','May','June','July','Aug','Sep','Nov','Dec'];
const gibberish = ['bjbkj jj kjbjbj jhbkjh jbkjk kjkjkjhkj kjkjhjk kkjkjhkjh lkkhlkhlkh kjkljhkljlkjh',
			'hjkhjkhkh kjhkjkh kjkjhkjhkh kjhkjhkjhkjh kjhkjhkjhklj khhkhkjkjl',
			'tytyyt78878 88798987 987987987 9797 8789 9879 87987 9 798 798 7897',
			'ihioiu iioiu oioiuoiu  jkjj k kjhkhjk khkhkh j bvnbnbn nnnn'];
aTag() => tagList[rand.nextInt(tagList.length)];
aGibber() => gibberish[rand.nextInt(gibberish.length)];
maybe(int x,String tag) => rand.nextInt(x)==0 ? tag : '';

main(List<String> args) {
  print('start ');
  List<PhotoInfo> photoList = [];
  for (int i=0;i<MAX_PICS;i++) {
    int rank = rand.nextInt(5);
    String newName = maybe(10,aGibber()) + maybe(100,aTag()) + maybe(10,aGibber());
    String newTag = maybe(100,aTag())+ ' ' + maybe(100,aTag());
    photoList.add(PhotoInfo(newName,newTag,rank));
//    print(newTag+'\t\t\t'+newName);
  } 
  print('loaded');
  String fullIndex = photoList.join('\n');
  print('full index is ${fullIndex.length}');
  File('fred.csv').writeAsStringSync(fullIndex); 
  bool done = false;
  String searchToken;
  while (!done) {
    stdout.write('search?');
    searchToken = stdin.readLineSync();
    if (searchToken=='quit')
      done = true;
    else {
      List<PhotoInfo> results = photoList.where((photo) => photo.name.contains(searchToken)).toList();
      int count = results.length;
      stdout.writeln('Result for $searchToken : Count = $count');
    }     
  } // of while

} // of main
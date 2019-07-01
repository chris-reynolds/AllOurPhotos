
import '../lib/ExifView.dart' as ExifView;

main(List<String> arguments) async {
  if (arguments.length>0)
    print(await ExifView.show(arguments[0]));
  else
    print('Invalid usage: requres a filename');
}

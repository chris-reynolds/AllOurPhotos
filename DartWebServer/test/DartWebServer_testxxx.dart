import 'package:DartWebServer/DartWebServer.dart' as fred;
import 'package:test/test.dart';
//import '../bin/aopMain.dart' as app;
void main() {
  test('calculate', () {
    expect(fred.calculate(), 42);
  });
}

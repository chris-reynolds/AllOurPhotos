import '../lib//ExifView.dart' as ExifView;
import 'package:test/test.dart';

void main() {
  test('calculate', () async {
    expect(await ExifView.show('blah'), 'blah not found');
  });
}

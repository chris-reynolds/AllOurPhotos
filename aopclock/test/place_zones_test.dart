import 'package:aopclock/place_zones.dart';
import 'package:test/test.dart';
import 'package:timezone/data/latest.dart' as tzdata;

int h(ZoneShift z) => z.primaryMinutes ~/ 60;

void main() {
  setUpAll(tzdata.initializeTimeZones);

  test('Arizona has no DST: NZDT in March is -20h, NZST in June is -19h', () {
    expect(h(expectedShift('America/Phoenix', DateTime.utc(2009, 3, 20, 12))), -20);
    expect(h(expectedShift('America/Phoenix', DateTime.utc(2011, 6, 10, 12))), -19);
  });

  test('UK in July (BST) is -11h, Italy (CEST) is -10h', () {
    expect(h(expectedShift('Europe/London', DateTime.utc(2010, 7, 10, 12))), -11);
    expect(h(expectedShift('Europe/Rome', DateTime.utc(2010, 7, 15, 12))), -10);
  });

  test('UK in December (GMT) is -13h during NZDT', () {
    expect(h(expectedShift('Europe/London', DateTime.utc(2019, 12, 20, 12))), -13);
  });

  test('Dubai September 2008 is -8h; alt (camera left on NZDT) is -9h', () {
    final z = expectedShift('Asia/Dubai', DateTime.utc(2008, 9, 25, 12));
    expect(z.primaryMinutes, -480);
    expect(z.altMinutes, -540);
  });

  test('Vanuatu after NZ daylight time starts is -2h', () {
    expect(h(expectedShift('Pacific/Efate', DateTime.utc(2010, 10, 7, 12))), -2);
  });

  test('home: 0 normally, alt is +1h in NZDT and -1h in NZST', () {
    final summer = expectedShift('Pacific/Auckland', DateTime.utc(2020, 1, 10, 12));
    expect([summer.primaryMinutes, summer.altMinutes], [0, 60]);
    final winter = expectedShift('Pacific/Auckland', DateTime.utc(2020, 7, 10, 12));
    expect([winter.primaryMinutes, winter.altMinutes], [0, -60]);
  });
}

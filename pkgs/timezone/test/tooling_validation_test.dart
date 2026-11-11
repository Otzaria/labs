@TestOn('vm')
library;

import 'package:test/test.dart';
import 'package:timezone/src/tools.dart';
import 'package:timezone/timezone.dart';
import 'package:timezone/tzdata.dart' as tzdata;

void main() {
  test('zone.tab ignores blank and indented comment lines', () {
    final db = tzdata.LocationDescriptionDatabase.fromString(
      '  # comment\n   \nIL\t+3146+03514\tAsia/Jerusalem\n',
    );
    expect(db.locations, hasLength(1));
    expect(db.locations.single.name, 'Asia/Jerusalem');
  });

  for (final line in [
    'IL\tbroken\tAsia/Jerusalem',
    'IL\t+9100+03500\tAsia/Jerusalem',
    'IL\t+3160+03500\tAsia/Jerusalem',
    'IL\t+3159+18100\tAsia/Jerusalem',
    'IL\t+315960+0350000\tAsia/Jerusalem',
    'IL\t+3146+03500',
    'IL',
  ]) {
    test('zone.tab rejects malformed coordinates: $line', () {
      expect(
        () => tzdata.LocationDescription.fromString(line),
        throwsFormatException,
      );
    });
  }

  test('conversion clamps transition values outside Dart DateTime limits', () {
    final loc = tzdata.Location(
      'Test/Zone',
      [-9223372036854775808, 0, 9223372036854775807],
      [0, 0, 0],
      ['TST'],
      [const tzdata.TimeZone(0, isDst: false, abbreviationIndex: 0)],
      [],
      [],
      [],
      [],
    );
    final converted = tzfileLocationToNativeLocation(loc);
    expect(converted.transitionAt, [minTime, 0, maxTime]);
  });
}

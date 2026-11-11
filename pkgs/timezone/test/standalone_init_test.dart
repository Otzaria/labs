@TestOn('vm')
library;

import 'package:test/test.dart';
import 'package:timezone/standalone.dart' as standalone;
import 'package:timezone/timezone.dart' as tz;

void main() {
  test('standalone can load packaged tzdb and resolve known locations', () async {
    await standalone.initializeTimeZone();
    expect(standalone.getLocation('Asia/Jerusalem').name, 'Asia/Jerusalem');
  });

  test('missing timezone data reports TimeZoneInitException', () async {
    await standalone.initializeTimeZone();
    final known = tz.getLocation('America/Detroit');
    await expectLater(
      standalone.initializeTimeZone('data/nonexistent-tzdata-20261111.tzf'),
      throwsA(isA<tz.TimeZoneInitException>()),
    );
    expect(identical(tz.getLocation('America/Detroit'), known), isTrue);
  });
}

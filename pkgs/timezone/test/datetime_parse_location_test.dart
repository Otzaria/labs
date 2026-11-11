@TestOn('vm')
library;

import 'package:test/test.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart';

void main() {
  tz_data.initializeTimeZones();
  final jerusalem = getLocation('Asia/Jerusalem');
  final detroit = getLocation('America/Detroit');

  test('offset-free timestamp is wall time in requested location', () {
    final parsed = TZDateTime.parse(jerusalem, '2026-01-15T09:12:34.567890');
    final constructed = TZDateTime(jerusalem, 2026, 1, 15, 9, 12, 34, 567, 890);
    expect(parsed, constructed);
    expect(parsed.hour, 9);
    expect(parsed.minute, 12);
    expect(parsed.microsecond, 890);
    expect(parsed.timeZoneOffset, const Duration(hours: 2));
  });

  test('same wall time in two zones represents different instants', () {
    final a = TZDateTime.parse(jerusalem, '2026-01-15 12:00:00');
    final b = TZDateTime.parse(detroit, '2026-01-15 12:00:00');
    expect(a.hour, 12);
    expect(b.hour, 12);
    expect(a.millisecondsSinceEpoch, isNot(b.millisecondsSinceEpoch));
  });

  test('explicit UTC suffix preserves the input instant', () {
    final input = '2026-01-15T09:12:34.567890Z';
    final parsed = TZDateTime.parse(jerusalem, input);
    expect(parsed.microsecondsSinceEpoch, DateTime.parse(input).microsecondsSinceEpoch);
    expect(parsed.hour, 11);
  });

  test('explicit numeric offset preserves the input instant', () {
    final input = '2026-01-15T09:12:34+03:00';
    final parsed = TZDateTime.parse(detroit, input);
    expect(parsed.millisecondsSinceEpoch, DateTime.parse(input).millisecondsSinceEpoch);
  });

  test('nonexistent spring-forward wall time follows constructor rules', () {
    final parsed = TZDateTime.parse(detroit, '2023-03-12T02:30:00');
    final constructed = TZDateTime(detroit, 2023, 3, 12, 2, 30);
    expect(parsed, constructed);
    expect(parsed.hour, 3);
    expect(parsed.minute, 30);
  });

  test('date-only string starts at midnight in requested location', () {
    final parsed = TZDateTime.parse(jerusalem, '2026-02-01');
    expect(parsed, TZDateTime(jerusalem, 2026, 2, 1));
  });
}

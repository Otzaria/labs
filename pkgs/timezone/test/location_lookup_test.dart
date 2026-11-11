@TestOn('vm')
library;

import 'package:test/test.dart';
import 'package:timezone/timezone.dart';

void main() {
  const winter = TimeZone(
    Duration(hours: 2),
    isDst: false,
    abbreviation: 'IST',
  );
  const summer = TimeZone(
    Duration(hours: 3),
    isDst: true,
    abbreviation: 'IDT',
  );

  test('timeZone agrees with lookupTimeZone across transition boundaries', () {
    final first = DateTime.utc(2026, 3, 27).millisecondsSinceEpoch;
    final second = DateTime.utc(2026, 10, 25).millisecondsSinceEpoch;
    final location = Location(
      'test/jerusalem',
      [first, second],
      [1, 0],
      [winter, summer],
    );
    for (final timestamp in [
      minTime,
      first - 1,
      first,
      first + 1,
      second - 1,
      second,
      second + 1,
      maxTime - 1,
    ]) {
      expect(
        location.timeZone(timestamp),
        location.lookupTimeZone(timestamp).timeZone,
        reason: 'timeZone mismatch at $timestamp',
      );
    }
    expect(location.timeZone(first - 1), winter);
    expect(location.timeZone(first), summer);
    expect(location.timeZone(second), winter);
  });

  test('cached current interval matches its exact transition boundaries', () {
    final now = DateTime.now().millisecondsSinceEpoch;
    final location = Location(
      'test/current',
      [now - 60000, now + 60000],
      [0, 1],
      [winter, summer],
    );
    expect(location.timeZone(now), winter);
    expect(location.lookupTimeZone(now).start, now - 60000);
    expect(location.lookupTimeZone(now).end, now + 60000);
    expect(location.timeZone(now + 60000), summer);
  });

  test('pre-first and transitionless locations preserve their initial zone', () {
    final later = DateTime.utc(2035).millisecondsSinceEpoch;
    final beforeFirst = Location(
      'test/pre-first',
      [later],
      [1],
      [winter, summer],
    );
    expect(beforeFirst.timeZone(later - 1), winter);
    expect(beforeFirst.lookupTimeZone(later - 1).timeZone, winter);
    expect(beforeFirst.timeZone(later), summer);

    final fixed = Location('test/fixed', [], [], [winter]);
    expect(fixed.timeZone(0), winter);
    expect(fixed.lookupTimeZone(0).timeZone, winter);
    final empty = Location('test/empty', [], [], []);
    expect(empty.timeZone(0), TimeZone.UTC);
    expect(empty.lookupTimeZone(0).timeZone, TimeZone.UTC);
  });
}

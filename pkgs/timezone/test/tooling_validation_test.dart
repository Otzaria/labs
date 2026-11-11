// Copyright (c) 2014, the timezone project authors. Please see the AUTHORS
// file for details. All rights reserved. Use of this source code is governed
// by a BSD-style license that can be found in the LICENSE file.

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
    'IL\t+03146+03514\tAsia/Jerusalem',
    'IL\t+3146+3514\tAsia/Jerusalem',
    'IL\t+314601+03514\tAsia/Jerusalem',
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

  test('conversion preserves the active zones at the DateTime limits', () {
    final loc = tzdata.Location(
      'Test/Zone',
      [-(1 << 62), -(1 << 61), 0, maxTime ~/ 1000 + 1],
      [0, 1, 0, 1],
      ['OLD', 'NEW'],
      [
        const tzdata.TimeZone(0, isDst: false, abbreviationIndex: 0),
        const tzdata.TimeZone(3600, isDst: true, abbreviationIndex: 1),
      ],
      [],
      [],
      [],
      [],
    );
    final converted = tzfileLocationToNativeLocation(loc);
    expect(converted.transitionAt, [minTime, 0]);
    expect(converted.timeZone(minTime).abbreviation, 'NEW');
    expect(converted.timeZone(maxTime).abbreviation, 'OLD');
  });
}

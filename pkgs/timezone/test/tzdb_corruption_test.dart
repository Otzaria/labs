@TestOn('vm')
library;

import 'dart:typed_data';

import 'package:test/test.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/src/tzdb.dart';
import 'package:timezone/timezone.dart';

void main() {
  final sample = LocationDatabase()
    ..add(
      Location(
        'Test/Zone',
        [123000],
        [0],
        [
          const TimeZone(
            Duration(hours: 2),
            isDst: false,
            abbreviation: 'TZ',
          ),
        ],
      ),
    );

  Uint8List encoded() => Uint8List.fromList(tzdbSerialize(sample));

  group('corrupted binary timezone data', () {
    test('rejects invalid zone abbreviation indices', () {
      final bytes = encoded();
      final data = ByteData.sublistView(bytes);
      final zonesOffset = data.getUint32(8 + 16);
      bytes[8 + zonesOffset + 5] = 255;
      expect(() => tzdbDeserialize(bytes).toList(), throwsFormatException);
    });

    test('rejects invalid transition zone indices', () {
      final bytes = encoded();
      final data = ByteData.sublistView(bytes);
      final transitionsOffset = data.getUint32(8 + 24);
      bytes[8 + transitionsOffset + 8] = 255;
      expect(() => tzdbDeserialize(bytes).toList(), throwsFormatException);
    });

    test('rejects invalid daylight-saving flags', () {
      final bytes = encoded();
      final data = ByteData.sublistView(bytes);
      final zonesOffset = data.getUint32(8 + 16);
      bytes[8 + zonesOffset + 4] = 2;
      expect(() => tzdbDeserialize(bytes).toList(), throwsFormatException);
    });

    test('rejects non-finite transition timestamps', () {
      final bytes = encoded();
      final data = ByteData.sublistView(bytes);
      final transitionsOffset = data.getUint32(8 + 24);
      data.setFloat64(8 + transitionsOffset, double.nan);
      expect(() => tzdbDeserialize(bytes).toList(), throwsFormatException);
    });

    test('rejects out-of-order or duplicate transition times', () {
      final sequential = LocationDatabase()
        ..add(
          Location(
            'Test/Two',
            [100000, 200000],
            [0, 0],
            [const TimeZone(
              Duration(hours: 2),
              isDst: false,
              abbreviation: 'TZ',
            )],
          ),
        );
      final bytes = Uint8List.fromList(tzdbSerialize(sequential));
      final data = ByteData.sublistView(bytes);
      final offset = data.getUint32(8 + 24);
      // A duplicate timestamp violates the binary-search precondition.
      data.setFloat64(8 + offset + 8, 100);
      expect(() => tzdbDeserialize(bytes).toList(), throwsFormatException);
    });

    test('rejects fractional transition timestamps', () {
      final bytes = encoded();
      final data = ByteData.sublistView(bytes);
      final offset = data.getUint32(8 + 24);
      data.setFloat64(8 + offset, 123.5);
      expect(() => tzdbDeserialize(bytes).toList(), throwsFormatException);
    });

    test('rejects sections that overlap earlier data', () {
      final bytes = encoded();
      final data = ByteData.sublistView(bytes);
      data.setUint32(8 + 16, 32);
      expect(() => tzdbDeserialize(bytes).toList(), throwsFormatException);
    });

    test('rejects unterminated abbreviation data', () {
      final bytes = encoded();
      final data = ByteData.sublistView(bytes);
      final offset = data.getUint32(8 + 8);
      final length = data.getUint32(8 + 12);
      bytes[8 + offset + length - 1] = 65;
      expect(() => tzdbDeserialize(bytes).toList(), throwsFormatException);
    });
  });

  test('failed initialization preserves the previous database and local zone', () {
    tz_data.initializeTimeZones();
    final before = getLocation('America/Detroit');
    setLocalLocation(before);
    final broken = [...encoded(), 1, 2, 3]; // Truncated second chunk.
    try {
      expect(() => initializeDatabase(broken), throwsFormatException);
      expect(identical(getLocation('America/Detroit'), before), isTrue);
      expect(identical(local, before), isTrue);
    } finally {
      tz_data.initializeTimeZones();
    }
  });
}

@TestOn('vm')
library;

import 'package:test/test.dart';
import 'package:timezone/timezone.dart';

void main() {
  test('deprecated isEmpty and isInitialized are logical opposites', () {
    final db = LocationDatabase();
    // ignore: deprecated_member_use
    expect(db.isEmpty, isTrue);
    expect(db.isInitialized, isFalse);

    db.add(Location('Test/Zone', [], [], [TimeZone.UTC]));
    // ignore: deprecated_member_use
    expect(db.isEmpty, isFalse);
    expect(db.isInitialized, isTrue);

    db.clear();
    // ignore: deprecated_member_use
    expect(db.isEmpty, isTrue);
    expect(db.isInitialized, isFalse);
  });
}

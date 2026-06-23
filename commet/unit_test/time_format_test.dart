import 'package:commet/utils/time_format.dart';
import 'package:test/test.dart';

/// Formats with a fixed locale and normalizes whitespace.
///
/// Recent CLDR data makes `intl` emit a narrow no-break space (U+202F) before
/// the AM/PM marker rather than an ASCII space; normalizing keeps the expected
/// values readable without asserting on the exact space codepoint.
String fmt(DateTime t, {required bool use24Hour}) =>
    formatTimeOfDay(t, use24Hour: use24Hour, locale: 'en_US')
        .replaceAll(RegExp(r'\s'), ' ');

void main() {
  group('formatTimeOfDay', () {
    test('24-hour afternoon', () {
      expect(fmt(DateTime(2026, 6, 23, 14, 30), use24Hour: true), '14:30');
    });

    test('12-hour afternoon uses AM/PM marker', () {
      expect(fmt(DateTime(2026, 6, 23, 14, 30), use24Hour: false), '2:30 PM');
    });

    test('24-hour morning is zero-padded', () {
      expect(fmt(DateTime(2026, 6, 23, 9, 5), use24Hour: true), '09:05');
    });

    test('12-hour morning is not zero-padded', () {
      expect(fmt(DateTime(2026, 6, 23, 9, 5), use24Hour: false), '9:05 AM');
    });

    test('midnight', () {
      final t = DateTime(2026, 6, 23, 0, 0);
      expect(fmt(t, use24Hour: true), '00:00');
      expect(fmt(t, use24Hour: false), '12:00 AM');
    });

    test('noon', () {
      final t = DateTime(2026, 6, 23, 12, 0);
      expect(fmt(t, use24Hour: true), '12:00');
      expect(fmt(t, use24Hour: false), '12:00 PM');
    });
  });

  group('TimeFormatPreference', () {
    test('round-trips every storage value', () {
      for (final p in TimeFormatPreference.values) {
        expect(TimeFormatPreference.fromStorage(p.storageValue), p);
      }
    });

    test('null and unknown values default to system', () {
      expect(
          TimeFormatPreference.fromStorage(null), TimeFormatPreference.system);
      expect(TimeFormatPreference.fromStorage('garbage'),
          TimeFormatPreference.system);
    });
  });
}

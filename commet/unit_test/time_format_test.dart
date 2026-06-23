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

  group('classifyRelativeDay', () {
    final now = DateTime(2026, 6, 23, 10, 0);

    test('same calendar day is today', () {
      expect(classifyRelativeDay(DateTime(2026, 6, 23, 0, 1), now),
          RelativeDay.today);
      expect(classifyRelativeDay(DateTime(2026, 6, 23, 23, 59), now),
          RelativeDay.today);
    });

    test('previous calendar day is yesterday even if < 24h apart', () {
      // 23:00 yesterday vs 10:00 today is 11h, but a different calendar day.
      expect(classifyRelativeDay(DateTime(2026, 6, 22, 23, 0), now),
          RelativeDay.yesterday);
    });

    test('two days ago is older', () {
      expect(classifyRelativeDay(DateTime(2026, 6, 21, 23, 59), now),
          RelativeDay.older);
    });

    test('handles month boundary', () {
      final july1 = DateTime(2026, 7, 1, 9, 0);
      expect(classifyRelativeDay(DateTime(2026, 6, 30, 12, 0), july1),
          RelativeDay.yesterday);
    });

    test('handles year boundary', () {
      final jan1 = DateTime(2026, 1, 1, 0, 30);
      expect(classifyRelativeDay(DateTime(2025, 12, 31, 23, 30), jan1),
          RelativeDay.yesterday);
    });

    test('future timestamps are treated as today', () {
      expect(classifyRelativeDay(DateTime(2026, 6, 23, 18, 0), now),
          RelativeDay.today);
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

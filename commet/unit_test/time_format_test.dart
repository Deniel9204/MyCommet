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

  group('formatRelativeTime', () {
    final now = DateTime(2026, 6, 23, 12, 0, 0);

    String ago(Duration d) => formatRelativeTime(now.subtract(d), now);

    test('under a minute is "now"', () {
      expect(ago(Duration.zero), 'now');
      expect(ago(const Duration(seconds: 59)), 'now');
    });

    test('minutes', () {
      expect(ago(const Duration(minutes: 1)), '1m');
      expect(ago(const Duration(minutes: 59)), '59m');
    });

    test('hours', () {
      expect(ago(const Duration(hours: 1)), '1h');
      expect(ago(const Duration(hours: 23)), '23h');
    });

    test('days', () {
      expect(ago(const Duration(days: 1)), '1d');
      expect(ago(const Duration(days: 6)), '6d');
    });

    test('weeks', () {
      expect(ago(const Duration(days: 7)), '1w');
      expect(ago(const Duration(days: 29)), '4w');
    });

    test('months', () {
      expect(ago(const Duration(days: 30)), '1mo');
      expect(ago(const Duration(days: 364)), '12mo');
    });

    test('years', () {
      expect(ago(const Duration(days: 365)), '1y');
      expect(ago(const Duration(days: 365 * 2)), '2y');
    });

    test('future timestamps clamp to "now"', () {
      expect(formatRelativeTime(now.add(const Duration(hours: 5)), now), 'now');
    });
  });

  group('resolveUse24Hour', () {
    test('explicit 24-hour overrides system default', () {
      expect(
          resolveUse24Hour(TimeFormatPreference.twentyFourHour, false), isTrue);
    });

    test('explicit 12-hour overrides system default', () {
      expect(resolveUse24Hour(TimeFormatPreference.twelveHour, true), isFalse);
    });

    test('system defers to the platform flag', () {
      expect(resolveUse24Hour(TimeFormatPreference.system, true), isTrue);
      expect(resolveUse24Hour(TimeFormatPreference.system, false), isFalse);
    });

    test('explicit prefs are independent of the system flag', () {
      expect(resolveUse24Hour(TimeFormatPreference.twelveHour, true),
          resolveUse24Hour(TimeFormatPreference.twelveHour, false));
      expect(resolveUse24Hour(TimeFormatPreference.twentyFourHour, true),
          resolveUse24Hour(TimeFormatPreference.twentyFourHour, false));
    });

    test('feeds formatTimeOfDay correctly', () {
      final t = DateTime(2026, 6, 23, 14, 30);
      final use24 =
          resolveUse24Hour(TimeFormatPreference.twentyFourHour, false);
      expect(fmt(t, use24Hour: use24), '14:30');
      final use12 = resolveUse24Hour(TimeFormatPreference.twelveHour, true);
      expect(fmt(t, use24Hour: use12), '2:30 PM');
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

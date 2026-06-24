import 'package:commet_calendar_widget/week_start.dart';
import 'package:test/test.dart';

void main() {
  // calendar_view's WeekDays enum is Monday-first:
  // monday=0, tuesday=1, wednesday=2, thursday=3, friday=4, saturday=5, sunday=6.
  // MaterialLocalizations.firstDayOfWeekIndex is Sunday-first (Sunday=0).
  group('calendarViewWeekdayIndex', () {
    test('Sunday (0) maps to WeekDays.sunday (6)', () {
      expect(calendarViewWeekdayIndex(0), 6);
    });

    test('Monday (1) maps to WeekDays.monday (0)', () {
      expect(calendarViewWeekdayIndex(1), 0);
    });

    test('Saturday (6) maps to WeekDays.saturday (5)', () {
      expect(calendarViewWeekdayIndex(6), 5);
    });

    test('maps every weekday to a distinct, in-range WeekDays index', () {
      final mapped = [for (var i = 0; i < 7; i++) calendarViewWeekdayIndex(i)];
      expect(mapped.toSet().length, 7);
      expect(mapped.every((i) => i >= 0 && i < 7), isTrue);
    });
  });
}

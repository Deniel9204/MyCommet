/// Converts Flutter's [MaterialLocalizations.firstDayOfWeekIndex] — where
/// `0 = Sunday` and `6 = Saturday` — into an index for the `calendar_view`
/// package's `WeekDays` enum, which is Monday-first (`0 = Monday` … `6 = Sunday`).
///
/// The calendar views hardcoded a Monday start (#841); sourcing the start day
/// from the device locale instead fixes that for Sunday/Saturday-first regions.
/// This off-by-one-prone conversion lives in its own Flutter-free helper so it
/// can be unit tested directly. [materialFirstDayOfWeekIndex] is expected to be
/// in the range 0–6.
int calendarViewWeekdayIndex(int materialFirstDayOfWeekIndex) {
  return (materialFirstDayOfWeekIndex + 6) % 7;
}

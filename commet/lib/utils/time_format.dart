import 'package:intl/intl.dart';

/// How the user wants times of day to be displayed in the timeline.
///
/// Persisted via [storageValue] / [fromStorage] so the representation stays
/// stable even if the enum is reordered.
enum TimeFormatPreference {
  /// Follow the operating system / locale 24-hour setting.
  system,

  /// Always use 12-hour format with an AM/PM marker (e.g. `2:30 PM`).
  twelveHour,

  /// Always use 24-hour format (e.g. `14:30`).
  twentyFourHour;

  /// The string written to shared preferences.
  String get storageValue => switch (this) {
        TimeFormatPreference.system => "system",
        TimeFormatPreference.twelveHour => "12",
        TimeFormatPreference.twentyFourHour => "24",
      };

  /// Parses a persisted value, defaulting to [system] for null/unknown input.
  static TimeFormatPreference fromStorage(String? value) => switch (value) {
        "12" => TimeFormatPreference.twelveHour,
        "24" => TimeFormatPreference.twentyFourHour,
        _ => TimeFormatPreference.system,
      };
}

/// Formats [time] as a localized time-of-day string.
///
/// When [use24Hour] is true the result uses 24-hour notation (`HH:mm`),
/// otherwise 12-hour notation with the locale's AM/PM marker (`h:mm a`).
///
/// This is a pure function (no Flutter dependency) so it can be unit tested
/// directly; callers resolve [use24Hour] from the user preference and, when
/// that preference is "follow system", from `MediaQuery.alwaysUse24HourFormat`.
String formatTimeOfDay(DateTime time, {required bool use24Hour, String? locale}) {
  final format = use24Hour ? DateFormat.Hm(locale) : DateFormat.jm(locale);
  return format.format(time);
}

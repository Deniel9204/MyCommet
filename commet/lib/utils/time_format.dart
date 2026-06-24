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
String formatTimeOfDay(DateTime time,
    {required bool use24Hour, String? locale}) {
  final format = use24Hour ? DateFormat.Hm(locale) : DateFormat.jm(locale);
  return format.format(time);
}

/// Where [time] falls relative to [now], compared by calendar day (not by a
/// 24-hour difference): a message at 23:00 and a "now" at 01:00 the next
/// morning are [RelativeDay.yesterday], not the same day.
enum RelativeDay { today, yesterday, older }

/// Classifies [time] against [now] by calendar day. Pure so it can be unit
/// tested; the caller supplies localized "Today"/"Yesterday" labels.
RelativeDay classifyRelativeDay(DateTime time, DateTime now) {
  final t = DateTime(time.year, time.month, time.day);
  final n = DateTime(now.year, now.month, now.day);
  final days = n.difference(t).inDays;

  if (days <= 0) return RelativeDay.today;
  if (days == 1) return RelativeDay.yesterday;
  return RelativeDay.older;
}

/// Formats [time] relative to [now] as a compact, locale-neutral "time ago"
/// string for Discord-style per-message timestamps: `now`, `5m`, `2h`, `3d`,
/// `1w`, `4mo`, `2y`. Months and years are approximate (30- and 365-day
/// buckets), which is the norm for a relative timestamp. Timestamps in the
/// future (e.g. from clock skew) are clamped to `now`.
///
/// Pure (no Flutter / locale dependency) so it can be unit tested directly.
String formatRelativeTime(DateTime time, DateTime now) {
  var diff = now.difference(time);
  if (diff.isNegative) diff = Duration.zero;

  if (diff.inSeconds < 60) return "now";
  if (diff.inMinutes < 60) return "${diff.inMinutes}m";
  if (diff.inHours < 24) return "${diff.inHours}h";
  if (diff.inDays < 7) return "${diff.inDays}d";
  if (diff.inDays < 30) return "${diff.inDays ~/ 7}w";
  if (diff.inDays < 365) return "${diff.inDays ~/ 30}mo";
  return "${diff.inDays ~/ 365}y";
}

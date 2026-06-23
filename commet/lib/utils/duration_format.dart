/// Formats a media [duration] as a short, human-readable string:
/// `5s` for under a minute, `m:ss` under an hour, and `h:mm:ss` otherwise.
///
/// Minutes and seconds are zero-padded to two digits in the larger units so a
/// 2m5s clip reads `2:05` rather than `2:5`. Pure (no Flutter dependency) so it
/// can be unit tested directly.
String durationToShortString(Duration duration) {
  String two(int n) => n.toString().padLeft(2, '0');

  if (duration.inSeconds < 60) {
    return "${duration.inSeconds}s";
  }

  if (duration.inMinutes < 60) {
    return "${duration.inMinutes.remainder(60)}:${two(duration.inSeconds.remainder(60))}";
  }

  return "${duration.inHours}:${two(duration.inMinutes.remainder(60))}:${two(duration.inSeconds.remainder(60))}";
}

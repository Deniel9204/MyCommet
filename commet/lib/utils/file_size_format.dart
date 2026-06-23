/// Formats a byte count as a human-readable size, e.g. `1.50 KB`.
///
/// Uses 1024-based units by default; pass [base1024] false for 1000-based.
/// A trailing all-zero fractional part is trimmed (`5.00` -> `5`). Pure (no
/// Flutter dependency) so it can be unit tested directly.
String formatFileSize(num number, {bool base1024 = true}) {
  const List<String> affixes = ['B', 'KB', 'MB', 'GB', 'TB', 'PB'];
  const int round = 2;
  final num divider = base1024 ? 1024 : 1000;

  num size = number;
  num runningDivider = divider;
  num runningPreviousDivider = 0;
  int affix = 0;

  while (size >= runningDivider && affix < affixes.length - 1) {
    runningPreviousDivider = runningDivider;
    runningDivider *= divider;
    affix++;
  }

  String result =
      (runningPreviousDivider == 0 ? size : size / runningPreviousDivider)
          .toStringAsFixed(round);

  // Trim a trailing all-zero fractional part (e.g. "5.00" -> "5").
  if (result.endsWith("0" * round)) {
    result = result.substring(0, result.length - round - 1);
  }

  return "$result ${affixes[affix]}";
}

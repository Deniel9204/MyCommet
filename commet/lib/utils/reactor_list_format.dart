/// Formats a list of reactor display names for a "who reacted" tooltip:
/// "Alice", "Alice and Bob", "Alice, Bob and Carol",
/// "Alice, Bob, Carol and 2 others".
///
/// Pure — no Flutter import — so the formatting is unit testable.
String formatReactorNames(List<String> names, {int maxNames = 3}) {
  if (names.isEmpty) return '';
  if (names.length == 1) return names.first;

  if (names.length <= maxNames) {
    final head = names.sublist(0, names.length - 1).join(', ');
    return '$head and ${names.last}';
  }

  final shown = names.sublist(0, maxNames).join(', ');
  final remaining = names.length - maxNames;
  return '$shown and $remaining other${remaining == 1 ? '' : 's'}';
}

/// Result of wrapping (or unwrapping) a text selection with a markdown marker.
class MarkdownWrapResult {
  final String text;
  final int selectionStart;
  final int selectionEnd;

  const MarkdownWrapResult(this.text, this.selectionStart, this.selectionEnd);

  @override
  bool operator ==(Object other) =>
      other is MarkdownWrapResult &&
      other.text == text &&
      other.selectionStart == selectionStart &&
      other.selectionEnd == selectionEnd;

  @override
  int get hashCode => Object.hash(text, selectionStart, selectionEnd);

  @override
  String toString() =>
      'MarkdownWrapResult("$text", $selectionStart, $selectionEnd)';
}

/// Toggles a markdown [marker] (e.g. `**`, `_`, `` ` ``) around the selection
/// `[start, end)` within [text].
///
/// - If the selection is already wrapped by [marker] (markers either just
///   outside the selection, or as the first/last characters of the selection),
///   the markers are removed.
/// - Otherwise the selection is wrapped, and the returned selection covers the
///   same characters (now between the markers). An empty selection inserts the
///   markers and places the cursor between them.
///
/// Pure (no Flutter dependency) so it can be unit tested directly.
MarkdownWrapResult wrapSelection(
    String text, int start, int end, String marker) {
  if (start > end) {
    final tmp = start;
    start = end;
    end = tmp;
  }
  start = start.clamp(0, text.length);
  end = end.clamp(0, text.length);

  final before = text.substring(0, start);
  final selected = text.substring(start, end);
  final after = text.substring(end);
  final n = marker.length;

  // Markers immediately outside the selection -> unwrap them.
  if (before.endsWith(marker) && after.startsWith(marker)) {
    final newText =
        before.substring(0, before.length - n) + selected + after.substring(n);
    return MarkdownWrapResult(newText, start - n, end - n);
  }

  // Selection itself begins and ends with the marker -> unwrap.
  if (selected.length >= 2 * n &&
      selected.startsWith(marker) &&
      selected.endsWith(marker)) {
    final inner = selected.substring(n, selected.length - n);
    return MarkdownWrapResult(
        before + inner + after, start, start + inner.length);
  }

  // Otherwise wrap the selection.
  final newText = '$before$marker$selected$marker$after';
  return MarkdownWrapResult(newText, start + n, end + n);
}

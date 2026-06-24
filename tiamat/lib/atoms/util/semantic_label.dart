/// Normalizes a caller-supplied semantic label for an icon-only button.
///
/// Returns `null` for a null or blank label so the button omits the label
/// entirely (and keeps just its implicit "button" role) rather than announcing
/// an empty string. Surrounding whitespace is trimmed.
///
/// Pure (no Flutter import) so it can be unit tested directly.
String? resolveButtonSemanticLabel(String? label) {
  if (label == null) return null;
  final trimmed = label.trim();
  return trimmed.isEmpty ? null : trimmed;
}

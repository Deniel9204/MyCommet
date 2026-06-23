/// Normalizes a user-entered account-switch prefix for storage.
///
/// Returns null when the prefix is null, empty, or only whitespace — that
/// clears the prefix. Otherwise the prefix is preserved verbatim, **including
/// a trailing space**: trailing spaces are meaningful so a prefix like
/// `"alice "` matches the message `"alice hello"` but not `"alicia"` (#875).
/// Previously the value was `.trim()`med, which silently dropped the trailing
/// space and broke prefixes that relied on it.
String? normalizeAccountPrefix(String? input) {
  if (input == null) return null;
  if (input.trim().isEmpty) return null;
  return input;
}

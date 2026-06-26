/// Builds a homeserver [Uri] from what the user typed on the login screen.
///
/// Accepts a bare host (`matrix.org`), a host:port (`localhost:8008`), or a full
/// URL with a scheme (`https://matrix.org`, `http://localhost`). When no scheme
/// is present https is assumed, and any trailing slash is trimmed.
///
/// The login page previously passed the raw input straight to `Uri.https()` as
/// the authority, so any input containing a scheme threw a `FormatException`
/// (the leading `//host` was parsed as a port) and crashed homeserver lookup —
/// both for users pasting a full URL and for the integration tests, which use
/// `http://localhost`.
Uri homeserverUriFromInput(String input) {
  var trimmed = input.trim();
  while (trimmed.endsWith('/')) {
    trimmed = trimmed.substring(0, trimmed.length - 1);
  }

  final hasScheme =
      trimmed.startsWith('http://') || trimmed.startsWith('https://');
  return Uri.parse(hasScheme ? trimmed : 'https://$trimmed');
}

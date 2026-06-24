/// Builds a `matrix.to` permalink for a room, optionally pointing at a specific
/// event, with optional `via` routing servers.
///
/// Pure — no Flutter/Matrix imports — so the URL format is unit testable.
/// Format: `https://matrix.to/#/<roomId>[/<eventId>][?via=a&via=b]` using raw
/// identifiers, matching the canonical matrix.to form clients produce and
/// parse.
String buildMatrixToLink({
  required String roomId,
  String? eventId,
  List<String> via = const [],
}) {
  final buffer = StringBuffer('https://matrix.to/#/');
  buffer.write(roomId);
  if (eventId != null && eventId.isNotEmpty) {
    buffer.write('/');
    buffer.write(eventId);
  }
  if (via.isNotEmpty) {
    buffer.write('?');
    buffer.write(via.map((v) => 'via=$v').join('&'));
  }
  return buffer.toString();
}

/// Extracts the server name from a matrix identifier such as
/// `!room:example.org` or `@user:example.org` -> `example.org`. Returns null
/// when there is no server part.
String? serverNameFromMatrixId(String id) {
  final index = id.indexOf(':');
  if (index < 0 || index + 1 >= id.length) return null;
  return id.substring(index + 1);
}

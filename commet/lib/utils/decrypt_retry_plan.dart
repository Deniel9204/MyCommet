/// A minimal, Flutter/SDK-free description of one timeline event, carrying only
/// what the bulk re-decrypt planner needs. The caller builds it from a
/// `matrix.Event`:
///   eventId           -> event.eventId
///   isUndecryptable   -> event.type == EventTypes.Encrypted &&
///                        event.messageType == MessageTypes.BadEncrypted
///   canRequestSession -> event.content['can_request_session'] == true
///   sessionId         -> event.content['session_id'] as String?
///   senderKey         -> event.content['sender_key'] as String?
typedef EncryptedEventDescriptor = ({
  String eventId,
  bool isUndecryptable,
  bool canRequestSession,
  String? sessionId,
  String? senderKey,
});

/// One megolm session key to re-request, deduplicated across events.
typedef SessionKeyRequest = ({String sessionId, String? senderKey});

/// The plan for a single bulk re-decrypt pass over a room's timeline.
class DecryptRetryPlan {
  /// Event ids that are still undecryptable (in input order, deduplicated).
  /// Used to refresh those timeline entries once keys arrive.
  final List<String> eventIdsToRefresh;

  /// Deduplicated megolm session keys to re-request. Usually far smaller than
  /// [eventIdsToRefresh]: many events share one megolm session, so a single
  /// to-device request covers them all. Deduping here is the whole point — it
  /// avoids blasting one request per event to every device in the room.
  final List<SessionKeyRequest> keysToRequest;

  const DecryptRetryPlan({
    required this.eventIdsToRefresh,
    required this.keysToRequest,
  });

  bool get isEmpty => eventIdsToRefresh.isEmpty && keysToRequest.isEmpty;
}

/// Computes which timeline events still need decryption and the deduplicated
/// set of megolm session keys to re-request.
///
/// Rules (each grounded in the SDK's `Event.requestKey` precondition):
///  - Only [EncryptedEventDescriptor.isUndecryptable] events are considered.
///  - Every still-undecryptable event id is added to [eventIdsToRefresh] (so
///    the UI can re-convert it once keys arrive) — even one whose key can't be
///    requested; it simply stays encrypted.
///  - An event contributes a key request only when
///    [EncryptedEventDescriptor.canRequestSession] is true AND it has a
///    non-null `sessionId`.
///  - Key requests are deduplicated by `(sessionId, senderKey)`.
DecryptRetryPlan planDecryptRetry(Iterable<EncryptedEventDescriptor> events) {
  final refresh = <String>[];
  final seenEventIds = <String>{};
  final keys = <SessionKeyRequest>[];
  final seenKeys = <String>{};

  for (final e in events) {
    if (!e.isUndecryptable) continue;

    if (seenEventIds.add(e.eventId)) {
      refresh.add(e.eventId);
    }

    final sessionId = e.sessionId;
    if (!e.canRequestSession || sessionId == null) continue;

    final dedupKey = '$sessionId|${e.senderKey ?? ''}';
    if (seenKeys.add(dedupKey)) {
      keys.add((sessionId: sessionId, senderKey: e.senderKey));
    }
  }

  return DecryptRetryPlan(eventIdsToRefresh: refresh, keysToRequest: keys);
}

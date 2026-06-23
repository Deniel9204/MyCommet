/// Holds unsent composer text per room so it isn't lost when switching rooms.
///
/// In-memory only (per app session). Pure (no Flutter dependency) so the
/// set/get/clear semantics can be unit tested directly.
class DraftStore {
  final Map<String, String> _drafts;

  DraftStore([Map<String, String>? initial]) : _drafts = {...?initial};

  /// The saved draft for [roomId], or null if there is none.
  String? getDraft(String roomId) => _drafts[roomId];

  /// Saves [text] as the draft for [roomId]. Whitespace-only or empty text
  /// clears the draft instead of storing it, so an emptied composer doesn't
  /// leave a stale draft behind.
  void setDraft(String roomId, String text) {
    if (text.trim().isEmpty) {
      _drafts.remove(roomId);
    } else {
      _drafts[roomId] = text;
    }
  }

  /// Removes the draft for [roomId] (e.g. after the message is sent).
  void clearDraft(String roomId) => _drafts.remove(roomId);

  /// Whether [roomId] currently has a non-empty draft.
  bool hasDraft(String roomId) => _drafts.containsKey(roomId);
}

/// App-wide draft store instance.
final DraftStore messageDrafts = DraftStore();

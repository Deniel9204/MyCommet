/// A parsed message-search query: free-text [words] plus optional filters
/// (`type:`, `from:`, `has:link|image|video|file`).
///
/// Pure — no Flutter or Matrix imports — so the parsing and match rules can be
/// unit tested and shared between per-room and cross-room (global) search.
class SearchQuery {
  SearchQuery({
    required this.words,
    this.requiredType,
    this.requiredSender,
    this.requireUrl = false,
    this.requireImage = false,
    this.requireVideo = false,
    this.requireAttachment = false,
  });

  final List<String> words;
  final String? requiredType;
  final String? requiredSender;
  final bool requireUrl;
  final bool requireImage;
  final bool requireVideo;
  final bool requireAttachment;

  static const String hasLinkString = 'has:link';
  static const String hasImageString = 'has:image';
  static const String hasVideoString = 'has:video';
  static const String hasFileString = 'has:file';

  factory SearchQuery.parse(String searchTerm) {
    final lower = searchTerm.toLowerCase();
    var words = lower.split(' ');

    final typeMatch = words.where((w) => w.startsWith('type:')).firstOrNull;
    final requiredType =
        typeMatch != null ? typeMatch.split('type:').last : null;

    final userMatch = words.where((w) => w.startsWith('from:')).firstOrNull;
    final requiredSender =
        userMatch != null ? userMatch.split('from:').last : null;

    final requireUrl = words.contains(hasLinkString);
    final requireImage = words.contains(hasImageString);
    final requireVideo = words.contains(hasVideoString);
    final requireAttachment = words.contains(hasFileString);

    words = words
        .where((w) => ![
              typeMatch,
              hasLinkString,
              hasImageString,
              hasVideoString,
              hasFileString,
            ].contains(w))
        .toList();

    return SearchQuery(
      words: words,
      requiredType: requiredType,
      requiredSender: requiredSender,
      requireUrl: requireUrl,
      requireImage: requireImage,
      requireVideo: requireVideo,
      requireAttachment: requireAttachment,
    );
  }

  /// Whether an event matches this query. The caller passes the event's
  /// already-extracted fields, keeping this free of any Matrix dependency.
  bool matches({
    required String plaintextBody,
    String? type,
    String? messageType,
    String? senderId,
    bool hasAttachment = false,
    bool isImageAttachment = false,
    bool isVideoAttachment = false,
  }) {
    final body = plaintextBody.toLowerCase();
    final numMatchingWords = words.where((w) => body.contains(w)).length;

    if (requireAttachment && !hasAttachment) return false;
    if (requireImage && !isImageAttachment) return false;
    if (requireVideo && !isVideoAttachment) return false;
    if (requireUrl &&
        !(body.contains('https://') || body.contains('http://'))) {
      return false;
    }
    if (requiredType != null &&
        type != requiredType &&
        messageType != requiredType) {
      return false;
    }
    if (requiredSender != null && senderId != requiredSender) return false;

    // Require at least half of the free-text words to be present. With no
    // free-text words (filter-only query) this is 0 < 0 -> matches everything
    // that passed the filters above.
    if (numMatchingWords < words.length / 2.0) return false;
    return true;
  }
}

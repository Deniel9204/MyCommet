/// Builds a single screen-reader label for a timeline message so assistive
/// technology announces it as one coherent unit ("Alice, 3:45 PM: Hello. has
/// attachment. edited") instead of a silent pile of nested layout widgets.
///
/// The caller supplies already-localized fragments (mirroring how the timeline
/// produces its "edited" marker), so this stays a pure, locale-neutral,
/// Flutter-free function — unit testable directly, like the other formatting
/// helpers in this directory. The message body is trimmed and truncated to
/// [maxBodyLength] so the label doesn't read out an entire long message.
String buildMessageSemanticLabel({
  required String senderName,
  String? timestamp,
  String? body,
  bool hasAttachment = false,
  bool hasSticker = false,
  bool hasReactions = false,
  bool isEdited = false,
  String attachmentLabel = 'has attachment',
  String stickerLabel = 'sticker',
  String reactionsLabel = 'has reactions',
  String editedLabel = 'edited',
  int maxBodyLength = 200,
}) {
  final header = StringBuffer(senderName);
  if (timestamp != null && timestamp.isNotEmpty) {
    header.write(', $timestamp');
  }

  final trimmedBody = body?.trim();
  if (trimmedBody != null && trimmedBody.isNotEmpty) {
    final shown = trimmedBody.length > maxBodyLength
        ? '${trimmedBody.substring(0, maxBodyLength).trimRight()}…'
        : trimmedBody;
    header.write(': $shown');
  }

  final segments = <String>[header.toString()];
  if (hasAttachment) segments.add(attachmentLabel);
  if (hasSticker) segments.add(stickerLabel);
  if (hasReactions) segments.add(reactionsLabel);
  if (isEdited) segments.add(editedLabel);

  return segments.join('. ');
}

/// Builds the screen-reader label for a message reaction chip, e.g.
/// "thumbsup, 3 reactions".
///
/// The reaction noun is supplied pre-localized (both forms) so this stays a
/// pure, Flutter-free function that picks singular vs. plural itself. Whether
/// the current user has reacted is conveyed separately via the chip's toggled
/// semantics, so it isn't part of the label.
String buildReactionSemanticLabel({
  required String emojiName,
  required int count,
  String reactionSingular = 'reaction',
  String reactionPlural = 'reactions',
}) {
  final word = count == 1 ? reactionSingular : reactionPlural;
  return '$emojiName, $count $word';
}

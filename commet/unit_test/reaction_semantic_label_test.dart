import 'package:commet/utils/reaction_semantic_label.dart';
import 'package:test/test.dart';

void main() {
  group('buildReactionSemanticLabel', () {
    test('plural for many', () {
      expect(buildReactionSemanticLabel(emojiName: 'thumbsup', count: 3),
          'thumbsup, 3 reactions');
    });

    test('singular for exactly one', () {
      expect(buildReactionSemanticLabel(emojiName: 'heart', count: 1),
          'heart, 1 reaction');
    });

    test('zero uses the plural form', () {
      expect(buildReactionSemanticLabel(emojiName: 'x', count: 0),
          'x, 0 reactions');
    });

    test('uses injected localized words', () {
      expect(
        buildReactionSemanticLabel(
          emojiName: 'x',
          count: 2,
          reactionSingular: 'réaction',
          reactionPlural: 'réactions',
        ),
        'x, 2 réactions',
      );
    });
  });
}

import 'package:commet/utils/message_semantic_label.dart';
import 'package:test/test.dart';

void main() {
  group('buildMessageSemanticLabel', () {
    test('sender name only', () {
      expect(buildMessageSemanticLabel(senderName: 'Alice'), 'Alice');
    });

    test('header with timestamp and body', () {
      expect(
        buildMessageSemanticLabel(
            senderName: 'Alice', timestamp: '3:45 PM', body: 'Hello world'),
        'Alice, 3:45 PM: Hello world',
      );
    });

    test('full house joins metadata as sentences', () {
      expect(
        buildMessageSemanticLabel(
          senderName: 'Alice',
          timestamp: '3:45 PM',
          body: 'Hi',
          hasAttachment: true,
          hasReactions: true,
          isEdited: true,
        ),
        'Alice, 3:45 PM: Hi. has attachment. has reactions. edited',
      );
    });

    test('blank body is omitted', () {
      expect(buildMessageSemanticLabel(senderName: 'Bob', body: '   '), 'Bob');
    });

    test('long body is truncated with an ellipsis', () {
      final long = 'a' * 250;
      expect(
        buildMessageSemanticLabel(
            senderName: 'A', body: long, maxBodyLength: 200),
        'A: ${'a' * 200}…',
      );
    });

    test('localized fragments are used verbatim', () {
      expect(
        buildMessageSemanticLabel(
          senderName: 'A',
          hasSticker: true,
          stickerLabel: 'autocollant',
        ),
        'A. autocollant',
      );
    });

    test('only present metadata appears, in a stable order', () {
      expect(
        buildMessageSemanticLabel(senderName: 'A', body: 'x', isEdited: true),
        'A: x. edited',
      );
    });

    test('timestamp without body', () {
      expect(
        buildMessageSemanticLabel(senderName: 'A', timestamp: '9:00'),
        'A, 9:00',
      );
    });
  });
}

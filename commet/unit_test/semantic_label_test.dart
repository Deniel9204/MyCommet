import 'package:test/test.dart';
import 'package:tiamat/atoms/util/semantic_label.dart';

void main() {
  group('resolveButtonSemanticLabel', () {
    test('null stays null', () {
      expect(resolveButtonSemanticLabel(null), isNull);
    });

    test('empty becomes null', () {
      expect(resolveButtonSemanticLabel(''), isNull);
    });

    test('whitespace-only becomes null', () {
      expect(resolveButtonSemanticLabel('   '), isNull);
    });

    test('trims surrounding whitespace', () {
      expect(resolveButtonSemanticLabel('  Send  '), 'Send');
    });

    test('keeps a normal label', () {
      expect(resolveButtonSemanticLabel('Send message'), 'Send message');
    });
  });
}

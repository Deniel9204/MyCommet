import 'package:commet/client/components/account_switch_prefix/account_prefix.dart';
import 'package:test/test.dart';

void main() {
  group('normalizeAccountPrefix', () {
    test('preserves a meaningful trailing space (#875)', () {
      expect(normalizeAccountPrefix('alice '), 'alice ');
    });

    test('preserves a prefix without a trailing space', () {
      expect(normalizeAccountPrefix('alice'), 'alice');
    });

    test('preserves symbol prefixes', () {
      expect(normalizeAccountPrefix('/'), '/');
      expect(normalizeAccountPrefix('!! '), '!! ');
    });

    test('null clears the prefix', () {
      expect(normalizeAccountPrefix(null), isNull);
    });

    test('empty string clears the prefix', () {
      expect(normalizeAccountPrefix(''), isNull);
    });

    test('whitespace-only clears the prefix', () {
      expect(normalizeAccountPrefix('   '), isNull);
      expect(normalizeAccountPrefix('\t'), isNull);
    });
  });
}

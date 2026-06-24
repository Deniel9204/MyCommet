import 'package:commet/utils/redecrypt_message.dart';
import 'package:test/test.dart';

void main() {
  group('redecryptResultMessage', () {
    test('zero -> nothing to do', () {
      expect(redecryptResultMessage(0), "No messages needed re-decrypting");
    });

    test('negative is treated as zero', () {
      expect(redecryptResultMessage(-3), "No messages needed re-decrypting");
    });

    test('one is singular', () {
      expect(redecryptResultMessage(1), "Re-requesting keys for 1 message");
    });

    test('many is plural with the count', () {
      expect(redecryptResultMessage(5), "Re-requesting keys for 5 messages");
    });
  });
}

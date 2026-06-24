import 'package:commet/utils/decrypt_retry_plan.dart';
import 'package:test/test.dart';

EncryptedEventDescriptor d(
  String id, {
  bool undecryptable = true,
  bool canRequest = true,
  String? session = 's1',
  String? sender = 'k1',
}) =>
    (
      eventId: id,
      isUndecryptable: undecryptable,
      canRequestSession: canRequest,
      sessionId: session,
      senderKey: sender,
    );

void main() {
  group('planDecryptRetry', () {
    test('dedups many events of one session into a single request', () {
      final plan = planDecryptRetry([d('a'), d('b'), d('c')]);
      expect(plan.eventIdsToRefresh, ['a', 'b', 'c']);
      expect(plan.keysToRequest, [(sessionId: 's1', senderKey: 'k1')]);
    });

    test('ignores events that decrypted fine', () {
      final plan = planDecryptRetry([d('a', undecryptable: false)]);
      expect(plan.isEmpty, isTrue);
    });

    test('refreshes but does not request when not requestable', () {
      final plan = planDecryptRetry([d('a', canRequest: false)]);
      expect(plan.eventIdsToRefresh, ['a']);
      expect(plan.keysToRequest, isEmpty);
    });

    test('excludes a null sessionId from requests but still refreshes', () {
      final plan = planDecryptRetry([d('a', session: null)]);
      expect(plan.eventIdsToRefresh, ['a']);
      expect(plan.keysToRequest, isEmpty);
    });

    test('keeps distinct senderKeys for the same session separate', () {
      final plan = planDecryptRetry([d('a', sender: 'k1'), d('b', sender: 'k2')]);
      expect(plan.keysToRequest.length, 2);
    });

    test('deduplicates repeated event ids', () {
      final plan = planDecryptRetry([d('a'), d('a')]);
      expect(plan.eventIdsToRefresh, ['a']);
      expect(plan.keysToRequest.length, 1);
    });

    test('preserves input order of requests across sessions', () {
      final plan = planDecryptRetry([
        d('a', session: 's2', sender: 'k1'),
        d('b', session: 's1', sender: 'k1'),
      ]);
      expect(plan.keysToRequest, [
        (sessionId: 's2', senderKey: 'k1'),
        (sessionId: 's1', senderKey: 'k1'),
      ]);
    });

    test('empty input yields an empty plan', () {
      expect(planDecryptRetry(const []).isEmpty, isTrue);
    });

    test('a null senderKey is allowed and deduped as empty', () {
      final plan = planDecryptRetry([
        d('a', sender: null),
        d('b', sender: null),
      ]);
      expect(plan.keysToRequest, [(sessionId: 's1', senderKey: null)]);
    });
  });
}

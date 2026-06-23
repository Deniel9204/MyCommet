import 'package:commet/utils/draft_store.dart';
import 'package:test/test.dart';

void main() {
  group('DraftStore', () {
    test('stores and retrieves a draft per room', () {
      final d = DraftStore();
      d.setDraft('!a', 'hello');
      d.setDraft('!b', 'world');
      expect(d.getDraft('!a'), 'hello');
      expect(d.getDraft('!b'), 'world');
    });

    test('returns null for a room with no draft', () {
      expect(DraftStore().getDraft('!nope'), isNull);
    });

    test('overwrites an existing draft', () {
      final d = DraftStore();
      d.setDraft('!a', 'first');
      d.setDraft('!a', 'second');
      expect(d.getDraft('!a'), 'second');
    });

    test('empty or whitespace-only text clears the draft', () {
      final d = DraftStore({'!a': 'hello'});
      d.setDraft('!a', '');
      expect(d.getDraft('!a'), isNull);
      expect(d.hasDraft('!a'), isFalse);

      d.setDraft('!a', 'x');
      d.setDraft('!a', '   \n\t');
      expect(d.getDraft('!a'), isNull);
    });

    test('clearDraft removes the draft', () {
      final d = DraftStore({'!a': 'hello'});
      d.clearDraft('!a');
      expect(d.hasDraft('!a'), isFalse);
    });

    test('preserves a draft with meaningful leading/trailing content', () {
      final d = DraftStore();
      d.setDraft('!a', '  has content  ');
      expect(d.getDraft('!a'), '  has content  ');
    });
  });
}

import 'package:commet/utils/search_query.dart';
import 'package:test/test.dart';

void main() {
  group('SearchQuery.parse', () {
    test('plain words', () {
      final q = SearchQuery.parse('Hello World');
      expect(q.words, ['hello', 'world']);
      expect(q.requiredType, isNull);
      expect(q.requiredSender, isNull);
      expect(q.requireUrl, isFalse);
    });

    test('extracts type: and from: filters', () {
      final q = SearchQuery.parse('type:m.image from:@bob:server hello');
      expect(q.requiredType, 'm.image');
      expect(q.requiredSender, '@bob:server');
      // type: token is stripped from words; from: token is retained (matches
      // the original behaviour — sender filtering is handled separately).
      expect(q.words, contains('hello'));
      expect(q.words, isNot(contains('type:m.image')));
    });

    test('extracts has: flags and strips their tokens', () {
      final q = SearchQuery.parse('has:link has:image has:video has:file cat');
      expect(q.requireUrl, isTrue);
      expect(q.requireImage, isTrue);
      expect(q.requireVideo, isTrue);
      expect(q.requireAttachment, isTrue);
      expect(q.words, ['cat']);
    });
  });

  group('SearchQuery.matches', () {
    test('matches when enough words are present', () {
      final q = SearchQuery.parse('quick brown fox');
      expect(q.matches(plaintextBody: 'the quick brown dog'), isTrue); // 2/3
      expect(q.matches(plaintextBody: 'totally unrelated'), isFalse); // 0/3
    });

    test('filter-only query matches anything passing the filter', () {
      final q = SearchQuery.parse('has:link');
      expect(q.matches(plaintextBody: 'see https://example.com'), isTrue);
      expect(q.matches(plaintextBody: 'no link here'), isFalse);
    });

    test('type filter', () {
      final q = SearchQuery.parse('type:m.image');
      expect(q.matches(plaintextBody: '', type: 'm.image'), isTrue);
      expect(q.matches(plaintextBody: '', messageType: 'm.image'), isTrue);
      expect(q.matches(plaintextBody: '', type: 'm.text'), isFalse);
    });

    test('from filter', () {
      final q = SearchQuery.parse('from:@alice:server hello');
      expect(q.matches(plaintextBody: 'hello there', senderId: '@alice:server'),
          isTrue);
      expect(q.matches(plaintextBody: 'hello there', senderId: '@bob:server'),
          isFalse);
    });

    test('has:image requires an image attachment', () {
      final q = SearchQuery.parse('has:image');
      expect(q.matches(plaintextBody: '', isImageAttachment: true), isTrue);
      expect(q.matches(plaintextBody: '', isImageAttachment: false), isFalse);
    });
  });
}

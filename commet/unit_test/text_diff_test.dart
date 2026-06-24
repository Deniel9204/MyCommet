import 'package:commet/utils/text_diff.dart';
import 'package:test/test.dart';

void main() {
  group('diffWords', () {
    test('identical text is all equal', () {
      expect(diffWords('hello world', 'hello world'),
          [const DiffSegment(DiffOp.equal, 'hello world')]);
    });

    test('pure insertion', () {
      expect(diffWords('hello', 'hello world'), [
        const DiffSegment(DiffOp.equal, 'hello'),
        const DiffSegment(DiffOp.insert, 'world'),
      ]);
    });

    test('pure deletion', () {
      expect(diffWords('hello world', 'hello'), [
        const DiffSegment(DiffOp.equal, 'hello'),
        const DiffSegment(DiffOp.delete, 'world'),
      ]);
    });

    test('word replacement', () {
      expect(diffWords('the quick brown fox', 'the slow brown fox'), [
        const DiffSegment(DiffOp.equal, 'the'),
        const DiffSegment(DiffOp.delete, 'quick'),
        const DiffSegment(DiffOp.insert, 'slow'),
        const DiffSegment(DiffOp.equal, 'brown fox'),
      ]);
    });

    test('insertion at the start', () {
      expect(diffWords('world', 'hello world'), [
        const DiffSegment(DiffOp.insert, 'hello'),
        const DiffSegment(DiffOp.equal, 'world'),
      ]);
    });
  });
}

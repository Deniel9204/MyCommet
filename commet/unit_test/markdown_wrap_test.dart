import 'package:commet/utils/markdown_wrap.dart';
import 'package:test/test.dart';

void main() {
  group('wrapSelection', () {
    test('wraps a selection with bold', () {
      expect(wrapSelection('hello', 0, 5, '**'),
          const MarkdownWrapResult('**hello**', 2, 7));
    });

    test('wraps a sub-selection and keeps the same characters selected', () {
      // "a bcd e", select "bcd" [2,5]
      expect(wrapSelection('a bcd e', 2, 5, '_'),
          const MarkdownWrapResult('a _bcd_ e', 3, 6));
    });

    test('empty selection inserts markers with cursor between them', () {
      expect(wrapSelection('abcd', 2, 2, '**'),
          const MarkdownWrapResult('ab****cd', 4, 4));
    });

    test('normalizes a reversed selection', () {
      expect(wrapSelection('hello', 5, 0, '`'),
          const MarkdownWrapResult('`hello`', 1, 6));
    });

    test('unwraps when markers sit just outside the selection', () {
      // "**hello**", select inner "hello" [2,7]
      expect(wrapSelection('**hello**', 2, 7, '**'),
          const MarkdownWrapResult('hello', 0, 5));
    });

    test('unwraps when the selection itself includes the markers', () {
      // select the whole "**hello**" [0,9]
      expect(wrapSelection('**hello**', 0, 9, '**'),
          const MarkdownWrapResult('hello', 0, 5));
    });

    test('code marker', () {
      expect(wrapSelection('x = 1', 0, 5, '`'),
          const MarkdownWrapResult('`x = 1`', 1, 6));
    });

    test('clamps out-of-range offsets', () {
      expect(wrapSelection('hi', 0, 99, '_'),
          const MarkdownWrapResult('_hi_', 1, 3));
    });
  });
}

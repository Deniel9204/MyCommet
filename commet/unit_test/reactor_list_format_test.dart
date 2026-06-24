import 'package:commet/utils/reactor_list_format.dart';
import 'package:test/test.dart';

void main() {
  group('formatReactorNames', () {
    test('empty', () => expect(formatReactorNames([]), ''));
    test('one', () => expect(formatReactorNames(['Alice']), 'Alice'));
    test('two',
        () => expect(formatReactorNames(['Alice', 'Bob']), 'Alice and Bob'));
    test('three', () {
      expect(formatReactorNames(['Alice', 'Bob', 'Carol']),
          'Alice, Bob and Carol');
    });
    test('four collapses to one other', () {
      expect(formatReactorNames(['Alice', 'Bob', 'Carol', 'Dave']),
          'Alice, Bob, Carol and 1 other');
    });
    test('five collapses to N others', () {
      expect(formatReactorNames(['A', 'B', 'C', 'D', 'E']),
          'A, B, C and 2 others');
    });
  });
}

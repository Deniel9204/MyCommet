import 'package:commet/utils/search_result_merge.dart';
import 'package:test/test.dart';

class _R {
  final String id;
  final int ts;
  _R(this.id, this.ts);
}

void main() {
  group('mergeSearchResults', () {
    test('flattens and sorts by sortKey descending', () {
      final merged = mergeSearchResults<_R>(
        [
          [_R('a', 10), _R('b', 30)],
          [_R('c', 20)],
        ],
        idOf: (r) => r.id,
        sortKey: (r) => r.ts,
      );
      expect(merged.map((r) => r.id), ['b', 'c', 'a']);
    });

    test('de-duplicates by id (first occurrence wins)', () {
      final first = _R('dup', 100);
      final second = _R('dup', 999);
      final merged = mergeSearchResults<_R>(
        [
          [first],
          [second, _R('other', 50)],
        ],
        idOf: (r) => r.id,
        sortKey: (r) => r.ts,
      );
      expect(merged.length, 2);
      expect(identical(merged.firstWhere((r) => r.id == 'dup'), first), isTrue);
    });

    test('empty input yields empty list', () {
      expect(
        mergeSearchResults<_R>([], idOf: (r) => r.id, sortKey: (r) => r.ts),
        isEmpty,
      );
      expect(
        mergeSearchResults<_R>([[], []],
            idOf: (r) => r.id, sortKey: (r) => r.ts),
        isEmpty,
      );
    });
  });
}

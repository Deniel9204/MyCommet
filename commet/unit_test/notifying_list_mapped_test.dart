import 'package:commet/utils/notifying_list.dart';
import 'package:commet/utils/notifying_list_mapped.dart';
import 'package:test/test.dart';

void main() {
  late NotifyingList<int> base;
  late NotifyingListMapped<int, int> mapped;
  late List<int> added;
  late List<int> removed;

  setUp(() {
    base = NotifyingList<int>.from([1, 2], growable: true);
    mapped =
        NotifyingListMapped<int, int>(baseList: base, map: (x) => [x, x * 10]);
    added = [];
    removed = [];
    mapped.onAdd.listen(added.add);
    mapped.onRemove.listen(removed.add);
  });

  test('initial mapping flat-maps each base item', () {
    expect(mapped.toList(), [1, 10, 2, 20]);
    expect(mapped.length, 4);
  });

  test('adding a base item adds its mapped items', () {
    base.add(3);
    expect(mapped.toList(), [1, 10, 2, 20, 3, 30]);
    expect(added, [3, 30]);
  });

  test('removing a base item removes its mapped items', () {
    base.remove(1);
    expect(mapped.toList(), [2, 20]);
    expect(removed, [1, 10]);
  });

  test('indexing reflects the mapped view', () {
    expect(mapped[0], 1);
    expect(mapped[1], 10);
    expect(mapped.contains(20), isTrue);
  });
}

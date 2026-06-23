import 'package:commet/utils/notifying_list.dart';
import 'package:commet/utils/notifying_list_filter.dart';
import 'package:test/test.dart';

void main() {
  late NotifyingList<int> base;
  late NotifyingListFilter<int> filtered;
  late List<int> added;
  late List<int> removed;

  setUp(() {
    base = NotifyingList<int>.from([1, 2, 3, 4], growable: true);
    filtered = NotifyingListFilter<int>(base, where: (x) => x.isEven);
    added = [];
    removed = [];
    filtered.onAdd.listen(added.add);
    filtered.onRemove.listen(removed.add);
  });

  test('initial filter keeps only matching items', () {
    expect(filtered.toList(), [2, 4]);
    expect(filtered.length, 2);
  });

  test('adding a matching item to base propagates to the filter', () {
    base.add(6);
    expect(filtered.toList(), [2, 4, 6]);
    expect(added, [6]);
  });

  test('adding a non-matching item to base is ignored', () {
    base.add(5);
    expect(filtered.toList(), [2, 4]);
    expect(added, isEmpty);
  });

  test('removing a matching item from base removes it from the filter', () {
    base.remove(2);
    expect(filtered.toList(), [4]);
    expect(removed, [2]);
  });

  test('removing a non-matching item from base does not affect the filter', () {
    base.remove(1);
    expect(filtered.toList(), [2, 4]);
    expect(removed, isEmpty);
  });

  test('contains / indexOf reflect the filtered view', () {
    expect(filtered.contains(2), isTrue);
    expect(filtered.contains(1), isFalse);
    expect(filtered.indexOf(4), 1);
  });

  test('unsubscribe stops reacting to base changes', () {
    filtered.unsubscribe();
    base.add(8);
    expect(filtered.toList(), [2, 4]);
  });
}

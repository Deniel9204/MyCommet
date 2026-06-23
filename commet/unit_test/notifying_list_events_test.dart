import 'package:commet/utils/notifying_list.dart';
import 'package:test/test.dart';

void main() {
  // Streams are synchronous by default, so events are collected eagerly.
  late NotifyingList<String> list;
  late List<String> added;
  late List<String> removed;
  late List<String> updated;
  late int listUpdates;

  void wire(NotifyingList<String> l) {
    list = l;
    added = [];
    removed = [];
    updated = [];
    listUpdates = 0;
    list.onAdd.listen(added.add);
    list.onRemove.listen(removed.add);
    list.onItemUpdated.listen(updated.add);
    list.onListUpdated.listen((_) => listUpdates++);
  }

  group('basic list semantics', () {
    setUp(() =>
        wire(NotifyingList<String>.from(['a', 'b', 'c'], growable: true)));

    test('length / indexing / contains', () {
      expect(list.length, 3);
      expect(list[1], 'b');
      expect(list.contains('c'), isTrue);
      expect(list.indexOf('b'), 1);
      expect(list.toList(), ['a', 'b', 'c']);
    });
  });

  group('add paths emit the correct elements on onAdd', () {
    setUp(() =>
        wire(NotifyingList<String>.from(['a', 'b', 'c'], growable: true)));

    test('add', () {
      list.add('d');
      expect(list.toList(), ['a', 'b', 'c', 'd']);
      expect(added, ['d']);
      expect(listUpdates, 1);
    });

    test('addAll', () {
      list.addAll(['d', 'e']);
      expect(list.toList(), ['a', 'b', 'c', 'd', 'e']);
      expect(added, ['d', 'e']);
    });

    test('insert', () {
      list.insert(1, 'z');
      expect(list.toList(), ['a', 'z', 'b', 'c']);
      expect(added, ['z']);
    });

    test('insertAll emits the actually-inserted elements', () {
      list.insertAll(0, ['x', 'y']);
      expect(list.toList(), ['x', 'y', 'a', 'b', 'c']);
      expect(added, ['x', 'y']);
    });
  });

  group('remove paths emit the correct elements on onRemove', () {
    setUp(() =>
        wire(NotifyingList<String>.from(['a', 'b', 'c', 'd'], growable: true)));

    test('remove', () {
      expect(list.remove('b'), isTrue);
      expect(list.toList(), ['a', 'c', 'd']);
      expect(removed, ['b']);
    });

    test('removeAt / removeLast', () {
      expect(list.removeAt(0), 'a');
      expect(list.removeLast(), 'd');
      expect(list.toList(), ['b', 'c']);
      expect(removed, ['a', 'd']);
    });

    test('removeRange emits the actually-removed elements', () {
      list.removeRange(1, 3); // removes b, c
      expect(list.toList(), ['a', 'd']);
      expect(removed, ['b', 'c']);
    });

    test('removeWhere', () {
      list.removeWhere((e) => e == 'a' || e == 'c');
      expect(list.toList(), ['b', 'd']);
      expect(removed, ['a', 'c']);
    });

    test('clear emits onRemove for every element', () {
      list.clear();
      expect(list.toList(), isEmpty);
      expect(removed, ['a', 'b', 'c', 'd']);
    });
  });

  group('update paths emit onItemUpdated', () {
    setUp(() =>
        wire(NotifyingList<String>.from(['a', 'b', 'c'], growable: true)));

    test('index assignment', () {
      list[1] = 'B';
      expect(list.toList(), ['a', 'B', 'c']);
      expect(updated, ['B']);
    });
  });
}

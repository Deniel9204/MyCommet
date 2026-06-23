import 'package:commet/utils/in_memory_cache.dart';
import 'package:test/test.dart';

void main() {
  group('InMemoryCache', () {
    test('stores and retrieves values', () {
      final c = InMemoryCache<int>(limit: 5);
      c.put('a', 1);
      expect(c.get('a'), 1);
      expect(c.get('missing'), isNull);
    });

    test('enforces the size limit by evicting the oldest entry', () {
      final c = InMemoryCache<int>(limit: 3);
      c.put('a', 1);
      c.put('b', 2);
      c.put('c', 3);
      expect(c.get('a'), 1);

      c.put('d', 4); // over limit -> evict 'a'
      expect(c.get('a'), isNull);
      expect(c.get('b'), 2);
      expect(c.get('d'), 4);
    });

    test('re-putting a key refreshes its position', () {
      final c = InMemoryCache<int>(limit: 3);
      c.put('a', 1);
      c.put('b', 2);
      c.put('c', 3);
      c.put('a', 10); // refresh 'a' -> order is now b, c, a
      c.put('d', 4); // evict the now-oldest 'b'
      expect(c.get('b'), isNull);
      expect(c.get('a'), 10);
      expect(c.get('d'), 4);
    });

    test('emits removed keys on onRemove when evicting', () async {
      final c = InMemoryCache<int>(limit: 1);
      final removed = <String>[];
      c.onRemove.listen(removed.add);
      c.put('a', 1);
      c.put('b', 2); // evicts 'a'
      await Future<void>.delayed(Duration.zero);
      expect(removed, contains('a'));
    });
  });
}

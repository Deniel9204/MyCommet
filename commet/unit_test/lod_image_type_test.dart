import 'package:commet/utils/image/lod_image_type.dart';
import 'package:test/test.dart';

void main() {
  group('LODImageType ordering', () {
    test('quality increases blurhash < thumbnail < fullres', () {
      expect(
          LODImageType.blurhash.index, lessThan(LODImageType.thumbnail.index));
      expect(
          LODImageType.thumbnail.index, lessThan(LODImageType.fullres.index));
    });
  });

  group('isHigherLod', () {
    test('any level upgrades from nothing shown yet', () {
      for (final t in LODImageType.values) {
        expect(isHigherLod(t, null), isTrue);
      }
    });

    test('full-res upgrades thumbnail and blurhash', () {
      expect(isHigherLod(LODImageType.fullres, LODImageType.thumbnail), isTrue);
      expect(isHigherLod(LODImageType.fullres, LODImageType.blurhash), isTrue);
    });

    test('thumbnail upgrades blurhash but not full-res', () {
      expect(
          isHigherLod(LODImageType.thumbnail, LODImageType.blurhash), isTrue);
      expect(
          isHigherLod(LODImageType.thumbnail, LODImageType.fullres), isFalse);
    });

    test('blurhash never overwrites a higher level', () {
      expect(
          isHigherLod(LODImageType.blurhash, LODImageType.thumbnail), isFalse);
      expect(isHigherLod(LODImageType.blurhash, LODImageType.fullres), isFalse);
    });

    test('the same level is not an upgrade (no redundant re-decode)', () {
      for (final t in LODImageType.values) {
        expect(isHigherLod(t, t), isFalse);
      }
    });
  });
}

import 'package:commet/utils/file_size_format.dart';
import 'package:test/test.dart';

void main() {
  group('formatFileSize (base 1024)', () {
    test('bytes', () {
      expect(formatFileSize(0), '0 B');
      expect(formatFileSize(512), '512 B');
    });

    test('exact units trim the fractional part', () {
      expect(formatFileSize(1024), '1 KB');
      expect(formatFileSize(1048576), '1 MB');
      expect(formatFileSize(1073741824), '1 GB');
    });

    test('fractional sizes keep two decimals', () {
      expect(formatFileSize(1536), '1.50 KB');
    });
  });

  group('formatFileSize (base 1000) — proves the base1024 param works', () {
    test('1000 bytes is 1 KB in base 1000', () {
      expect(formatFileSize(1000, base1024: false), '1 KB');
    });

    test('1024 bytes differs by base', () {
      // The whole point of the fix: this previously returned "1 KB"
      // regardless of base because the parameter was ignored.
      expect(formatFileSize(1024, base1024: true), '1 KB');
      expect(formatFileSize(1024, base1024: false), '1.02 KB');
    });

    test('1500 bytes base 1000', () {
      expect(formatFileSize(1500, base1024: false), '1.50 KB');
    });
  });
}

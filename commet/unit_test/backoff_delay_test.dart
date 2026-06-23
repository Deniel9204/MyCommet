import 'package:commet/utils/backoff_delay.dart';
import 'package:test/test.dart';

void main() {
  group('nextBackoffDelay', () {
    const max = Duration(seconds: 30);

    test('doubles while under the cap', () {
      expect(nextBackoffDelay(const Duration(milliseconds: 500), max),
          const Duration(seconds: 1));
      expect(nextBackoffDelay(const Duration(seconds: 8), max),
          const Duration(seconds: 16));
    });

    test('caps at maxDelay instead of overshooting', () {
      // 16s * 2 = 32s -> capped to 30s
      expect(nextBackoffDelay(const Duration(seconds: 16), max), max);
    });

    test('never exceeds maxDelay once at the cap (the bug being fixed)', () {
      // Previously 30s would double to 60s and the caller waited 60s.
      expect(nextBackoffDelay(max, max), max);
    });
  });
}

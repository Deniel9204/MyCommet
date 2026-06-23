import 'package:commet/utils/duration_format.dart';
import 'package:test/test.dart';

void main() {
  group('durationToShortString', () {
    test('under a minute shows seconds with an s suffix', () {
      expect(durationToShortString(const Duration(seconds: 5)), '5s');
      expect(durationToShortString(const Duration(seconds: 59)), '59s');
      expect(durationToShortString(Duration.zero), '0s');
    });

    test('zero-pads seconds in m:ss', () {
      expect(durationToShortString(const Duration(minutes: 2, seconds: 5)),
          '2:05');
      expect(durationToShortString(const Duration(minutes: 10)), '10:00');
      expect(durationToShortString(const Duration(minutes: 1, seconds: 59)),
          '1:59');
    });

    test('zero-pads minutes and seconds in h:mm:ss', () {
      expect(
          durationToShortString(
              const Duration(hours: 1, minutes: 2, seconds: 5)),
          '1:02:05');
      expect(durationToShortString(const Duration(hours: 2)), '2:00:00');
      expect(
          durationToShortString(
              const Duration(hours: 1, minutes: 59, seconds: 59)),
          '1:59:59');
    });
  });
}

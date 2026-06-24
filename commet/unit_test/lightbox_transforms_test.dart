import 'package:commet/utils/lightbox_transforms.dart';
import 'package:test/test.dart';

void main() {
  group('nextQuarterTurn', () {
    test('advances by one quarter turn', () {
      expect(nextQuarterTurn(0), 1);
      expect(nextQuarterTurn(1), 2);
      expect(nextQuarterTurn(2), 3);
    });

    test('wraps from 3 back to 0', () {
      expect(nextQuarterTurn(3), 0);
    });

    test('four advances return to the start', () {
      var turns = 0;
      for (var i = 0; i < 4; i++) {
        turns = nextQuarterTurn(turns);
      }
      expect(turns, 0);
    });
  });
}

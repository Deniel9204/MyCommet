import 'package:commet/utils/formatting_shortcut.dart';
import 'package:test/test.dart';

void main() {
  group('markerForFormattingShortcut', () {
    test('bold / italic / code mappings (case-insensitive)', () {
      expect(markerForFormattingShortcut('b'), '**');
      expect(markerForFormattingShortcut('B'), '**');
      expect(markerForFormattingShortcut('i'), '_');
      expect(markerForFormattingShortcut('e'), '`');
    });

    test('non-formatting keys return null', () {
      expect(markerForFormattingShortcut('a'), isNull);
      expect(markerForFormattingShortcut('v'), isNull); // paste, not formatting
      expect(markerForFormattingShortcut(''), isNull);
      expect(markerForFormattingShortcut('Control'), isNull);
    });
  });
}

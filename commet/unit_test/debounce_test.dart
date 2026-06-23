import 'package:commet/utils/debounce.dart';
import 'package:test/test.dart';

void main() {
  group('Debouncer', () {
    test('runs the action after the delay', () async {
      final d = Debouncer(delay: const Duration(milliseconds: 30));
      var ran = false;
      d.run(() => ran = true);
      expect(ran, isFalse);
      await Future<void>.delayed(const Duration(milliseconds: 60));
      expect(ran, isTrue);
    });

    test('running is true during the delay and false after it fires', () async {
      final d = Debouncer(delay: const Duration(milliseconds: 30));
      d.run(() {});
      expect(d.running, isTrue);
      await Future<void>.delayed(const Duration(milliseconds: 60));
      expect(d.running, isFalse);
    });

    test('a second run cancels the first pending action', () async {
      final d = Debouncer(delay: const Duration(milliseconds: 30));
      var count = 0;
      d.run(() => count++);
      d.run(() => count++);
      await Future<void>.delayed(const Duration(milliseconds: 60));
      expect(count, 1);
    });

    test('cancel stops a pending action and clears running', () async {
      final d = Debouncer(delay: const Duration(milliseconds: 30));
      var ran = false;
      d.run(() => ran = true);
      d.cancel();
      expect(d.running, isFalse);
      await Future<void>.delayed(const Duration(milliseconds: 60));
      expect(ran, isFalse);
    });
  });
}

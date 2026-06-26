import 'package:commet/utils/homeserver_input.dart';
import 'package:test/test.dart';

void main() {
  group('homeserverUriFromInput', () {
    test('a bare host defaults to https', () {
      expect(homeserverUriFromInput('matrix.org').toString(),
          'https://matrix.org');
    });

    test('preserves an explicit https scheme', () {
      expect(homeserverUriFromInput('https://matrix.org').toString(),
          'https://matrix.org');
    });

    test('preserves an explicit http scheme (local servers)', () {
      expect(homeserverUriFromInput('http://localhost').toString(),
          'http://localhost');
    });

    test('a scheme + host no longer throws (the old FormatException)', () {
      // Uri.https('http://localhost') used to throw because '//localhost' was
      // parsed as a port.
      expect(() => homeserverUriFromInput('http://localhost'), returnsNormally);
      expect(
          () => homeserverUriFromInput('https://matrix.org'), returnsNormally);
    });

    test('keeps an explicit port', () {
      expect(homeserverUriFromInput('http://localhost:8008').toString(),
          'http://localhost:8008');
      expect(homeserverUriFromInput('localhost:8008').toString(),
          'https://localhost:8008');
    });

    test('trims whitespace and trailing slashes', () {
      expect(homeserverUriFromInput('  matrix.org/  ').toString(),
          'https://matrix.org');
      expect(homeserverUriFromInput('https://matrix.org//').toString(),
          'https://matrix.org');
    });
  });
}

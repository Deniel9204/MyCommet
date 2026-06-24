import 'package:commet/utils/matrix_permalink.dart';
import 'package:test/test.dart';

void main() {
  group('buildMatrixToLink', () {
    test('room only', () {
      expect(
        buildMatrixToLink(roomId: '!abc:example.org'),
        'https://matrix.to/#/!abc:example.org',
      );
    });

    test('room + event', () {
      expect(
        buildMatrixToLink(roomId: '!abc:example.org', eventId: r'$evt'),
        'https://matrix.to/#/!abc:example.org/\$evt',
      );
    });

    test('with via servers', () {
      expect(
        buildMatrixToLink(
          roomId: '!abc:example.org',
          eventId: r'$evt',
          via: ['example.org', 'other.net'],
        ),
        'https://matrix.to/#/!abc:example.org/\$evt?via=example.org&via=other.net',
      );
    });

    test('empty eventId is ignored', () {
      expect(
        buildMatrixToLink(roomId: '!abc:example.org', eventId: ''),
        'https://matrix.to/#/!abc:example.org',
      );
    });
  });

  group('serverNameFromMatrixId', () {
    test('extracts the server', () {
      expect(serverNameFromMatrixId('!abc:example.org'), 'example.org');
      expect(serverNameFromMatrixId('@user:matrix.org'), 'matrix.org');
    });

    test('null when no server part', () {
      expect(serverNameFromMatrixId(r'$eventid'), isNull);
      expect(serverNameFromMatrixId('!trailing:'), isNull);
    });
  });
}

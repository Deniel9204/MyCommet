import 'package:commet/utils/room_shortcut_image.dart';
import 'package:test/test.dart';

void main() {
  group('resolveRoomShortcutImage', () {
    test('uses the room avatar when present', () async {
      final result = await resolveRoomShortcutImage<String>(
        roomAvatar: 'room',
        isDirectMessage: false,
        directMessagePartnerAvatar: () => 'partner',
        spaceAvatar: () => 'space',
      );

      expect(result, 'room');
    });

    test('does not fetch fallbacks when the room avatar is present', () async {
      var partnerCalled = false;
      var spaceCalled = false;

      final result = await resolveRoomShortcutImage<String>(
        roomAvatar: 'room',
        isDirectMessage: true,
        directMessagePartnerAvatar: () {
          partnerCalled = true;
          return 'partner';
        },
        spaceAvatar: () {
          spaceCalled = true;
          return 'space';
        },
      );

      expect(result, 'room');
      expect(partnerCalled, isFalse);
      expect(spaceCalled, isFalse);
    });

    test('falls back to the DM partner avatar for a direct message', () async {
      final result = await resolveRoomShortcutImage<String>(
        roomAvatar: null,
        isDirectMessage: true,
        directMessagePartnerAvatar: () async => 'partner',
        spaceAvatar: () => 'space',
      );

      expect(result, 'partner');
    });

    test('skips the DM partner avatar when not a direct message', () async {
      var partnerCalled = false;

      final result = await resolveRoomShortcutImage<String>(
        roomAvatar: null,
        isDirectMessage: false,
        directMessagePartnerAvatar: () {
          partnerCalled = true;
          return 'partner';
        },
        spaceAvatar: () => 'space',
      );

      expect(result, 'space');
      expect(partnerCalled, isFalse);
    });

    test('falls back to the space avatar when the DM partner has none',
        () async {
      final result = await resolveRoomShortcutImage<String>(
        roomAvatar: null,
        isDirectMessage: true,
        directMessagePartnerAvatar: () async => null,
        spaceAvatar: () => 'space',
      );

      expect(result, 'space');
    });

    test('returns null when no source has an image', () async {
      final result = await resolveRoomShortcutImage<String>(
        roomAvatar: null,
        isDirectMessage: true,
        directMessagePartnerAvatar: () async => null,
        spaceAvatar: () async => null,
      );

      expect(result, isNull);
    });
  });
}

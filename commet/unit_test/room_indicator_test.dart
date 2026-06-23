import 'package:commet/utils/room_indicator.dart';
import 'package:test/test.dart';

void main() {
  group('resolveRoomBadge', () {
    test('no notifications and read -> none', () {
      expect(
        resolveRoomBadge(notificationCount: 0, hasUnread: false),
        RoomBadgeStyle.none,
      );
    });

    test('unread with no notifications -> unread', () {
      expect(
        resolveRoomBadge(notificationCount: 0, hasUnread: true),
        RoomBadgeStyle.unread,
      );
    });

    test('notifications -> notification', () {
      expect(
        resolveRoomBadge(notificationCount: 3, hasUnread: false),
        RoomBadgeStyle.notification,
      );
    });

    test('notifications take precedence over unread', () {
      expect(
        resolveRoomBadge(notificationCount: 1, hasUnread: true),
        RoomBadgeStyle.notification,
      );
    });
  });
}

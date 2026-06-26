import 'package:commet/main.dart';

class NotificationUtils {
  static (int, int) getNotificationCounts() {
    var highlightedNotificationCount = 0;
    var notificationCount = 0;

    var topLevelSpaces =
        clientManager!.spaces.where((e) => e.isTopLevel).toList();

    for (var i in topLevelSpaces) {
      highlightedNotificationCount += i.displayHighlightedNotificationCount;
      notificationCount += i.displayNotificationCount;
    }

    for (var dm in clientManager!.directMessages.highlightedRoomsList) {
      highlightedNotificationCount += dm.displayHighlightedNotificationCount;
      notificationCount += dm.displayNotificationCount;
    }

    // Rooms that aren't in a space (and aren't DMs) are counted by neither loop
    // above, so unread messages in them never reached the taskbar/dock badge
    // (#13). Include them too.
    for (var room in clientManager!.singleRooms()) {
      highlightedNotificationCount += room.displayHighlightedNotificationCount;
      notificationCount += room.displayNotificationCount;
    }

    return (highlightedNotificationCount, notificationCount);
  }
}

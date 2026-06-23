/// Visual indicator to show next to a room in the room list.
///
/// A room with notifications shows a prominent [notification] dot (unchanged
/// behaviour). A room that has no notifications but still has unread content
/// shows a subtler [unread] dot, so muted / marked-unread rooms remain
/// distinguishable from fully-read ones without screaming for attention.
enum RoomBadgeStyle { none, unread, notification }

/// Decides which indicator (if any) a room should show.
///
/// Notifications take precedence over the plain unread state, so a room that
/// both notifies and is unread shows the notification dot.
RoomBadgeStyle resolveRoomBadge({
  required int notificationCount,
  required bool hasUnread,
}) {
  if (notificationCount > 0) return RoomBadgeStyle.notification;
  if (hasUnread) return RoomBadgeStyle.unread;
  return RoomBadgeStyle.none;
}

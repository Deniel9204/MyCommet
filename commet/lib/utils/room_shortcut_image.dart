import 'dart:async';

/// Resolves which image to use as a room's "shortcut" / notification icon.
///
/// The priority is: the room's own avatar, then — for a direct message — the
/// conversation partner's avatar, then the avatar of a containing space.
/// Returns `null` when no source has an image.
///
/// This is shared between the foreground room and the headless background room
/// so the in-app room list and background push notifications resolve the same
/// icon instead of one of them falling back to a blank/default avatar (#945).
/// The fallback closures are only invoked when the preceding source came up
/// empty, so a partner-profile fetch or space lookup is skipped whenever the
/// room already has its own avatar.
Future<T?> resolveRoomShortcutImage<T extends Object>({
  required T? roomAvatar,
  required bool isDirectMessage,
  required FutureOr<T?> Function() directMessagePartnerAvatar,
  required FutureOr<T?> Function() spaceAvatar,
}) async {
  if (roomAvatar != null) return roomAvatar;

  if (isDirectMessage) {
    final partner = await directMessagePartnerAvatar();
    if (partner != null) return partner;
  }

  return await spaceAvatar();
}

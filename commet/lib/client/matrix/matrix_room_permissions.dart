import 'package:matrix/matrix.dart' as matrix;

import '../permissions.dart';

class MatrixRoomPermissions extends Permissions {
  late matrix.Room room;

  MatrixRoomPermissions(this.room);

  // The matrix SDK's power-level checks (`ownPowerLevel`) do `client.userID!`
  // and throw when there is no logged-in user — e.g. a client that isn't logged
  // in, like the timeline render benchmark. An unidentified user has no
  // permissions, so treat "no user" as "not allowed" rather than crashing.
  bool get _loggedIn => room.client.userID != null;

  @override
  bool get canBan => _loggedIn && room.canBan;

  @override
  bool get canKick => _loggedIn && room.canKick;

  @override
  bool get canSendMessage => _loggedIn && room.canSendDefaultMessages;

  @override
  bool get canEditAvatar =>
      _loggedIn && room.canChangeStateEvent("m.room.avatar");

  @override
  bool get canEditName => _loggedIn && room.canChangeStateEvent("m.room.name");

  @override
  bool get canEditTopic =>
      _loggedIn && room.canChangeStateEvent(matrix.EventTypes.RoomTopic);

  @override
  bool get canEnableE2EE =>
      _loggedIn && room.canChangeStateEvent("m.room.encryption");

  @override
  bool get canEditRoomEmoticons => _loggedIn && room.canSendDefaultStates;

  @override
  bool get canDeleteOtherUserMessages => _loggedIn && room.canRedact;

  @override
  bool get canEditChildren =>
      _loggedIn && room.canChangeStateEvent(matrix.EventTypes.SpaceChild);

  @override
  bool get canInviteUser => _loggedIn && room.canInvite;

  @override
  bool get canChangeRoles => _loggedIn && room.canChangePowerLevel;

  @override
  bool get canMentionRoom =>
      _loggedIn && canUserMentionRoom(room.client.userID!, room);

  static bool canUserMentionRoom(String user, matrix.Room room) {
    int powerLevel = 50;

    var data = room
        .getState(matrix.EventTypes.RoomPowerLevels)
        ?.content
        .tryGetMap<String, int>('notifications');

    if (data != null) {
      var level = data["room"];

      if (level != null) powerLevel = level;
    }

    return room.getPowerLevelByUserId(user) >= powerLevel;
  }

  @override
  bool get canChangeVisibility =>
      _loggedIn && room.canChangeStateEvent(matrix.EventTypes.RoomJoinRules);
}

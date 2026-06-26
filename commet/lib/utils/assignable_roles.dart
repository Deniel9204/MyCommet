/// Returns the role power levels from [roleLevels] that a user with
/// [ownPowerLevel] is allowed to assign to someone else — i.e. levels at or
/// below their own.
///
/// Matrix forbids granting a power level higher than your own, so offering such
/// roles in the picker only leads to a rejected request (#18). Order is
/// preserved.
List<int> assignableRoleLevels(Iterable<int> roleLevels, int ownPowerLevel) {
  return roleLevels.where((level) => level <= ownPowerLevel).toList();
}

/// Returns the role power levels to offer in the role picker for a room, given
/// its [roomVersion], the current user's [ownPowerLevel] and whether the room
/// [hasCalendar].
///
/// The Owner (150) tier only exists in room version 12+, where the room
/// creator has an effectively infinite power level and is the only one able to
/// grant it; it is omitted for older rooms (#18). The Calendar Moderator (25)
/// tier is only relevant to calendar rooms. Levels above [ownPowerLevel] are
/// then dropped via [assignableRoleLevels] because the homeserver rejects
/// granting a power level higher than your own. Order is highest-to-lowest.
List<int> availableRoleLevels(
  int? roomVersion,
  int ownPowerLevel, {
  bool hasCalendar = false,
}) {
  final levels = <int>[
    if (roomVersion != null && roomVersion >= 12) 150,
    100,
    50,
    if (hasCalendar) 25,
    0,
  ];

  return assignableRoleLevels(levels, ownPowerLevel);
}

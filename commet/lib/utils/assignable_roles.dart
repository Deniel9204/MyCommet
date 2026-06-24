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

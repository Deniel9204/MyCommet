/// A single power-level change to apply to an `m.room.power_levels` content
/// map: set `content[key]` (or `content[parent][key]` when [parent] is set,
/// e.g. the `events` / `notifications` sub-maps) to [powerLevel].
typedef PowerLevelChange = ({String key, String? parent, int powerLevel});

/// Returns a deep copy of [base] with [changes] applied.
///
/// The copy is deep so callers never mutate the cached state event in place:
/// the change may still be rejected by the server, in which case the local
/// state must stay exactly as it was. Sub-maps are recreated rather than
/// shared with [base].
Map<String, dynamic> applyPowerLevelChanges(
  Map<String, dynamic> base,
  Iterable<PowerLevelChange> changes,
) {
  final content = _deepCopy(base);

  for (final change in changes) {
    final parent = change.parent;
    if (parent == null) {
      content[change.key] = change.powerLevel;
      continue;
    }

    final existing = content[parent];
    final parentMap = existing is Map
        ? Map<String, dynamic>.from(existing)
        : <String, dynamic>{};
    parentMap[change.key] = change.powerLevel;
    content[parent] = parentMap;
  }

  return content;
}

Map<String, dynamic> _deepCopy(Map<String, dynamic> src) {
  final out = <String, dynamic>{};
  src.forEach((key, value) {
    out[key] =
        value is Map ? _deepCopy(Map<String, dynamic>.from(value)) : value;
  });
  return out;
}

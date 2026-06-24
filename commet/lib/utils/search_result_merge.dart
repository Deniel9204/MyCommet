/// Merges per-room search result lists into a single list for global
/// (cross-room) search: de-duplicates by [idOf] (first occurrence wins) and
/// sorts by [sortKey] descending (most recent first).
///
/// Pure and generic so the merge behaviour can be unit tested independently of
/// the Matrix event types.
List<T> mergeSearchResults<T>(
  Iterable<List<T>> perRoomResults, {
  required String Function(T item) idOf,
  required int Function(T item) sortKey,
}) {
  final byId = <String, T>{};
  for (final list in perRoomResults) {
    for (final item in list) {
      byId.putIfAbsent(idOf(item), () => item);
    }
  }
  final merged = byId.values.toList();
  merged.sort((a, b) => sortKey(b).compareTo(sortKey(a)));
  return merged;
}

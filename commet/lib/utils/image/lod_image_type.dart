/// Levels of detail for a progressively-loaded image, declared from lowest to
/// highest quality. The declaration order is load-bearing — [isHigherLod]
/// compares by `index` — so new levels must be inserted in quality order.
enum LODImageType {
  blurhash,
  thumbnail,
  fullres,
}

/// Whether [incoming] is a strictly higher level of detail than [current],
/// treating a null [current] as "nothing shown yet".
///
/// Thumbnail and full-res are fetched concurrently and can finish in either
/// order, so this gate stops a late, lower-quality level from overwriting a
/// higher one that already rendered. Re-applying the same level is not an
/// upgrade, so it returns false (avoids a redundant re-decode).
bool isHigherLod(LODImageType incoming, LODImageType? current) {
  return current == null || incoming.index > current.index;
}

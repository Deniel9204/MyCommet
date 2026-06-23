/// Computes the next exponential-backoff delay: double [current], capped at
/// [maxDelay]. Pure (no Flutter dependency) so it can be unit tested.
///
/// Capping here (before the caller waits) ensures a single wait never exceeds
/// [maxDelay] — previously the cap was applied after waiting, so once the delay
/// reached the max the next wait was twice the max.
Duration nextBackoffDelay(Duration current, Duration maxDelay) {
  final doubled = current * 2;
  return doubled > maxDelay ? maxDelay : doubled;
}

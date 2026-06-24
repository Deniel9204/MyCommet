/// Advances a quarter-turn rotation by 90° clockwise, wrapping back to 0 after
/// a full turn. Quarter-turns are in the range 0–3 (as used by Flutter's
/// `RotatedBox.quarterTurns`).
///
/// Pure (no Flutter import) so it can be unit tested directly.
int nextQuarterTurn(int current) {
  return (current + 1) % 4;
}

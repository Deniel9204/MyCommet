/// Human-readable result of a room-wide re-decrypt request, given the number
/// of still-undecryptable messages it tried to recover. Pure so it can be unit
/// tested directly.
String redecryptResultMessage(int undecryptableCount) {
  if (undecryptableCount <= 0) {
    return "No messages needed re-decrypting";
  }
  if (undecryptableCount == 1) {
    return "Re-requesting keys for 1 message";
  }
  return "Re-requesting keys for $undecryptableCount messages";
}

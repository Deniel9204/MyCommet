/// What a hardware Enter keypress in the message composer should do.
enum EnterAction {
  /// Let the text field handle it (e.g. shift+enter inserts a newline).
  ignore,

  /// Consume the event but do nothing — used for auto-repeat / key-up so a
  /// held or fast Enter does not trigger the action more than once.
  swallow,

  /// Apply the currently highlighted autocomplete suggestion.
  applyAutofill,

  /// Send the message.
  send,
}

/// Resolves the action for an Enter keypress in the composer.
///
/// Pure (no Flutter dependency) so it can be unit tested. The caller supplies:
/// - [isInitialPress]: the event is a `KeyDownEvent`, not auto-repeat or key-up.
///   This is the guard that fixes double-send: only the initial press acts;
///   subsequent repeat events are swallowed.
/// - [shiftPressed]: shift is held (newline instead of send).
/// - [hasAutofillSelection]: an autocomplete suggestion is highlighted.
EnterAction resolveEnterAction({
  required bool isInitialPress,
  required bool shiftPressed,
  required bool hasAutofillSelection,
}) {
  if (hasAutofillSelection) {
    return isInitialPress ? EnterAction.applyAutofill : EnterAction.swallow;
  }

  if (shiftPressed) {
    return EnterAction.ignore;
  }

  return isInitialPress ? EnterAction.send : EnterAction.swallow;
}

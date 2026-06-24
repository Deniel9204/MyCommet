/// The kind of user-interactive-authentication (UIA) stage the UI should
/// present next, derived from the set of stage type strings the homeserver
/// offers (matrix's `UiaRequest.nextStages`).
enum UiaStageKind {
  /// `m.login.password` — show a password field.
  password,

  /// `m.login.dummy` — no user input required; complete immediately.
  dummy,

  /// `m.login.sso` — send the user through the homeserver's SSO fallback page.
  sso,

  /// A stage the app can't drive in-app yet (recaptcha, msisdn, e-mail, …).
  /// The UI should offer to cancel rather than loop forever on a password box
  /// that can never satisfy the stage.
  unsupported,
}

/// UIA stage type identifiers. These mirror matrix's `AuthenticationTypes`,
/// duplicated here so this helper stays a pure Dart unit (no SDK import) and so
/// the same constants can be reused when completing a stage.
abstract class UiaStageTypes {
  static const String password = 'm.login.password';
  static const String dummy = 'm.login.dummy';
  static const String sso = 'm.login.sso';
}

/// Picks which stage to present from [nextStages], preferring the path that
/// needs the least from the user and that the app can actually complete:
/// dummy (no input) > password > sso > anything else (unsupported).
///
/// Historically the view always rendered a password box regardless of the
/// stage, so a homeserver that required SSO/dummy/etc. could never satisfy the
/// flow and the request looped forever (#84). Empty [nextStages] also maps to
/// [UiaStageKind.unsupported] so the UI can bail rather than hang.
UiaStageKind resolveUiaStage(Set<String> nextStages) {
  if (nextStages.contains(UiaStageTypes.dummy)) return UiaStageKind.dummy;
  if (nextStages.contains(UiaStageTypes.password)) return UiaStageKind.password;
  if (nextStages.contains(UiaStageTypes.sso)) return UiaStageKind.sso;
  return UiaStageKind.unsupported;
}

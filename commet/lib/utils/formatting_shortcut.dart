/// Maps a Ctrl/Cmd+<key> composer shortcut to the markdown marker that should
/// wrap the current selection, or null if the key isn't a formatting shortcut.
///
/// The caller checks that the control/meta modifier is held and passes the
/// pressed key's label (e.g. "B"). Kept pure (no Flutter import) so the mapping
/// is unit testable. The markers match the composer's selection-toolbar items.
String? markerForFormattingShortcut(String keyLabel) {
  switch (keyLabel.toLowerCase()) {
    case 'b':
      return '**'; // bold
    case 'i':
      return '_'; // italic
    case 'e':
      return '`'; // inline code
    default:
      return null;
  }
}

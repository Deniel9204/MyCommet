import 'package:flutter/foundation.dart';
import 'dart:io' show Platform;

class ThemeCommon {
  static List<String>? fontFamilyFallback() {
    // On Apple platforms the bundled color emoji font (EmojiFont) claims the
    // emoji glyphs but renders them blank, which also blocks Flutter's normal
    // fallback to the OS emoji font. Put the system "Apple Color Emoji" font
    // first there so emoji actually render.
    if (!kIsWeb && (Platform.isMacOS || Platform.isIOS)) {
      return ["Apple Color Emoji", "EmojiFont"];
    }
    return ["EmojiFont"];
  }
}

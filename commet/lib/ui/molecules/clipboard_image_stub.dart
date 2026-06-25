import 'dart:typed_data';

/// Surfaces images pasted via the browser's `paste` event.
///
/// This is the non-web stub: on desktop/mobile, clipboard image paste is
/// handled natively through the `pasteboard` package, so this listener does
/// nothing. The real implementation lives in `clipboard_image_web.dart` and is
/// selected by a conditional import on web.
class WebPasteImageListener {
  WebPasteImageListener(void Function(Uint8List bytes) onImage);

  void dispose() {}
}

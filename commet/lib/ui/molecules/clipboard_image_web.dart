import 'dart:typed_data';

import 'package:universal_html/html.dart' as html;

/// Surfaces images pasted via the browser's `paste` event.
///
/// Flutter web's `pasteboard` cannot read clipboard images, so on web we hook
/// the DOM `paste` event instead: it is a genuine user gesture (no permission
/// prompt) and works across browsers. When an image is pasted we pull its blob
/// out of the event's clipboard data and read it into bytes.
class WebPasteImageListener {
  late final html.EventListener _listener;

  WebPasteImageListener(void Function(Uint8List bytes) onImage) {
    _listener = (html.Event event) {
      if (event is! html.ClipboardEvent) return;
      final items = event.clipboardData?.items;
      if (items == null) return;

      final length = items.length ?? 0;
      for (var i = 0; i < length; i++) {
        // universal_html types operator[] as non-null, but its runtime values
        // can be null (its getters are nullable), so keep the null-aware access.
        // ignore: invalid_null_aware_operator
        final file = items[i]?.getAsFile();
        if (file == null) continue;
        if (!file.type.startsWith('image/')) continue;

        final reader = html.FileReader();
        reader.onLoadEnd.listen((_) {
          final result = reader.result;
          if (result is ByteBuffer) {
            onImage(result.asUint8List());
          } else if (result is Uint8List) {
            onImage(result);
          }
        });
        reader.readAsArrayBuffer(file);
        // Only handle the first image on the clipboard.
        return;
      }
    };

    html.document.addEventListener('paste', _listener);
  }

  void dispose() {
    html.document.removeEventListener('paste', _listener);
  }
}

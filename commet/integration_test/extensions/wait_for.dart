import 'package:flutter_test/flutter_test.dart';

/// Workaround for https://github.com/flutter/flutter/issues/88765
extension WaitForExtension on WidgetTester {
  Future<void> waitFor(
    bool Function() finder, {
    Duration timeout = const Duration(seconds: 20),
    bool skipPumpAndSettle = false,
  }) async {
    final end = DateTime.now().add(timeout);

    while (finder.call() != true) {
      if (DateTime.now().isAfter(end)) {
        throw Exception('Timed out waiting for $finder');
      }

      if (!skipPumpAndSettle) {
        await pump();
      }

      await Future.delayed(const Duration(milliseconds: 100));
    }
  }

  /// Pumps a bounded number of frames. Use instead of [pumpAndSettle], which in
  /// the live app hangs until its 10-minute timeout because frames are scheduled
  /// continuously (the sync loop, spinners). This advances animations and route
  /// transitions without waiting for the tree to fully settle; pair it with a
  /// [waitFor] when the next step depends on async (network/sync) state.
  Future<void> pumpBounded({
    int frames = 12,
    Duration step = const Duration(milliseconds: 100),
  }) async {
    for (var i = 0; i < frames; i++) {
      await pump(step);
    }
  }
}

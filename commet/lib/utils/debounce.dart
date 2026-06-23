import 'dart:async';

class Debouncer {
  final Duration delay;
  Timer? _timer;

  bool get running => _timer != null;

  Debouncer({required this.delay});

  void run(void Function() action) {
    _timer?.cancel();
    _timer = Timer(delay, () {
      // Clear the timer before running so `running` reports false once the
      // debounced action fires (callers use it to drive e.g. a loading state).
      _timer = null;
      action();
    });
  }

  void cancel() {
    _timer?.cancel();
    _timer = null;
  }
}

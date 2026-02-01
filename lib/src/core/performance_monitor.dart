import 'dart:developer' as developer;

class PerformanceMonitor {
  static final Map<String, Stopwatch> _timers = {};

  static void start(String label) {
    _timers[label] = Stopwatch()..start();
    developer.log('[PERF] START $label');
  }

  static void end(String label) {
    final stopwatch = _timers[label];
    if (stopwatch != null) {
      stopwatch.stop();
      developer.log('[PERF] END $label: ${stopwatch.elapsedMicroseconds}us');
      _timers.remove(label);
    } else {
      developer.log('[PERF] END $label: Timer not found');
    }
  }

  static void instant(String message) {
    developer.log('[PERF] $message');
  }
}

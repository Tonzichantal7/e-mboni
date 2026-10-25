import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:vibration/vibration.dart';

/// Universal haptic feedback abstraction.
///
/// All public methods are fire-and-forget futures that swallow every
/// platform exception, so callers never need try/catch blocks.
/// Call [cancel] inside [State.dispose] to truncate any in-flight
/// vibration before the hardware channel is released.
class HapticService {
  static bool? _hasVibrator;
  static Completer<bool>? _probeCompleter;

  static Future<bool> get _capable async {
    if (kIsWeb || !_isMobilePlatform) return false;
    if (_hasVibrator != null) return _hasVibrator!;
    if (_probeCompleter != null) return _probeCompleter!.future;

    _probeCompleter = Completer<bool>();
    try {
      final result = await Vibration.hasVibrator() ?? false;
      _hasVibrator = result;
      _probeCompleter!.complete(result);
    } catch (_) {
      _hasVibrator = false;
      _probeCompleter!.complete(false);
    } finally {
      _probeCompleter = null;
    }
    return _hasVibrator!;
  }

  static bool get _isMobilePlatform =>
      defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS;

  // ── Public API ──────────────────────────────────────────────────────────────

  /// Entry alert on the emergency screen.
  /// Matches RN vibrateDanger(): [0, 800, 200, 800, 200, 800]
  static Future<void> emergencyEntry() => _safeVibrate(
        pattern: [0, 800, 200, 800, 200, 800],
      );

  /// Continuous buzz while the user holds the cancel gesture.
  /// Repeats indefinitely until [cancel] is called.
  static Future<void> emergencyCancelHold() => _safeVibrate(
        pattern: [0, 300, 100],
        repeat: 0,
      );

  /// Dual-pulse confirmation when the voice listener is activated.
  /// Matches RN: 100ms buzz · 50ms gap · 100ms buzz
  static Future<void> voiceListenStart() => _safeVibrate(
        pattern: [0, 100, 50, 100],
      );

  /// Single short tick for generic confirmations.
  static Future<void> lightTick() => _safeVibrate(
        pattern: [0, 40],
      );

  /// Danger vibration for navigation screen.
  /// Matches RN vibrateDanger(): [0, 800, 200, 800, 200, 800]
  static Future<void> navigationDanger() => _safeVibrate(
        pattern: [0, 800, 200, 800, 200, 800],
      );

  /// Warning vibration for navigation screen (obstacle/left/right).
  /// Matches RN vibrateObstacle/Left/Right(): [0, 80]
  static Future<void> navigationWarning() => _safeVibrate(
        pattern: [0, 80],
      );

  /// Stops any active vibration immediately. Never throws.
  static Future<void> cancel() async {
    try {
      await Vibration.cancel();
    } catch (_) {}
  }

  // ── Internal ────────────────────────────────────────────────────────────────

  static Future<void> _safeVibrate({
    required List<int> pattern,
    int repeat = -1,
  }) async {
    if (!await _capable) return;
    try {
      await Vibration.vibrate(pattern: pattern, repeat: repeat);
    } catch (_) {}
  }
}

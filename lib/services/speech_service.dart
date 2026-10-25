import 'package:flutter_tts/flutter_tts.dart';

/// Singleton TTS service that mirrors RN's speechService.ts exactly:
///
/// • fr-FR locale for Kinyarwanda (closest supported TTS language)
/// • urgent=true  → rate 1.1, pitch 1.2  (danger announcements)
/// • urgent=false → rate 0.75, pitch 1.0 (normal / calm)
/// • 7-second dedup: identical non-urgent text is silenced
/// • Consecutive "path clear" suppression after the first utterance
/// • speak() is fire-and-forget — never awaited by callers, matching
///   RN's setTimeout(() => Speech.speak(...), 0/100) pattern.
class SpeechService {
  SpeechService._();

  static final FlutterTts _tts = FlutterTts();

  static String _lastSpoken   = '';
  static int    _lastSpokenMs = 0;
  static int    _clearCount   = 0;
  static String _currentLang  = 'en';

  static const Map<String, String> _ttsLocale = {
    'en': 'en-US',
    'rw': 'fr-FR', // French is the closest supported locale for Kinyarwanda
  };

  static void setLanguage(String lang) {
    _currentLang = lang;
  }

  /// Fire-and-forget TTS call. Matches RN's setTimeout pattern:
  ///   urgent=true  → immediate (0 ms delay)
  ///   urgent=false → 100 ms delay before speaking
  ///
  /// GAP 4.6 FIX: The method is NOT async and does NOT await _tts.speak().
  /// This prevents blocking the 3500 ms detection loop when called from
  /// NavigationScreen, matching RN's non-blocking setTimeout behaviour.
  static void speak(String text, {bool urgent = false}) {
    final now = DateTime.now().millisecondsSinceEpoch;

    // Consecutive "path clear" suppression
    final clearKey = _currentLang == 'rw' ? 'Inzira irahari' : 'Path is clear';
    if (text == clearKey) {
      _clearCount++;
      if (_clearCount > 1) return;
    } else {
      _clearCount = 0;
    }

    // 7-second dedup for non-urgent speech
    final isDuplicate = text == _lastSpoken && (now - _lastSpokenMs) < 7000;
    if (isDuplicate && !urgent) return;

    _lastSpoken   = text;
    _lastSpokenMs = now;

    // Apply TTS settings and speak — all fire-and-forget
    Future(() async {
      await _tts.setLanguage(_ttsLocale[_currentLang] ?? 'en-US');
      await _tts.setSpeechRate(urgent ? 1.1 : 0.75);
      await _tts.setPitch(urgent ? 1.2 : 1.0);
      if (!urgent) {
        // 100 ms delay for non-urgent speech — matches RN setTimeout(100)
        await Future.delayed(const Duration(milliseconds: 100));
      }
      await _tts.speak(text);
    });
  }

  static Future<void> reset() async {
    _lastSpoken   = '';
    _lastSpokenMs = 0;
    _clearCount   = 0;
    await _tts.stop();
  }

  static Future<void> stop() => _tts.stop();
}

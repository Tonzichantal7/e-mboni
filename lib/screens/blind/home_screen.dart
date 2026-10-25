import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:speech_to_text/speech_to_text.dart';
import '../../constants/colors.dart';
import '../../services/haptic_service.dart';
import '../../services/lang_provider.dart';
import '../../services/speech_service.dart';
import '../../widgets/voice_indicator.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  // ── Pulse animation ──────────────────────────────────────────────────────────
  late AnimationController _pulseCtrl;
  late Animation<double>   _pulse;

  // ── Tap counting — 400 ms debounce matches RN ────────────────────────────────
  int    _tapCount = 0;
  Timer? _tapTimer;

  // ── Voice / STT ──────────────────────────────────────────────────────────────
  bool         _listening    = false;
  final SpeechToText _stt   = SpeechToText();
  bool         _sttAvailable = false;

  @override
  void initState() {
    super.initState();

    // Pulse ring: 1.0 → 1.08 over 1000 ms, reverse, loop — matches RN exactly
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    _pulse = Tween<double>(begin: 1.0, end: 1.08).animate(_pulseCtrl);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      _sttAvailable = await _stt.initialize();
      final lang = context.read<LangProvider>().lang;
      SpeechService.setLanguage(lang);
      SpeechService.speak(
        lang == 'rw'
            ? 'E-mboni irategurwa. Kanda rimwe gutangira kugenda. Kanda inshuro eshatu kugira impanuka.'
            : 'E-mboni ready. Tap once to start navigation. Triple tap for emergency.',
        urgent: true,
      );
    });
  }

  // ── Tap dispatcher ───────────────────────────────────────────────────────────

  void _handleTap() {
    _tapCount++;
    _tapTimer?.cancel();
    _tapTimer = Timer(const Duration(milliseconds: 400), () {
      final count = _tapCount;
      _tapCount = 0;
      if (count == 1)      _singleTap();
      else if (count == 2) _doubleTap();
      else if (count >= 3) _tripleTap();
    });
  }

  void _singleTap() {
    final lang = context.read<LangProvider>().lang;
    SpeechService.speak(
      lang == 'rw' ? 'Gutangira kuyobora' : 'Starting navigation',
      urgent: true,
    );
    context.push('/blind/navigation');
  }

  void _doubleTap() {
    final lang         = context.read<LangProvider>().lang;
    final nowListening = !_listening;
    setState(() => _listening = nowListening);

    if (nowListening) {
      HapticService.voiceListenStart();
      SpeechService.speak(
        lang == 'rw' ? 'Ndumva. Vuga gutangira.' : 'Listening. Say start to begin.',
      );
      _startSTT(lang);
    } else {
      _stt.stop();
      SpeechService.speak(
        lang == 'rw' ? 'Kumva byarangiye' : 'Done listening',
      );
    }
  }

  void _startSTT(String lang) {
    if (!_sttAvailable) return;
    _stt.listen(
      localeId: lang == 'rw' ? 'fr_FR' : 'en_US',
      onResult: (result) {
        if (!result.finalResult) return;
        if (!mounted) return;
        setState(() => _listening = false);
        final lower = result.recognizedWords.toLowerCase();
        if (lower.contains('start') || lower.contains('tangira')) {
          _singleTap();
        } else if (lower.contains('emergency') || lower.contains('impanuka')) {
          _tripleTap();
        } else {
          SpeechService.speak(
            lang == 'rw'
                ? 'Vuga gutangira cyangwa impanuka.'
                : 'Say start or emergency.',
          );
        }
      },
    );
  }

  void _tripleTap() {
    final lang = context.read<LangProvider>().lang;
    SpeechService.speak(
      lang == 'rw' ? 'Impanuka. Komera.' : 'Emergency activated. Stay calm.',
      urgent: true,
    );
    context.push('/blind/emergency');
  }

  @override
  void dispose() {
    HapticService.cancel();
    _pulseCtrl.dispose();
    _tapTimer?.cancel();
    _stt.stop();
    SpeechService.stop();
    super.dispose();
  }

  // ── Build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LangProvider>().lang;

    // FIX: Scaffold is the outermost widget. GestureDetector wraps the BODY
    // content only — not the Scaffold itself. Wrapping Scaffold causes it to
    // intercept pointer events before GestureDetector can see them, resulting
    // in missed taps. RN's TouchableOpacity wraps screen content, not a shell.
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Semantics(
        button: true,
        label: lang == 'rw'
            ? 'Kanda rimwe gutangira. Kanda inshuro eshatu kugira impanuka.'
            : 'Tap once to start. Triple tap for emergency.',
        child: GestureDetector(
          onTap: _handleTap,
          behavior: HitTestBehavior.opaque,
          child: SizedBox.expand(
            child: Center(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Pulsing ring — RN: borderColor: COLORS.accent + '33' = 20% opacity
                  ScaleTransition(
                    scale: _pulse,
                    child: Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.accent.withOpacity(0.2),
                          width: 2,
                        ),
                      ),
                    ),
                  ),

                  // VoiceIndicator — dual-ring staggered ripple animation
                  VoiceIndicator(active: _listening),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

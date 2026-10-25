import 'dart:async';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../constants/colors.dart';
import '../../services/api.dart';
import '../../services/haptic_service.dart';
import '../../services/lang_provider.dart';
import '../../services/speech_service.dart';

class EmergencyScreen extends StatefulWidget {
  const EmergencyScreen({super.key});

  @override
  State<EmergencyScreen> createState() => _EmergencyScreenState();
}

class _EmergencyScreenState extends State<EmergencyScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseCtrl;
  late Animation<double> _pulse;
  String? _guardianPhone;
  int _tapCount = 0;
  Timer? _tapTimer;

  static const _bg     = Color(0xFF0D0005);
  static const _danger = AppColors.danger;

  @override
  void initState() {
    super.initState();

    // Pulse: 1.0 → 1.15 over 600 ms, reverse, loop — matches RN exactly
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);
    _pulse = Tween<double>(begin: 1.0, end: 1.15).animate(_pulseCtrl);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final lang = context.read<LangProvider>().lang;
      SpeechService.setLanguage(lang);
      HapticService.emergencyEntry();
      SpeechService.speak(
        lang == 'rw'
          ? 'Impanuka. Kanda rimwe guhamagara umurezi wawe. Shikama guhagarika.'
          : 'Emergency active. Tap once to call your guardian. Hold to cancel.',
        urgent: true,
      );
      apiFetch('/auth/me').then((data) {
        if (data['emergency_phone'] != null && mounted) {
          setState(() => _guardianPhone = data['emergency_phone'] as String);
        }
      }).catchError((_) {});
    });
  }

  void _handleTap() {
    _tapCount++;
    _tapTimer?.cancel();
    _tapTimer = Timer(const Duration(milliseconds: 400), () {
      final count = _tapCount;
      _tapCount = 0;
      if (count == 1) _callGuardian();
    });
  }

  Future<void> _callGuardian() async {
    final lang = context.read<LangProvider>().lang;
    if (_guardianPhone == null) {
      SpeechService.speak(
        lang == 'rw' ? 'Nimero ntiboneka.' : 'Guardian phone not found.',
        urgent: true,
      );
      return;
    }
    SpeechService.speak(
      lang == 'rw' ? 'Guhamagara umurezi.' : 'Calling your guardian now.',
      urgent: true,
    );
    final uri = Uri.parse('tel:$_guardianPhone');
    if (await canLaunchUrl(uri)) launchUrl(uri);
  }

  void _cancelEmergency() {
    // Cancel any in-flight haptic before navigating away
    HapticService.cancel();
    final lang = context.read<LangProvider>().lang;
    SpeechService.speak(
      lang == 'rw' ? 'Impanuka ihagaritswe.' : 'Emergency cancelled. Going back.',
      urgent: true,
    );
    context.go('/blind');
  }

  @override
  void dispose() {
    HapticService.cancel();
    _pulseCtrl.dispose();
    _tapTimer?.cancel();
    SpeechService.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // RawGestureDetector sets the exact 1500 ms threshold matching
    // RN delayLongPress={1500}. Flutter's GestureDetector does not
    // expose this duration directly.
    return RawGestureDetector(
      gestures: {
        TapGestureRecognizer:
            GestureRecognizerFactoryWithHandlers<TapGestureRecognizer>(
          () => TapGestureRecognizer(),
          (r) => r.onTap = _handleTap,
        ),
        LongPressGestureRecognizer:
            GestureRecognizerFactoryWithHandlers<LongPressGestureRecognizer>(
          () => LongPressGestureRecognizer(
            duration: const Duration(milliseconds: 1500),
          ),
          (r) {
            r.onLongPressStart = (_) => HapticService.emergencyCancelHold();
            r.onLongPressEnd   = (_) => HapticService.cancel();
            // GAP 3.1 FIX: onLongPressCancel is void Function() — wrap the
            // async HapticService.cancel() in a sync lambda so the types match.
            r.onLongPressCancel = () { HapticService.cancel(); };
            r.onLongPress       = _cancelEmergency;
          },
        ),
      },
      child: Scaffold(
        backgroundColor: _bg,
        body: Center(
          child: Stack(
            alignment: Alignment.center,
            children: [
              // GAP 2.1 FIX: explicit alignment on ScaleTransition prevents
              // off-center scaling on some Flutter engine versions.
              ScaleTransition(
                scale: _pulse,
                alignment: Alignment.center,
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      // RN: DANGER + '66' = 0x66/0xFF = 40% opacity
                      color: _danger.withOpacity(0.4),
                      width: 3,
                    ),
                  ),
                ),
              ),
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  // RN: DANGER + '33' = 0x33/0xFF = 20% opacity
                  color: _danger.withOpacity(0.2),
                  border: Border.all(color: _danger, width: 2),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

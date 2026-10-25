import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../constants/colors.dart';
import '../../services/lang_provider.dart';
import '../../services/speech_service.dart';

class StopScreen extends StatefulWidget {
  const StopScreen({super.key});

  @override
  State<StopScreen> createState() => _StopScreenState();
}

class _StopScreenState extends State<StopScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final lang = context.read<LangProvider>();
      SpeechService.setLanguage(lang.lang);
      // navStopped is spoken with urgent=false (calm, matches RN speak(t('navStopped')))
      SpeechService.speak(lang.t('navStopped'));
    });
  }

  @override
  void dispose() {
    SpeechService.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LangProvider>();

    // ── ScreenContainer equivalent: flex:1, bg, center, padding:32 ───────────
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // title — fontSize:36, fontWeight:'600', marginBottom:12
              Text(
                lang.t('stopped'),
                style: const TextStyle(
                  color: AppColors.text,
                  fontSize: 36,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),

              // subtitle — fontSize:18, lineHeight:28 (height≈1.55), marginBottom:48
              Text(
                lang.t('youAreSafe'),
                style: const TextStyle(
                  color: AppColors.muted,
                  fontSize: 18,
                  height: 1.55,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),

              // Home button — paddingV:18, paddingH:56, borderRadius:50
              // RN uses TouchableOpacity → use InkWell for press feedback
              InkWell(
                onTap: () => context.go('/blind'),
                borderRadius: BorderRadius.circular(50),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      vertical: 18, horizontal: 56),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: Text(
                    lang.t('goHome'),
                    style: const TextStyle(
                      color: AppColors.text,
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Settings link — paddingV:12, paddingH:32
              InkWell(
                onTap: () => context.push('/blind/settings'),
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      vertical: 12, horizontal: 32),
                  child: Text(
                    lang.lang == 'rw' ? 'Igenamiterere' : 'Settings',
                    style: const TextStyle(
                        color: AppColors.muted, fontSize: 14),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

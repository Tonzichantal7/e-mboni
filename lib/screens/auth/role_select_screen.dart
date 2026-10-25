import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../constants/colors.dart';
import '../../services/lang_provider.dart';

class RoleSelectScreen extends StatelessWidget {
  const RoleSelectScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LangProvider>();
    return Scaffold(
      body: Stack(
        children: [
          // Background image
          Positioned.fill(
            child: Image.asset('assets/images/auth-bg.jpg', fit: BoxFit.cover),
          ),
          // Dark overlay — RN: rgba(10,8,20,0.82) = 0xD10A0814
          Positioned.fill(
            child: Container(color: const Color(0xD10A0814)),
          ),

          // Main content — vertically centered
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo section
                  Column(
                    children: [
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: AppColors.accent,
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: const Icon(
                          Icons.remove_red_eye,
                          color: Colors.white,
                          size: 36,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'E-mboni',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 40,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 3,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        lang.t('tagline'),
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // Guardian card (tappable)
                  _RoleCard(
                    icon: Icons.shield,
                    iconColor: AppColors.accent,
                    title: lang.t('guardian'),
                    desc: lang.t('guardianDesc'),
                    onTap: () => context.push('/auth/guardian-register'),
                  ),
                  const SizedBox(height: 14),

                  // Blind user card (informational only — opacity:0.6)
                  Opacity(
                    opacity: 0.6,
                    child: _RoleCard(
                      icon: Icons.mic,
                      iconColor: Colors.white38,
                      title: lang.t('blindUser'),
                      desc: lang.t('blindUserDesc'),
                      onTap: null,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Sign in link
                  GestureDetector(
                    onTap: () => context.push('/auth/login'),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          lang.t('alreadyAccount'),
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.45),
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          lang.t('signIn'),
                          style: const TextStyle(
                            color: AppColors.accent,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 2),
                        const Icon(
                          Icons.arrow_forward,
                          color: AppColors.accent,
                          size: 14,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // GAP 1.1 FIX: Language toggle is position:absolute top:56 right:24
          // matching RN: position:'absolute', top:56, right:24
          Positioned(
            top: 56,
            right: 24,
            child: SafeArea(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _LangBtn(
                    label: '🇬🇧 EN',
                    active: lang.lang == 'en',
                    onTap: () => lang.setLang('en'),
                  ),
                  const SizedBox(width: 8),
                  _LangBtn(
                    label: '🇷🇼 RW',
                    active: lang.lang == 'rw',
                    onTap: () => lang.setLang('rw'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LangBtn extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _LangBtn({
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
          decoration: BoxDecoration(
            color: active ? AppColors.accent : Colors.white.withOpacity(0.08),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: active ? AppColors.accent : Colors.white24,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: active ? Colors.white : Colors.white54,
            ),
          ),
        ),
      );
}

class _RoleCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String desc;
  final VoidCallback? onTap;
  const _RoleCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.desc,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            // RN: rgba(255,255,255,0.07)
            color: Colors.white.withOpacity(0.07),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white12),
          ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.13),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: iconColor, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      desc,
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 12,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              if (onTap != null)
                const Icon(
                  Icons.chevron_right,
                  color: Colors.white38,
                  size: 20,
                ),
            ],
          ),
        ),
      );
}

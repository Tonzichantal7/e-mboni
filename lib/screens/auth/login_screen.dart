import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../constants/colors.dart';
import '../../services/api.dart';
import '../../services/lang_provider.dart';
import '../../services/speech_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _phoneCtrl = TextEditingController();
  final _passCtrl  = TextEditingController();
  bool   _showPass = false;
  bool   _loading  = false;
  String _error    = '';

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  // GAP 4.1 FIX: mirrors RN applyLang() — sets both the UI lang provider
  // AND the TTS service language so speech is correct immediately.
  void _applyLang(String l) {
    context.read<LangProvider>().setLang(l);
    SpeechService.setLanguage(l);
  }

  Future<void> _handleLogin() async {
    final lang = context.read<LangProvider>();
    if (_phoneCtrl.text.trim().isEmpty || _passCtrl.text.trim().isEmpty) {
      setState(() => _error = lang.lang == 'rw'
          ? 'Uzuza ibisabwa byose.'
          : 'Please fill in all fields.');
      return;
    }
    setState(() { _loading = true; _error = ''; });
    try {
      final data = await apiFetch('/auth/login', method: 'POST', body: {
        'phone':    _phoneCtrl.text.trim(),
        'password': _passCtrl.text.trim(),
      });
      await saveToken(data['token'] as String);
      await saveUser(Map<String, dynamic>.from(data['user'] as Map));
      if (!mounted) return;
      final role = data['user']['role'] as String?;
      if (role == 'guardian')   context.go('/guardian');
      else if (role == 'admin') context.go('/admin');
      else                      context.go('/blind');
    } catch (_) {
      final lang2 = context.read<LangProvider>();
      setState(() => _error = lang2.lang == 'rw'
          ? 'Nimero cyangwa ijambo banga sibyo.'
          : 'Wrong phone or password.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LangProvider>();

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset('assets/images/auth-bg.jpg', fit: BoxFit.cover),
          ),
          // RN overlay: rgba(10,8,20,0.88) = 0xE10A0814
          Positioned.fill(
            child: Container(color: const Color(0xE10A0814)),
          ),
          SafeArea(
            // GestureDetector replicates RN keyboardShouldPersistTaps='handled':
            // tapping outside an input dismisses the keyboard without consuming
            // the tap on any underlying widget.
            child: GestureDetector(
              onTap: () => FocusScope.of(context).unfocus(),
              behavior: HitTestBehavior.translucent,
              child: SingleChildScrollView(
                // GAP 2.10 FIX: paddingTop:56 matches RN contentContainerStyle
                // paddingTop:56. Previous Flutter value was only 16.
                padding: const EdgeInsets.fromLTRB(24, 56, 24, 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ── Top row ───────────────────────────────────────────────
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _CircleBtn(
                          icon: Icons.arrow_back,
                          onTap: () => context.pop(),
                        ),
                        Row(children: [
                          _LangBtn(
                            label: '🇬🇧 EN',
                            active: lang.lang == 'en',
                            onTap: () => _applyLang('en'),
                          ),
                          const SizedBox(width: 8),
                          _LangBtn(
                            label: '🇷🇼 RW',
                            active: lang.lang == 'rw',
                            onTap: () => _applyLang('rw'),
                          ),
                        ]),
                      ],
                    ),
                    const SizedBox(height: 32),

                    // ── Header ────────────────────────────────────────────────
                    Center(
                      child: Column(children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: AppColors.accent,
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: const Icon(
                            Icons.remove_red_eye,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          lang.t('welcomeBack'),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          lang.t('signInAccount'),
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.45),
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Hint box
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white12),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(
                                Icons.info_outline,
                                color: Colors.white38,
                                size: 14,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  lang.lang == 'rw'
                                      ? "Umurezi: injira ukoresheje nimero yawe na ijambo banga wahinduye.\nImpumyi: injira ukoresheje nimero yawe na imibare 6 y'imperuka ya nimero yawe."
                                      : 'Guardian: use your phone number and the password you created.\nBlind user: use your phone number and the last 6 digits of your phone number.',
                                  style: const TextStyle(
                                    color: Colors.white38,
                                    fontSize: 11,
                                    height: 1.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ]),
                    ),
                    const SizedBox(height: 24),

                    // ── Form card ─────────────────────────────────────────────
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: Colors.white12),
                      ),
                      child: Column(children: [
                        _InputField(
                          controller: _phoneCtrl,
                          icon: Icons.call_outlined,
                          hint: lang.lang == 'rw'
                              ? 'Nimero ya Telefoni'
                              : 'Phone Number',
                          keyboardType: TextInputType.phone,
                          onChanged: (_) => setState(() => _error = ''),
                        ),
                        const SizedBox(height: 12),
                        _InputField(
                          controller: _passCtrl,
                          icon: Icons.lock_outline,
                          hint: lang.t('password'),
                          obscure: !_showPass,
                          onChanged: (_) => setState(() => _error = ''),
                          suffix: IconButton(
                            icon: Icon(
                              _showPass
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              color: Colors.white38,
                              size: 18,
                            ),
                            onPressed: () =>
                                setState(() => _showPass = !_showPass),
                          ),
                        ),
                        if (_error.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Row(children: [
                            const Icon(
                              Icons.error_outline,
                              color: Color(0xFFF87171),
                              size: 14,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              _error,
                              style: const TextStyle(
                                color: Color(0xFFF87171),
                                fontSize: 13,
                              ),
                            ),
                          ]),
                        ],
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _loading ? null : _handleLogin,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.accent,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: _loading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        lang.t('signIn'),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      const Icon(
                                        Icons.arrow_forward,
                                        color: Colors.white,
                                        size: 18,
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                      ]),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────

class _CircleBtn extends StatelessWidget {
  final IconData     icon;
  final VoidCallback onTap;
  const _CircleBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
      );
}

class _LangBtn extends StatelessWidget {
  final String       label;
  final bool         active;
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
            color: active
                ? AppColors.accent
                : Colors.white.withOpacity(0.08),
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

class _InputField extends StatelessWidget {
  final TextEditingController  controller;
  final IconData               icon;
  final String                 hint;
  final bool                   obscure;
  final TextInputType?         keyboardType;
  final ValueChanged<String>?  onChanged;
  final Widget?                suffix;

  const _InputField({
    required this.controller,
    required this.icon,
    required this.hint,
    this.obscure      = false,
    this.keyboardType,
    this.onChanged,
    this.suffix,
  });

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white12),
        ),
        child: Row(children: [
          const SizedBox(width: 14),
          Icon(icon, color: Colors.white38, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller:   controller,
              obscureText:  obscure,
              keyboardType: keyboardType,
              onChanged:    onChanged,
              style: const TextStyle(color: Colors.white, fontSize: 15),
              decoration: InputDecoration(
                hintText:  hint,
                hintStyle: const TextStyle(color: Colors.white38),
                border:    InputBorder.none,
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
          if (suffix != null) suffix!,
        ]),
      );
}

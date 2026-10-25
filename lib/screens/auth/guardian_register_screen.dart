import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../constants/colors.dart';
import '../../services/lang_provider.dart';

class GuardianRegisterScreen extends StatefulWidget {
  const GuardianRegisterScreen({super.key});

  @override
  State<GuardianRegisterScreen> createState() => _GuardianRegisterScreenState();
}

class _GuardianRegisterScreenState extends State<GuardianRegisterScreen> {
  final _nameCtrl         = TextEditingController();
  final _phoneCtrl        = TextEditingController();
  final _passCtrl         = TextEditingController();
  final _relationshipCtrl = TextEditingController();
  bool _showPass = false;

  bool get _isValid =>
    _nameCtrl.text.trim().length >= 2 &&
    _phoneCtrl.text.trim().length >= 9 &&
    _passCtrl.text.trim().length >= 6;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _passCtrl.dispose();
    _relationshipCtrl.dispose();
    super.dispose();
  }

  void _handleNext() {
    if (!_isValid) return;
    context.push('/auth/blind-register', extra: {
      'guardianName':  _nameCtrl.text.trim(),
      'guardianPhone': _phoneCtrl.text.trim().replaceAll(' ', ''),
      'password':      _passCtrl.text.trim(),
      'relationship':  _relationshipCtrl.text.trim(),
    });
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LangProvider>();

    return Scaffold(
      backgroundColor: AppColors.gBackground,
      body: SafeArea(
        // GAP 1.2 FIX: GestureDetector wrapping the scroll view replicates
        // RN keyboardShouldPersistTaps='handled' — tapping outside a field
        // dismisses the keyboard without consuming the tap.
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          behavior: HitTestBehavior.translucent,
          child: SingleChildScrollView(
            // GAP 2.6 FIX: paddingTop:60 matches RN paddingTop:60.
            // Previous Flutter value was only 20.
            padding: const EdgeInsets.fromLTRB(28, 60, 28, 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: () => context.pop(),
                  child: Text(
                    '← ${lang.t('back')}',
                    style: const TextStyle(
                      color: AppColors.gAccent,
                      fontSize: 15,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  lang.t('createAccount'),
                  style: const TextStyle(
                    color: AppColors.gText,
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  lang.t('personGuiding'),
                  style: const TextStyle(
                    color: AppColors.gMuted,
                    fontSize: 14,
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 24),
                _label(lang.t('yourFullName')),
                _input(
                  _nameCtrl,
                  'e.g. Sarah Kamau',
                  TextInputType.name,
                  TextCapitalization.words,
                ),
                _label(lang.t('yourPhone')),
                _input(_phoneCtrl, '+250 780 000 000', TextInputType.phone),
                _label(lang.t('password')),
                _passwordField(lang),
                _label(lang.t('relationship')),
                _input(
                  _relationshipCtrl,
                  lang.t('relationshipHint'),
                  TextInputType.text,
                  TextCapitalization.words,
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isValid ? _handleNext : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.gAccent,
                      disabledBackgroundColor:
                          AppColors.gAccent.withOpacity(0.4),
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(
                      lang.t('nextPrefs'),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(top: 14, bottom: 6),
        child: Text(
          text,
          style: const TextStyle(color: AppColors.gMuted, fontSize: 13),
        ),
      );

  Widget _input(
    TextEditingController ctrl,
    String hint,
    TextInputType type, [
    TextCapitalization cap = TextCapitalization.none,
  ]) =>
      TextField(
        controller: ctrl,
        keyboardType: type,
        textCapitalization: cap,
        onChanged: (_) => setState(() {}),
        style: const TextStyle(color: AppColors.gText, fontSize: 16),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: AppColors.gMuted),
          filled: true,
          fillColor: AppColors.gCard,
          contentPadding: const EdgeInsets.all(16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.gBorder),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.gBorder),
          ),
        ),
      );

  Widget _passwordField(LangProvider lang) => TextField(
        controller: _passCtrl,
        obscureText: !_showPass,
        onChanged: (_) => setState(() {}),
        style: const TextStyle(color: AppColors.gText, fontSize: 16),
        decoration: InputDecoration(
          hintText: lang.t('createPassword'),
          hintStyle: const TextStyle(color: AppColors.gMuted),
          filled: true,
          fillColor: AppColors.gCard,
          contentPadding: const EdgeInsets.all(16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.gBorder),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.gBorder),
          ),
          suffixIcon: IconButton(
            icon: Icon(
              _showPass
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
              color: AppColors.gMuted,
              size: 18,
            ),
            onPressed: () => setState(() => _showPass = !_showPass),
          ),
        ),
      );
}

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../constants/colors.dart';
import '../../services/api.dart';
import '../../services/lang_provider.dart';
import '../../services/speech_service.dart';

// Matches RN locationConsentService.ts KEY = '@emboni_location_consent'
const String _consentKey = '@emboni_location_consent';

class BlindRegisterScreen extends StatefulWidget {
  final String guardianName;
  final String guardianPhone;
  final String password;
  final String relationship;

  const BlindRegisterScreen({
    super.key,
    required this.guardianName,
    required this.guardianPhone,
    required this.password,
    required this.relationship,
  });

  @override
  State<BlindRegisterScreen> createState() => _BlindRegisterScreenState();
}

class _BlindRegisterScreenState extends State<BlindRegisterScreen> {
  final _nameCtrl  = TextEditingController();
  final _phoneCtrl = TextEditingController();
  String _lang     = 'en';
  String _speed    = 'Normal';
  bool?  _locationAllowed;
  bool   _loading  = false;
  String _error    = '';

  bool get _canSubmit =>
    _locationAllowed != null &&
    _nameCtrl.text.trim().length >= 2 &&
    _phoneCtrl.text.trim().length >= 9 &&
    !_loading;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleDone() async {
    if (!_canSubmit) return;
    setState(() { _loading = true; _error = ''; });
    try {
      final data = await apiFetch('/auth/register', method: 'POST', body: {
        'guardian': {
          'name':         widget.guardianName,
          'phone':        widget.guardianPhone,
          'password':     widget.password,
          'relationship': widget.relationship.isEmpty
              ? 'Guardian'
              : widget.relationship,
        },
        'blind_user': {
          'name':        _nameCtrl.text.trim(),
          'phone':       _phoneCtrl.text.trim().replaceAll(' ', ''),
          'language':    _lang,
          'voice_speed': _speed,
        },
      });

      // GAP 1.6 / GAP 4.2 FIX: write location consent to SharedPreferences
      // using the exact key '@emboni_location_consent' and string value
      // 'true'/'false' — matching RN saveLocationConsent() exactly.
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_consentKey, _locationAllowed! ? 'true' : 'false');

      await saveToken(data['token'] as String);
      await saveUser(Map<String, dynamic>.from(data['guardian'] as Map));

      if (!mounted) return;

      // GAP 4.3 FIX: sync TTS language after registration — matches RN
      // setLanguage(lang) + setDetectionLanguage(lang) calls.
      context.read<LangProvider>().setLang(_lang);
      SpeechService.setLanguage(_lang);

      context.go('/guardian');
    } catch (e) {
      setState(() =>
          _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final uiLang = context.watch<LangProvider>();
    return Scaffold(
      backgroundColor: AppColors.gBackground,
      body: SafeArea(
        // GAP 1.2 FIX: keyboard dismiss on outside tap
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          behavior: HitTestBehavior.translucent,
          child: SingleChildScrollView(
            // GAP 2.7 FIX: paddingTop:60 matches RN paddingTop:60
            padding: const EdgeInsets.fromLTRB(28, 60, 28, 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: () => context.pop(),
                  child: Text(
                    '← ${uiLang.t('back')}',
                    style: const TextStyle(
                      color: AppColors.gAccent,
                      fontSize: 15,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  uiLang.t('registerBlind'),
                  style: const TextStyle(
                    color: AppColors.gText,
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  uiLang.t('registeringFor'),
                  style: const TextStyle(
                    color: AppColors.gMuted,
                    fontSize: 14,
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 12),
                // Info banner
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.gAccent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.gAccent.withOpacity(0.25),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.shield_outlined,
                        color: AppColors.gAccent,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _lang == 'rw'
                            ? "Nimero ya ${widget.guardianName.isEmpty ? 'umurezi' : widget.guardianName} izakoreshwa nk'uwahamagarwa mu bihe bikomeye."
                            : "${widget.guardianName.isEmpty ? 'Guardian' : widget.guardianName}'s number will be used as the emergency contact.",
                          style: const TextStyle(
                            color: AppColors.gText,
                            fontSize: 12,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _label(uiLang.t('theirName')),
                _input(
                  _nameCtrl,
                  'e.g. James Kamau',
                  TextInputType.name,
                  TextCapitalization.words,
                ),
                _label(_lang == 'rw'
                    ? 'Nimero ya Telefoni (izakoreshwa kwinjira)'
                    : 'Phone Number (used to log in)'),
                _input(_phoneCtrl, '+250 780 000 000', TextInputType.phone),
                // Password note
                Container(
                  margin: const EdgeInsets.only(top: 8),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.04),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.info_outline,
                        color: AppColors.gMuted,
                        size: 14,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          _lang == 'rw'
                            ? "Ijambo banga ry'impumyi ni imibare 6 y'imperuka ya nimero yabo ya telefoni."
                            : "The blind user's password will be the last 6 digits of their phone number.",
                          style: const TextStyle(
                            color: AppColors.gMuted,
                            fontSize: 12,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                _label(uiLang.t('preferredLang')),
                _chips(
                  [
                    {'label': '🇬🇧 English',     'value': 'en'},
                    {'label': '🇷🇼 Kinyarwanda', 'value': 'rw'},
                  ],
                  _lang,
                  (v) => setState(() => _lang = v),
                ),
                _label(uiLang.t('voiceSpeed')),
                _chips(
                  [
                    {'label': 'Slow',   'value': 'Slow'},
                    {'label': 'Normal', 'value': 'Normal'},
                    {'label': 'Fast',   'value': 'Fast'},
                  ],
                  _speed,
                  (v) => setState(() => _speed = v),
                ),
                _label(_lang == 'rw'
                    ? 'Emera ko umurezi abona aho uri'
                    : 'Allow guardian to see your location?'),
                Row(children: [
                  _consentChip(
                    label: _lang == 'rw' ? '✓  Emera' : '✓  Allow',
                    active: _locationAllowed == true,
                    color: AppColors.safe,
                    onTap: () => setState(() => _locationAllowed = true),
                  ),
                  const SizedBox(width: 10),
                  _consentChip(
                    label: _lang == 'rw' ? '✕  Anga' : '✕  Deny',
                    active: _locationAllowed == false,
                    color: AppColors.danger,
                    onTap: () => setState(() => _locationAllowed = false),
                  ),
                ]),
                if (_locationAllowed == null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      _lang == 'rw'
                          ? 'Hitamo imwe'
                          : 'Please make a choice to continue',
                      style: const TextStyle(
                        color: AppColors.danger,
                        fontSize: 12,
                      ),
                    ),
                  ),
                if (_error.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      _error,
                      style: const TextStyle(
                        color: AppColors.danger,
                        fontSize: 12,
                      ),
                    ),
                  ),
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _canSubmit ? _handleDone : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.gAccent,
                      disabledBackgroundColor:
                          AppColors.gAccent.withOpacity(0.4),
                      padding: const EdgeInsets.symmetric(vertical: 18),
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
                      : Text(
                          uiLang.t('done'),
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

  Widget _chips(
    List<Map<String, String>> items,
    String selected,
    ValueChanged<String> onSelect,
  ) =>
      Wrap(
        spacing: 10,
        children: items.map((item) {
          final active = selected == item['value'];
          return GestureDetector(
            onTap: () => onSelect(item['value']!),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
              decoration: BoxDecoration(
                color: active ? AppColors.gAccent : AppColors.gCard,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: active ? AppColors.gAccent : AppColors.gBorder,
                ),
              ),
              child: Text(
                item['label']!,
                style: TextStyle(
                  color: active ? Colors.white : AppColors.gMuted,
                  fontSize: 14,
                  fontWeight:
                      active ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
          );
        }).toList(),
      );

  Widget _consentChip({
    required String label,
    required bool active,
    required Color color,
    required VoidCallback onTap,
  }) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
          decoration: BoxDecoration(
            color: active ? color : AppColors.gCard,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: active ? color : AppColors.gBorder,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: active ? Colors.white : AppColors.gMuted,
              fontSize: 14,
              fontWeight: active ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ),
      );
}

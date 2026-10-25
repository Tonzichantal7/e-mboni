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

class BlindSettingsScreen extends StatefulWidget {
  const BlindSettingsScreen({super.key});

  @override
  State<BlindSettingsScreen> createState() => _BlindSettingsScreenState();
}

class _BlindSettingsScreenState extends State<BlindSettingsScreen> {
  Map<String, dynamic>? _profile;
  bool? _consent;
  bool  _saved = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    // Read consent using the correct key matching RN
    final prefs   = await SharedPreferences.getInstance();
    final raw     = prefs.getString(_consentKey);
    final consent = raw == null ? null : raw == 'true';
    if (mounted) setState(() => _consent = consent);

    try {
      final data = await apiFetch('/auth/me');
      if (mounted) setState(() => _profile = data);
    } catch (_) {}

    if (!mounted) return;
    final lang = context.read<LangProvider>().lang;
    SpeechService.setLanguage(lang);
    SpeechService.speak(
      lang == 'rw' ? 'Igenamiterere. Amakuru yawe.' : 'Settings. Your profile.',
    );
  }

  Future<void> _setConsent(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    // Store as string 'true'/'false' — matches RN AsyncStorage approach
    await prefs.setString(_consentKey, value ? 'true' : 'false');
    if (mounted) setState(() { _consent = value; _saved = true; });

    final lang = context.read<LangProvider>().lang;
    SpeechService.speak(
      value
          ? (lang == 'rw' ? 'Emerewe.' : 'Location sharing allowed.')
          : (lang == 'rw' ? 'Yanganiwe.' : 'Location sharing denied.'),
    );
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _saved = false);
    });
  }

  Future<void> _signOut() async {
    await clearSession();
    if (mounted) context.go('/auth');
  }

  @override
  void dispose() {
    SpeechService.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lang         = context.watch<LangProvider>().lang;
    final consentColor = _consent == true
        ? AppColors.safe
        : _consent == false
            ? AppColors.danger
            : AppColors.muted;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          // RN: padding:24, paddingTop:60, paddingBottom:60
          padding: const EdgeInsets.fromLTRB(24, 60, 24, 60),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Back button — matches RN TouchableOpacity with marginBottom:8
              InkWell(
                onTap: () => context.pop(),
                borderRadius: BorderRadius.circular(20),
                child: const Padding(
                  padding: EdgeInsets.all(4),
                  child: Icon(Icons.arrow_back, color: AppColors.muted, size: 22),
                ),
              ),
              const SizedBox(height: 8),

              // Title — fontSize:28, fontWeight:'700', marginBottom:8
              Text(
                lang == 'rw' ? 'Igenamiterere' : 'Settings',
                style: const TextStyle(
                  color: AppColors.text,
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 16),

              // ── Profile card ───────────────────────────────────────────────
              if (_profile != null) ...[
                _Card(children: [
                  _CardHeader(
                    icon: Icons.person_outline,
                    label: lang == 'rw' ? 'Umwirondoro' : 'My Profile',
                  ),
                  _InfoRow(
                    label: lang == 'rw' ? 'Izina' : 'Name',
                    value: _profile!['name'] ?? '—',
                  ),
                  _InfoRow(
                    label: lang == 'rw' ? 'Telefoni' : 'Phone',
                    value: _profile!['phone'] ?? '—',
                  ),
                  _InfoRow(
                    label: lang == 'rw' ? 'Ururimi' : 'Language',
                    value: _profile!['language'] == 'rw'
                        ? 'Kinyarwanda'
                        : 'English',
                  ),
                  _InfoRow(
                    label: lang == 'rw' ? "Intera y'Ijwi" : 'Voice Speed',
                    value: _profile!['voice_speed'] ?? '—',
                  ),
                  if (_profile!['emergency_phone'] != null)
                    _InfoRow(
                      label: lang == 'rw'
                          ? 'Uwahamagarwa'
                          : 'Emergency Contact',
                      value: _profile!['emergency_phone'],
                    ),
                ]),
                const SizedBox(height: 16),
              ],

              // ── Location consent card ──────────────────────────────────────
              _Card(children: [
                _CardHeader(
                  icon: Icons.location_on_outlined,
                  label: lang == 'rw'
                      ? 'Gusangira Aho Uri'
                      : 'Location Sharing',
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    lang == 'rw'
                        ? 'Emera cyangwa anga ko umurezi wawe abona aho uri.'
                        : 'Allow or deny your guardian from seeing your location.',
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 14,
                      height: 1.57, // lineHeight:22 at fontSize:14
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                // Status row
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 12),
                    decoration: BoxDecoration(
                      // RN: SAFE+'15' = 0x15/0xFF = 8.2% opacity
                      color: consentColor.withOpacity(0.082),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        // RN: SAFE+'44' = 0x44/0xFF = 26.7% opacity
                        color: consentColor.withOpacity(0.267),
                      ),
                    ),
                    child: Row(children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: consentColor,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _consent == true
                            ? (lang == 'rw'
                                ? 'Emerewe'
                                : 'Currently Allowed')
                            : _consent == false
                                ? (lang == 'rw'
                                    ? 'Yanganiwe'
                                    : 'Currently Denied')
                                : (lang == 'rw'
                                    ? 'Ntabwo byashyizweho'
                                    : 'Not set yet'),
                        style: TextStyle(
                          color: consentColor,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ]),
                  ),
                ),
                const SizedBox(height: 12),

                // Allow / Deny buttons
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Row(children: [
                    Expanded(
                      child: _ActionBtn(
                        label: lang == 'rw' ? 'Emera' : 'Allow',
                        icon: Icons.check_circle,
                        color: AppColors.safe,
                        disabled: _consent == true,
                        onTap: () => _setConsent(true),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _ActionBtn(
                        label: lang == 'rw' ? 'Anga' : 'Deny',
                        icon: Icons.cancel,
                        color: AppColors.danger,
                        disabled: _consent == false,
                        onTap: () => _setConsent(false),
                      ),
                    ),
                  ]),
                ),

                if (_saved)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Center(
                      child: Text(
                        lang == 'rw' ? '✓ Byabitswe' : '✓ Saved',
                        style: const TextStyle(
                          color: AppColors.safe,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
              ]),

              const SizedBox(height: 16),

              // ── Sign out ───────────────────────────────────────────────────
              // RN: TouchableOpacity → InkWell for press feedback
              InkWell(
                onTap: _signOut,
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    // RN: DANGER+'10' = 0x10/0xFF = 6.3% opacity
                    color: AppColors.danger.withOpacity(0.063),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      // RN: DANGER+'44' = 26.7% opacity
                      color: AppColors.danger.withOpacity(0.267),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.logout_outlined,
                          color: AppColors.danger, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        lang == 'rw' ? 'Sohoka' : 'Sign Out',
                        style: const TextStyle(
                          color: AppColors.danger,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
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

// ── Shared sub-widgets ────────────────────────────────────────────────────────

class _Card extends StatelessWidget {
  final List<Widget> children;
  const _Card({required this.children});

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: children,
        ),
      );
}

class _CardHeader extends StatelessWidget {
  final IconData icon;
  final String   label;
  const _CardHeader({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: Row(children: [
          Icon(icon, color: AppColors.accent, size: 22),
          const SizedBox(width: 10),
          Text(label,
              style: const TextStyle(
                  color: AppColors.text,
                  fontSize: 17,
                  fontWeight: FontWeight.w700)),
        ]),
      );
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              // RN: COLORS.muted + '22' = 0x22/0xFF = 13.3% opacity
              color: AppColors.muted.withOpacity(0.133),
            ),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: const TextStyle(
                    color: AppColors.muted, fontSize: 13)),
            Flexible(
              child: Text(
                value,
                style: const TextStyle(
                  color: AppColors.text,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.right,
              ),
            ),
          ],
        ),
      );
}

class _ActionBtn extends StatelessWidget {
  final String       label;
  final IconData     icon;
  final Color        color;
  final bool         disabled;
  final VoidCallback onTap;
  const _ActionBtn({
    required this.label,
    required this.icon,
    required this.color,
    required this.disabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => Opacity(
        opacity: disabled ? 0.5 : 1.0,
        child: Material(
          color: color,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            onTap: disabled ? null : onTap,
            borderRadius: BorderRadius.circular(14),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, color: Colors.white, size: 18),
                  const SizedBox(width: 8),
                  Text(label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      )),
                ],
              ),
            ),
          ),
        ),
      );
}

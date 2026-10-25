import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../services/api.dart';
import '../../services/theme_provider.dart';

class GuardianSettingsScreen extends StatefulWidget {
  const GuardianSettingsScreen({super.key});

  @override
  State<GuardianSettingsScreen> createState() => _GuardianSettingsScreenState();
}

class _GuardianSettingsScreenState extends State<GuardianSettingsScreen> {
  Map<String, dynamic>? _guardian;
  Map<String, dynamic>? _blind;
  bool _push = true;
  bool _vib  = true;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    apiFetch('/guardian/dashboard').then((data) {
      if (mounted) setState(() {
        _guardian = data['guardian'];
        _blind    = data['blind_user'];
        _loading  = false;
      });
    }).catchError((_) {
      if (mounted) setState(() => _loading = false);
    });
  }

  String _initials(String? name) =>
    name?.split(' ').map((n) => n.isNotEmpty ? n[0] : '').join().toUpperCase() ?? '?';

  Future<void> _signOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sign Out', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await clearSession();
      if (mounted) context.go('/auth');
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.watch<ThemeProvider>();

    return Scaffold(
      backgroundColor: c.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 60, 20, 120),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Profile',
                style: TextStyle(color: c.text, fontSize: 26, fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),

              // Profile pill
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: c.card,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: c.border),
                ),
                child: Row(children: [
                  Container(
                    width: 50, height: 50,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: c.accent.withOpacity(0.13),
                      border: Border.all(color: c.accent.withOpacity(0.27)),
                    ),
                    child: Center(
                      child: _loading
                        ? Icon(Icons.person_outline, color: c.accent, size: 20)
                        : Text(_initials(_guardian?['name']),
                            style: TextStyle(color: c.accent, fontSize: 16, fontWeight: FontWeight.w700)),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(_guardian?['name'] ?? '—',
                      style: TextStyle(color: c.text, fontSize: 16, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Text(_guardian?['phone'] ?? '—', style: TextStyle(color: c.muted, fontSize: 12)),
                  ])),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: c.accent.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text('Guardian',
                      style: TextStyle(color: c.accent, fontSize: 11, fontWeight: FontWeight.w700)),
                  ),
                ]),
              ),
              const SizedBox(height: 12),

              // Appearance
              _GroupLabel(label: 'APPEARANCE', c: c),
              _GroupCard(c: c, children: [
                _RowItem(
                  label: c.isDark ? '🌙  Dark Mode' : '☀️  Light Mode',
                  sub:   c.isDark ? 'Switch to light mode' : 'Switch to dark mode',
                  c: c,
                  trailing: Switch(
                    value: !c.isDark,
                    onChanged: (_) => c.toggle(),
                    activeColor: c.accent,
                  ),
                ),
              ]),
              const SizedBox(height: 12),

              // Blind user
              _GroupLabel(label: 'BLIND USER', c: c),
              _GroupCard(c: c, children: [
                _RowItem(label: 'Name',        value: _blind?['name']        ?? '—', c: c),
                _RowItem(label: 'Phone',       value: _blind?['phone']       ?? '—', c: c),
                _RowItem(label: 'Language',
                  value: _blind?['language'] == 'rw' ? 'Kinyarwanda' : 'English', c: c),
                _RowItem(label: 'Voice Speed', value: _blind?['voice_speed'] ?? '—', c: c),
                _RowItem(label: 'Status',      value: _blind?['status']      ?? '—', c: c, last: true),
              ]),
              const SizedBox(height: 12),

              // Emergency contact
              _GroupLabel(label: 'EMERGENCY CONTACT', c: c),
              _GroupCard(c: c, children: [
                _RowItem(label: 'Guardian phone (auto)',
                  value: _guardian?['phone'] ?? '—', c: c, last: true),
              ]),
              const SizedBox(height: 12),

              // Notifications
              _GroupLabel(label: 'NOTIFICATIONS', c: c),
              _GroupCard(c: c, children: [
                _RowItem(label: 'Push Notifications', c: c,
                  trailing: Switch(value: _push, onChanged: (v) => setState(() => _push = v),
                    activeColor: c.accent)),
                _RowItem(label: 'Vibration', c: c, last: true,
                  trailing: Switch(value: _vib, onChanged: (v) => setState(() => _vib = v),
                    activeColor: c.accent)),
              ]),
              const SizedBox(height: 12),

              // Sign out
              // GAP 3.4 FIX: use Material+InkWell for press ripple feedback
              // matching RN TouchableOpacity activeOpacity behaviour.
              Material(
                color: c.danger.withOpacity(0.063), // RN: DANGER+'10' = 6.3%
                borderRadius: BorderRadius.circular(20),
                child: InkWell(
                  onTap: _signOut,
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        // RN: DANGER+'44' = 0x44/0xFF = 26.7% opacity
                        color: c.danger.withOpacity(0.267),
                      ),
                    ),
                    child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Icon(Icons.logout_outlined, color: c.danger, size: 18),
                      const SizedBox(width: 8),
                      Text('Sign Out',
                        style: TextStyle(color: c.danger, fontSize: 14, fontWeight: FontWeight.w600)),
                    ]),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Center(
                child: Text('E-mboni v1.0.0',
                  style: TextStyle(color: c.muted, fontSize: 11)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GroupLabel extends StatelessWidget {
  final String label;
  final ThemeProvider c;
  const _GroupLabel({required this.label, required this.c});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 6, left: 4),
    child: Text(label,
      style: TextStyle(color: c.muted, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1)),
  );
}

class _GroupCard extends StatelessWidget {
  final List<Widget> children;
  final ThemeProvider c;
  const _GroupCard({required this.children, required this.c});

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: c.card,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: c.border),
    ),
    clipBehavior: Clip.hardEdge,
    child: Column(children: children),
  );
}

class _RowItem extends StatelessWidget {
  final String label;
  final String? sub;
  final String? value;
  final ThemeProvider c;
  final bool last;
  final Widget? trailing;
  const _RowItem({required this.label, required this.c, this.sub, this.value,
    this.last = false, this.trailing});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
    decoration: BoxDecoration(
      border: last ? null : Border(bottom: BorderSide(color: c.border)),
    ),
    child: Row(children: [
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: TextStyle(color: c.text, fontSize: 15)),
        if (sub != null) ...[
          const SizedBox(height: 2),
          Text(sub!, style: TextStyle(color: c.muted, fontSize: 11)),
        ],
      ])),
      if (value != null)
        Text(value!,
          style: TextStyle(color: c.muted, fontSize: 13),
          textAlign: TextAlign.right),
      if (trailing != null) trailing!,
    ]),
  );
}

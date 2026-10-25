import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/api.dart';
import '../../services/theme_provider.dart';

class GuardianDashboardScreen extends StatefulWidget {
  const GuardianDashboardScreen({super.key});

  @override
  State<GuardianDashboardScreen> createState() => _GuardianDashboardScreenState();
}

class _GuardianDashboardScreenState extends State<GuardianDashboardScreen> {
  Map<String, dynamic>? _dashboard;
  bool _refreshing = false;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final data = await apiFetch('/guardian/dashboard');
      if (mounted) setState(() { _dashboard = data; _error = ''; });
    } catch (e) {
      if (mounted) setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> _onRefresh() async {
    setState(() => _refreshing = true);
    await _load();
    setState(() => _refreshing = false);
  }

  void _handleCall() async {
    final phone = _dashboard?['blind_user']?['phone'];
    if (phone == null) return;
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) launchUrl(uri);
  }

  String _initials(String? name) =>
    name?.split(' ').map((n) => n.isNotEmpty ? n[0] : '').join().toUpperCase() ?? '?';

  @override
  Widget build(BuildContext context) {
    final c = context.watch<ThemeProvider>();

    if (_dashboard == null && _error.isEmpty) {
      return Scaffold(
        backgroundColor: c.background,
        body: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.sync, color: c.accent, size: 32),
          const SizedBox(height: 8),
          Text('Loading dashboard...', style: TextStyle(color: c.muted, fontSize: 14)),
        ])),
      );
    }

    if (_error.isNotEmpty && _dashboard == null) {
      return Scaffold(
        backgroundColor: c.background,
        body: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.cloud_off_outlined, color: c.danger, size: 40),
          const SizedBox(height: 8),
          Text(_error, style: TextStyle(color: c.danger, fontSize: 14), textAlign: TextAlign.center),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: _load,
            style: ElevatedButton.styleFrom(backgroundColor: c.accent),
            child: const Text('Retry', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
          ),
        ])),
      );
    }

    final guardian  = _dashboard?['guardian'];
    final blind     = _dashboard?['blind_user'];
    final alerts    = (_dashboard?['recent_alerts'] as List?) ?? [];
    final session   = _dashboard?['active_session'];
    final isScanning = session?['status'] == 'active';
    final statusColor = isScanning ? c.safe : c.muted;
    final dangerCount = alerts.where((a) => a['level'] == 'danger').length;

    return Scaffold(
      backgroundColor: c.background,
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        color: c.accent,
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            // paddingTop:60 matches RN contentContainerStyle paddingTop:60
            padding: const EdgeInsets.fromLTRB(20, 60, 20, 120),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Guardian', style: TextStyle(color: c.muted, fontSize: 12, fontWeight: FontWeight.w500)),
                      const SizedBox(height: 2),
                      Text(guardian?['name'] ?? '—',
                        style: TextStyle(color: c.text, fontSize: 24, fontWeight: FontWeight.w700)),
                    ]),
                    // GAP 3.5 FIX: Material+InkWell for press ripple feedback.
                    // GAP 2.5 FIX: exact opacity values — 0x22/0xFF=13.3%, 0x44/0xFF=26.7%
                    Material(
                      color: c.accent.withOpacity(0.1333), // RN: accent+'22'
                      shape: const CircleBorder(),
                      child: InkWell(
                        onTap: () async { await clearSession(); if (mounted) context.go('/auth'); },
                        customBorder: const CircleBorder(),
                        child: Container(
                          width: 44, height: 44,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: c.accent.withOpacity(0.2667), // RN: accent+'44'
                            ),
                          ),
                          child: Center(
                            child: Text(_initials(guardian?['name']),
                              style: TextStyle(color: c.accent, fontSize: 14, fontWeight: FontWeight.w700)),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Blind user card
                Container(
                  decoration: BoxDecoration(
                    color: c.card,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: c.border),
                  ),
                  child: blind == null
                    ? Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(children: [
                          Icon(Icons.person_add_outlined, color: c.muted, size: 28),
                          const SizedBox(height: 8),
                          Text('No blind user linked to your account.',
                            style: TextStyle(color: c.muted, fontSize: 13), textAlign: TextAlign.center),
                        ]),
                      )
                    : Column(children: [
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(children: [
                            Container(
                              width: 46, height: 46,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: c.accent.withOpacity(0.1),
                                border: Border.all(color: c.accent.withOpacity(0.2)),
                              ),
                              child: Center(
                                child: Text(_initials(blind['name']),
                                  style: TextStyle(color: c.accent, fontSize: 15, fontWeight: FontWeight.w700)),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text(blind['name'] ?? '—',
                                style: TextStyle(color: c.text, fontSize: 15, fontWeight: FontWeight.w600)),
                              const SizedBox(height: 2),
                              Text(blind['phone'] ?? '—', style: TextStyle(color: c.muted, fontSize: 12)),
                            ])),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: statusColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: statusColor.withOpacity(0.27)),
                              ),
                              child: Row(mainAxisSize: MainAxisSize.min, children: [
                                Container(width: 6, height: 6,
                                  decoration: BoxDecoration(shape: BoxShape.circle, color: statusColor)),
                                const SizedBox(width: 5),
                                Text(isScanning ? 'Scanning' : 'Offline',
                                  style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.w600)),
                              ]),
                            ),
                          ]),
                        ),
                        Divider(height: 1, color: c.border),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          child: Row(children: [
                            Icon(Icons.language_outlined, color: c.muted, size: 14),
                            const SizedBox(width: 6),
                            Text('${(blind['language'] ?? 'en').toString().toUpperCase()} · ${blind['voice_speed'] ?? 'Normal'} speed',
                              style: TextStyle(color: c.muted, fontSize: 12)),
                            const Spacer(),
                            Icon(Icons.shield_outlined, color: c.muted, size: 14),
                            const SizedBox(width: 6),
                            Text(blind['status'] ?? 'active', style: TextStyle(color: c.muted, fontSize: 12)),
                          ]),
                        ),
                      ]),
                ),
                const SizedBox(height: 14),

                // Action pills
                Row(children: [
                  _ActionPill(icon: Icons.call, label: 'Call',   onTap: _handleCall,
                    disabled: blind?['phone'] == null, c: c),
                  const SizedBox(width: 10),
                  _ActionPill(icon: Icons.navigation, label: 'Track',
                    onTap: () => context.push('/guardian/tracking'), primary: true, c: c),
                  const SizedBox(width: 10),
                  _ActionPill(icon: Icons.notifications, label: 'Alerts',
                    onTap: () => context.push('/guardian/alerts'),
                    badge: dangerCount > 0 ? dangerCount : null, c: c),
                ]),
                const SizedBox(height: 14),

                // Recent alerts
                Text('Recent Activity',
                  style: TextStyle(color: c.muted, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.8)),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    color: c.card,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: c.border),
                  ),
                  child: alerts.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.all(24),
                        child: Center(child: Text('No alerts yet.',
                          style: TextStyle(color: c.muted, fontSize: 13))),
                      )
                    : Column(
                        children: List.generate(alerts.take(5).length, (i) {
                          final a  = alerts[i];
                          final dc = a['level'] == 'safe' ? c.safe
                              : a['level'] == 'warning' ? c.warning : c.danger;
                          final time = a['created_at'] != null
                            ? TimeOfDay.fromDateTime(DateTime.parse(a['created_at'])).format(context)
                            : '';
                          final isLast = i == (alerts.take(5).length - 1);
                          return Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              border: isLast ? null : Border(bottom: BorderSide(color: c.border)),
                            ),
                            child: Row(children: [
                              Container(
                                width: 32, height: 32,
                                decoration: BoxDecoration(
                                  color: dc.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Center(child: Container(
                                  width: 8, height: 8,
                                  decoration: BoxDecoration(shape: BoxShape.circle, color: dc),
                                )),
                              ),
                              const SizedBox(width: 12),
                              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text(a['message'] ?? '', style: TextStyle(color: c.text, fontSize: 14, fontWeight: FontWeight.w500)),
                                const SizedBox(height: 2),
                                Text(time, style: TextStyle(color: c.muted, fontSize: 11)),
                              ])),
                            ]),
                          );
                        }),
                      ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ActionPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool primary;
  final bool disabled;
  final int? badge;
  final ThemeProvider c;

  const _ActionPill({
    required this.icon, required this.label, required this.onTap, required this.c,
    this.primary = false, this.disabled = false, this.badge,
  });

  @override
  Widget build(BuildContext context) => Expanded(
    child: Opacity(
      opacity: disabled ? 0.4 : 1,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // InkWell gives activeOpacity:0.75 equivalent press feedback
          Material(
            color: primary ? c.accent : c.card,
            borderRadius: BorderRadius.circular(20),
            child: InkWell(
              onTap: disabled ? null : onTap,
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: primary ? c.accent : c.border),
                ),
                child: Column(children: [
                  Icon(icon, color: primary ? Colors.white : c.muted, size: 20),
                  const SizedBox(height: 6),
                  Text(label,
                    style: TextStyle(color: primary ? Colors.white : c.text,
                      fontSize: 12, fontWeight: FontWeight.w600)),
                ]),
              ),
            ),
          ),
          if (badge != null)
            Positioned(
              top: 6, right: 6,
              child: Container(
                width: 16, height: 16,
                decoration: BoxDecoration(shape: BoxShape.circle, color: c.danger),
                child: Center(child: Text('$badge',
                  style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w700))),
              ),
            ),
        ],
      ),
    ),
  );
}

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

const _accent  = Color(0xFFA855F7);
const _bg      = Color(0xFF0C0B12);
const _card    = Color(0xFF13111C);
const _border  = Color(0xFF1E1A2E);
const _text    = Color(0xFFEDE9F8);
const _muted   = Color(0xFF6B6480);
const _safe    = Color(0xFF4ADE80);
const _warning = Color(0xFFFBBF24);
const _danger  = Color(0xFFF87171);
const _blue    = Color(0xFF60A5FA);

const _activeUsers = [
  {'name': 'James Kamau',  'status': 'Navigating', 'initials': 'JK'},
  {'name': 'Alice Uwera',  'status': 'Scanning',   'initials': 'AU'},
  {'name': 'Eric Mugisha', 'status': 'Idle',        'initials': 'EM'},
];

const _recentAlerts = [
  {'user': 'James Kamau',  'msg': 'Moving car — 3m ahead',  'time': '2 min ago',  'level': 'danger'},
  {'user': 'Alice Uwera',  'msg': 'Chair detected — 1.5m',  'time': '8 min ago',  'level': 'warning'},
  {'user': 'Eric Mugisha', 'msg': 'Navigation started',      'time': '15 min ago', 'level': 'safe'},
  {'user': 'Grace Ineza',  'msg': 'Stairs — 1m ahead',      'time': '22 min ago', 'level': 'danger'},
];

class AdminOverviewScreen extends StatelessWidget {
  const AdminOverviewScreen({super.key});

  Color _levelColor(String l) =>
      l == 'danger' ? _danger : l == 'warning' ? _warning : _safe;

  @override
  Widget build(BuildContext context) {
    final stats = [
      {'label': 'Total Users',  'value': '128', 'icon': Icons.people,          'color': _accent},
      {'label': 'Active Now',   'value': '14',  'icon': Icons.radio_button_on, 'color': _safe},
      {'label': 'Guardians',    'value': '76',  'icon': Icons.shield,          'color': _blue},
      {'label': 'Alerts Today', 'value': '32',  'icon': Icons.notifications,   'color': _warning},
    ];

    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: SingleChildScrollView(
          // RN: paddingTop:60 — was incorrectly 20
          padding: const EdgeInsets.fromLTRB(20, 60, 20, 120),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Admin Panel',
                        style: TextStyle(color: _muted, fontSize: 12, fontWeight: FontWeight.w500)),
                    SizedBox(height: 2),
                    Text('Overview',
                        style: TextStyle(color: _text, fontSize: 26, fontWeight: FontWeight.w700)),
                  ]),
                  Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _accent.withOpacity(0.13),
                      border: Border.all(color: _accent.withOpacity(0.27)),
                    ),
                    child: const Icon(Icons.person, color: _accent, size: 20),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Stats grid — RN: flexDirection:'row', flexWrap:'wrap', gap:12
              // width:'47%' on each card → GridView 2-column with spacing:12
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                // childAspectRatio tuned so card height matches RN natural flex height
                childAspectRatio: 1.55,
                children: stats.map((s) {
                  final color = s['color'] as Color;
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _card,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: _border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 40, height: 40,
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(s['icon'] as IconData, color: color, size: 20),
                        ),
                        const SizedBox(height: 8),
                        Text(s['value'] as String,
                            style: const TextStyle(color: _text, fontSize: 26, fontWeight: FontWeight.w800)),
                        Text(s['label'] as String,
                            style: const TextStyle(color: _muted, fontSize: 12)),
                      ],
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 14),

              // Active users
              const Text('ACTIVE USERS',
                  style: TextStyle(color: _muted, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.8)),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: _card,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _border),
                ),
                child: Column(
                  children: List.generate(_activeUsers.length, (i) {
                    final u      = _activeUsers[i];
                    final isLast = i == _activeUsers.length - 1;
                    final dotColor = u['status'] == 'Navigating'
                        ? _safe
                        : u['status'] == 'Scanning'
                            ? _warning
                            : _muted;
                    return Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        border: isLast ? null : const Border(bottom: BorderSide(color: _border)),
                      ),
                      child: Row(children: [
                        Container(
                          width: 42, height: 42,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _accent.withOpacity(0.13),
                          ),
                          child: Center(
                            child: Text(u['initials']!,
                                style: const TextStyle(color: _accent, fontSize: 14, fontWeight: FontWeight.w700)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(u['name']!,
                              style: const TextStyle(color: _text, fontSize: 14, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 2),
                          Text(u['status']!, style: const TextStyle(color: _muted, fontSize: 12)),
                        ])),
                        Container(
                          width: 8, height: 8,
                          decoration: BoxDecoration(shape: BoxShape.circle, color: dotColor),
                        ),
                      ]),
                    );
                  }),
                ),
              ),
              const SizedBox(height: 14),

              // Recent alerts
              const Text('RECENT ALERTS',
                  style: TextStyle(color: _muted, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.8)),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: _card,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _border),
                ),
                child: Column(
                  children: List.generate(_recentAlerts.length, (i) {
                    final a      = _recentAlerts[i];
                    final isLast = i == _recentAlerts.length - 1;
                    final color  = _levelColor(a['level']!);
                    return Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        border: isLast ? null : const Border(bottom: BorderSide(color: _border)),
                      ),
                      child: Row(children: [
                        Container(
                          width: 36, height: 36,
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Center(child: Container(
                            width: 8, height: 8,
                            decoration: BoxDecoration(shape: BoxShape.circle, color: color),
                          )),
                        ),
                        const SizedBox(width: 12),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(a['user']!,
                              style: const TextStyle(color: _text, fontSize: 13, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 2),
                          Text(a['msg']!, style: const TextStyle(color: _muted, fontSize: 12)),
                        ])),
                        Text(a['time']!, style: const TextStyle(color: _muted, fontSize: 11)),
                      ]),
                    );
                  }),
                ),
              ),
              const SizedBox(height: 14),

              // Sign out
              GestureDetector(
                onTap: () => context.go('/auth'),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: _card,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _border),
                  ),
                  child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(Icons.logout_outlined, color: _muted, size: 18),
                    SizedBox(width: 8),
                    Text('Sign Out',
                        style: TextStyle(color: _muted, fontSize: 14, fontWeight: FontWeight.w600)),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

const _accent  = Color(0xFFA855F7);
const _bg      = Color(0xFF0C0B12);
const _card    = Color(0xFF13111C);
const _border  = Color(0xFF1E1A2E);
const _text    = Color(0xFFEDE9F8);
const _muted   = Color(0xFF6B6480);
const _safe    = Color(0xFF4ADE80);
const _blue    = Color(0xFF60A5FA);

const _users = [
  {'name': 'James Kamau',   'role': 'blind',    'guardian': 'Sarah Kamau',   'status': 'active',   'initials': 'JK', 'lang': 'EN'},
  {'name': 'Sarah Kamau',   'role': 'guardian', 'guardian': '—',             'status': 'active',   'initials': 'SK', 'lang': 'EN'},
  {'name': 'Alice Uwera',   'role': 'blind',    'guardian': 'Paul Uwera',    'status': 'active',   'initials': 'AU', 'lang': 'RW'},
  {'name': 'Paul Uwera',    'role': 'guardian', 'guardian': '—',             'status': 'active',   'initials': 'PU', 'lang': 'RW'},
  {'name': 'Eric Mugisha',  'role': 'blind',    'guardian': 'Marie Mugisha', 'status': 'inactive', 'initials': 'EM', 'lang': 'RW'},
  {'name': 'Marie Mugisha', 'role': 'guardian', 'guardian': '—',             'status': 'inactive', 'initials': 'MM', 'lang': 'RW'},
];

class AdminUsersScreen extends StatelessWidget {
  const AdminUsersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final blindCount    = _users.where((u) => u['role'] == 'blind').length;
    final guardianCount = _users.where((u) => u['role'] == 'guardian').length;
    final activeCount   = _users.where((u) => u['status'] == 'active').length;

    final summaryItems = [
      {'label': 'Blind Users', 'value': blindCount,    'icon': Icons.mic,            'color': _accent},
      {'label': 'Guardians',   'value': guardianCount, 'icon': Icons.shield,         'color': _blue},
      {'label': 'Active',      'value': activeCount,   'icon': Icons.radio_button_on, 'color': _safe},
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
              const Text('Users',
                  style: TextStyle(color: _text, fontSize: 26, fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text('${_users.length} registered accounts',
                  style: const TextStyle(color: _muted, fontSize: 13)),
              const SizedBox(height: 14),

              // Summary pills — RN: flexDirection:'row', gap:10
              Row(
                children: List.generate(summaryItems.length, (idx) {
                  final s     = summaryItems[idx];
                  final color = s['color'] as Color;
                  return Expanded(
                    child: Container(
                      margin: EdgeInsets.only(right: idx < summaryItems.length - 1 ? 10 : 0),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: _card,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: _border),
                      ),
                      child: Column(children: [
                        Icon(s['icon'] as IconData, color: color, size: 18),
                        const SizedBox(height: 4),
                        Text('${s['value']}',
                            style: const TextStyle(color: _text, fontSize: 20, fontWeight: FontWeight.w800)),
                        Text(s['label'] as String,
                            style: const TextStyle(color: _muted, fontSize: 10)),
                      ]),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 14),

              // User list
              Container(
                decoration: BoxDecoration(
                  color: _card,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _border),
                ),
                child: Column(
                  children: List.generate(_users.length, (i) {
                    final u         = _users[i];
                    final isLast    = i == _users.length - 1;
                    final isBlind   = u['role'] == 'blind';
                    final roleColor = isBlind ? _accent : _blue;
                    final dotColor  = u['status'] == 'active' ? _safe : _muted;
                    return Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        border: isLast ? null : const Border(bottom: BorderSide(color: _border)),
                      ),
                      child: Row(children: [
                        Container(
                          width: 44, height: 44,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: roleColor.withOpacity(0.13),
                          ),
                          child: Center(
                            child: Text(u['initials']!,
                                style: TextStyle(color: roleColor, fontSize: 14, fontWeight: FontWeight.w700)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Row(children: [
                            Text(u['name']!,
                                style: const TextStyle(color: _text, fontSize: 14, fontWeight: FontWeight.w600)),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: roleColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(isBlind ? 'Blind' : 'Guardian',
                                  style: TextStyle(color: roleColor, fontSize: 10, fontWeight: FontWeight.w700)),
                            ),
                          ]),
                          const SizedBox(height: 2),
                          Text(
                            isBlind
                                ? 'Guardian: ${u['guardian']}  ·  ${u['lang']}'
                                : 'Guardian account  ·  ${u['lang']}',
                            style: const TextStyle(color: _muted, fontSize: 11),
                          ),
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
            ],
          ),
        ),
      ),
    );
  }
}

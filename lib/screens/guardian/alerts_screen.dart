import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/api.dart';
import '../../services/theme_provider.dart';

class AlertsScreen extends StatefulWidget {
  const AlertsScreen({super.key});

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {
  List<dynamic> _alerts   = [];
  String _blindName       = '';
  bool   _loading         = true;
  bool   _refreshing      = false;
  String _error           = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final results = await Future.wait([
        apiFetch('/guardian/dashboard'),
        apiFetch('/alerts'),
      ]);
      if (mounted) setState(() {
        _blindName = results[0]['blind_user']?['name'] ?? '';
        _alerts    = results[1] as List? ?? [];
        _error     = '';
      });
    } catch (e) {
      if (mounted) setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() { _loading = false; _refreshing = false; });
    }
  }

  Future<void> _onRefresh() async {
    setState(() => _refreshing = true);
    await _load();
  }

  Color _levelColor(String level, ThemeProvider c) {
    if (level == 'danger')  return c.danger;
    if (level == 'warning') return c.warning;
    return c.safe;
  }

  IconData _levelIcon(String level) {
    if (level == 'danger')  return Icons.error;
    if (level == 'warning') return Icons.warning;
    return Icons.check_circle;
  }

  @override
  Widget build(BuildContext context) {
    final c = context.watch<ThemeProvider>();

    if (_loading) {
      return Scaffold(
        backgroundColor: c.background,
        body: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.sync, color: c.accent, size: 32),
          const SizedBox(height: 8),
          Text('Loading alerts...', style: TextStyle(color: c.muted, fontSize: 14)),
        ])),
      );
    }

    return Scaffold(
      backgroundColor: c.background,
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        color: c.accent,
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 60, 20, 120),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Alerts',
                  style: TextStyle(color: c.text, fontSize: 26, fontWeight: FontWeight.w700)),
                if (_blindName.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(_blindName, style: TextStyle(color: c.muted, fontSize: 13)),
                ],
                const SizedBox(height: 12),

                if (_error.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: c.danger.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: c.danger.withOpacity(0.27)),
                    ),
                    child: Row(children: [
                      Icon(Icons.cloud_off_outlined, color: c.danger, size: 16),
                      const SizedBox(width: 8),
                      Expanded(child: Text(_error, style: TextStyle(color: c.danger, fontSize: 13))),
                      GestureDetector(
                        onTap: _load,
                        child: Text('Retry',
                          style: TextStyle(color: c.accent, fontSize: 13, fontWeight: FontWeight.w700)),
                      ),
                    ]),
                  ),

                Container(
                  decoration: BoxDecoration(
                    color: c.card,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: c.border),
                  ),
                  child: _alerts.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(children: [
                          Icon(Icons.notifications_off_outlined, color: c.muted, size: 32),
                          const SizedBox(height: 10),
                          Text('No alerts yet.\nThey will appear here when the blind user is navigating.',
                            style: TextStyle(color: c.muted, fontSize: 13, height: 1.5),
                            textAlign: TextAlign.center),
                        ]),
                      )
                    : Column(
                        children: List.generate(_alerts.length, (i) {
                          final a      = _alerts[i];
                          final level  = a['level'] as String? ?? 'safe';
                          final color  = _levelColor(level, c);
                          final icon   = _levelIcon(level);
                          final isLast = i == _alerts.length - 1;
                          String time = '';
                          if (a['created_at'] != null) {
                            final dt = DateTime.tryParse(a['created_at']);
                            if (dt != null) {
                              time = '${_monthName(dt.month)} ${dt.day}, '
                                '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
                            }
                          }
                          return Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              border: isLast ? null : Border(bottom: BorderSide(color: c.border)),
                            ),
                            child: Row(children: [
                              Container(
                                width: 36, height: 36,
                                decoration: BoxDecoration(
                                  color: color.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(icon, color: color, size: 16),
                              ),
                              const SizedBox(width: 12),
                              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text(a['message'] ?? '',
                                  style: TextStyle(color: c.text, fontSize: 14, fontWeight: FontWeight.w500, height: 1.4)),
                                const SizedBox(height: 2),
                                Text(time, style: TextStyle(color: c.muted, fontSize: 11)),
                              ])),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: color.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(level.toUpperCase(),
                                  style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w700)),
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
      ),
    );
  }

  String _monthName(int m) =>
    ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'][m - 1];
}

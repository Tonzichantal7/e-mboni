import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/api.dart';
import '../../services/theme_provider.dart';

class TrackingScreen extends StatefulWidget {
  const TrackingScreen({super.key});

  @override
  State<TrackingScreen> createState() => _TrackingScreenState();
}

class _TrackingScreenState extends State<TrackingScreen> {
  Map<String, dynamic>? _trackData;
  Map<String, double>?  _location;
  String _locError  = '';
  bool   _loading   = true;
  bool   _refreshing = false;
  String _error     = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final data = await apiFetch('/guardian/tracking');
      if (mounted) setState(() { _trackData = data; _error = ''; });

      final prefs   = await SharedPreferences.getInstance();
      final raw     = prefs.getString('@emboni_location_consent');
      final consent = raw == null ? false : raw == 'true';
      if (consent) {
        final permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied ||
            permission == LocationPermission.deniedForever) {
          if (mounted) setState(() => _locError = 'Location permission denied on this device.');
        } else {
          try {
            final pos = await Geolocator.getCurrentPosition(
              desiredAccuracy: LocationAccuracy.high);
            if (mounted) setState(() {
              _location = {'lat': pos.latitude, 'lng': pos.longitude};
              _locError = '';
            });
          } catch (_) {
            if (mounted) setState(() => _locError = 'Could not get location. Make sure GPS is on.');
          }
        }
      }
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

  void _openMaps() {
    if (_location == null) return;
    launchUrl(Uri.parse('https://www.google.com/maps?q=${_location!['lat']},${_location!['lng']}'));
  }

  Color _dc(String level, ThemeProvider c) {
    if (level == 'safe')    return c.safe;
    if (level == 'warning') return c.warning;
    if (level == 'danger')  return c.danger;
    return c.muted;
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
          Text('Loading tracking data...', style: TextStyle(color: c.muted, fontSize: 14)),
        ])),
      );
    }

    final blindName  = _trackData?['blind_name']  ?? '—';
    final isScanning = _trackData?['is_scanning'] ?? false;
    final session    = _trackData?['session']     ?? {'status': 'Offline', 'duration_minutes': 0, 'alert_count': 0};
    final timeline   = (_trackData?['timeline']   as List?) ?? [];
    final scanColor  = isScanning ? c.safe : c.muted;

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
                Text('Tracking',
                  style: TextStyle(color: c.text, fontSize: 26, fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(blindName, style: TextStyle(color: c.muted, fontSize: 13)),
                const SizedBox(height: 14),

                // Scanning banner
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: scanColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: scanColor.withOpacity(0.27)),
                  ),
                  child: Row(children: [
                    Icon(isScanning ? Icons.radio : Icons.radio_outlined, color: scanColor, size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        isScanning
                          ? '$blindName is actively scanning right now'
                          : '$blindName is not currently scanning',
                        style: TextStyle(color: scanColor, fontSize: 13, fontWeight: FontWeight.w600)),
                    ),
                  ]),
                ),
                const SizedBox(height: 14),

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
                          style: TextStyle(color: c.accent, fontWeight: FontWeight.w700, fontSize: 13)),
                      ),
                    ]),
                  ),

                // Location card
                Container(
                  decoration: BoxDecoration(
                    color: c.card,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: c.border),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(28),
                    child: _locError.isNotEmpty
                      ? _locationState(Icons.warning_outlined, c.warning, 'Location Unavailable', _locError, c)
                      : _location == null
                      ? _locationState(Icons.location_off_outlined, c.muted, 'Location Not Shared',
                          'The blind user has not allowed location sharing.', c)
                      : Column(children: [
                          Container(
                            width: 64, height: 64,
                            decoration: BoxDecoration(
                              color: c.safe.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Icon(Icons.location_on, color: c.safe, size: 32),
                          ),
                          const SizedBox(height: 12),
                          Text('Live Location',
                            style: TextStyle(color: c.text, fontSize: 16, fontWeight: FontWeight.w700)),
                          const SizedBox(height: 12),
                          Container(
                            decoration: BoxDecoration(
                              color: c.background,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: c.border),
                            ),
                            child: Column(children: [
                              _coordRow('Latitude',  _location!['lat']!.toStringAsFixed(6), c),
                              Divider(height: 1, color: c.border),
                              _coordRow('Longitude', _location!['lng']!.toStringAsFixed(6), c),
                            ]),
                          ),
                          const SizedBox(height: 12),
                          GestureDetector(
                            onTap: _openMaps,
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                              decoration: BoxDecoration(
                                color: c.accent,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Row(mainAxisSize: MainAxisSize.min, children: [
                                const Icon(Icons.map, color: Colors.white, size: 16),
                                const SizedBox(width: 8),
                                const Text('Open in Google Maps',
                                  style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700)),
                              ]),
                            ),
                          ),
                        ]),
                  ),
                ),
                const SizedBox(height: 14),

                // Stat pills
                Row(children: [
                  _StatPill(label: 'Status',   value: session['status'] ?? 'Offline',
                    color: isScanning ? c.safe : c.muted, c: c),
                  const SizedBox(width: 10),
                  _StatPill(label: 'Duration', value: '${session['duration_minutes'] ?? 0} min',
                    color: c.accent, c: c),
                  const SizedBox(width: 10),
                  _StatPill(label: 'Alerts',   value: '${session['alert_count'] ?? 0}',
                    color: (session['alert_count'] ?? 0) > 0 ? c.warning : c.muted, c: c),
                ]),
                const SizedBox(height: 14),

                // Timeline
                Text('Session Timeline',
                  style: TextStyle(color: c.muted, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.8)),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    color: c.card,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: c.border),
                  ),
                  child: timeline.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.all(24),
                        child: Center(child: Text('No activity yet.',
                          style: TextStyle(color: c.muted, fontSize: 13))),
                      )
                    : Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: List.generate(timeline.length, (i) {
                            final item   = timeline[i];
                            final isLast = i == timeline.length - 1;
                            final dotColor = _dc(item['level'] ?? 'safe', c);
                            return Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(
                                  width: 14,
                                  child: Column(children: [
                                    Container(
                                      width: 10, height: 10,
                                      decoration: BoxDecoration(shape: BoxShape.circle, color: dotColor),
                                    ),
                                    if (!isLast)
                                      Container(
                                        width: 2, height: 40,
                                        margin: const EdgeInsets.only(top: 4),
                                        color: c.border,
                                      ),
                                  ]),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Padding(
                                    padding: EdgeInsets.only(bottom: isLast ? 0 : 18),
                                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                      Text(item['event'] ?? '',
                                        style: TextStyle(color: c.text, fontSize: 14,
                                          fontWeight: FontWeight.w500, height: 1.4)),
                                      const SizedBox(height: 2),
                                      Text(item['time'] ?? '',
                                        style: TextStyle(color: c.muted, fontSize: 11)),
                                    ]),
                                  ),
                                ),
                              ],
                            );
                          }),
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

  Widget _locationState(IconData icon, Color color, String title, String sub, ThemeProvider c) =>
    Column(children: [
      Container(
        width: 64, height: 64,
        decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
        child: Icon(icon, color: color, size: 32),
      ),
      const SizedBox(height: 12),
      Text(title, style: TextStyle(color: c.text, fontSize: 16, fontWeight: FontWeight.w700)),
      const SizedBox(height: 6),
      Text(sub, style: TextStyle(color: c.muted, fontSize: 12, height: 1.5), textAlign: TextAlign.center),
    ]);

  Widget _coordRow(String label, String value, ThemeProvider c) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: TextStyle(color: c.muted, fontSize: 12)),
      Text(value,  style: TextStyle(color: c.text,  fontSize: 14, fontWeight: FontWeight.w600)),
    ]),
  );
}

class _StatPill extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final ThemeProvider c;
  const _StatPill({required this.label, required this.value, required this.color, required this.c});

  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: c.border),
      ),
      child: Column(children: [
        Text(value, style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(color: c.muted, fontSize: 11)),
      ]),
    ),
  );
}

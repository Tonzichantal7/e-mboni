import 'dart:async';
import 'dart:convert';
import 'package:camera/camera.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import '../../constants/colors.dart';
import '../../services/api.dart';
import '../../services/haptic_service.dart';
import '../../services/lang_provider.dart';
import '../../services/speech_service.dart';

// Detection endpoint — uses same base URL as apiFetch
const String _detectUrl = 'http://192.168.0.104:8000/detect';

class NavigationScreen extends StatefulWidget {
  const NavigationScreen({super.key});

  @override
  State<NavigationScreen> createState() => _NavigationScreenState();
}

class _NavigationScreenState extends State<NavigationScreen> {
  CameraController? _cam;
  Timer?  _loop;
  bool    _processing = false;
  bool    _offline    = false;
  int     _errCount   = 0;

  Map<String, dynamic>? _result;

  static const _statusColors = {
    'safe':     AppColors.safe,
    'warning':  AppColors.warning,
    'danger':   AppColors.danger,
    'scanning': AppColors.muted,
  };

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    final cameras = await availableCameras();
    if (cameras.isEmpty) return;
    _cam = CameraController(
      cameras.first,
      ResolutionPreset.medium,
      enableAudio: false,
    );
    await _cam!.initialize();
    if (!mounted) return;
    setState(() {});

    final lang = context.read<LangProvider>();
    SpeechService.setLanguage(lang.lang);
    SpeechService.speak(lang.t('navStarted'));
    apiFetch('/session/start', method: 'POST').catchError((_) {});
    _startLoop();
  }

  void _startLoop() {
    _loop = Timer.periodic(const Duration(milliseconds: 3500), (_) async {
      if (_processing || _cam == null || !_cam!.value.isInitialized) return;
      _processing = true;
      try {
        final file  = await _cam!.takePicture();
        final bytes = await file.readAsBytes();
        final token = await getToken();
        final lang  = context.read<LangProvider>().lang;

        final req = http.MultipartRequest('POST', Uri.parse(_detectUrl))
          ..headers['Authorization'] = 'Bearer ${token ?? ''}'
          ..fields['language'] = lang
          ..files.add(http.MultipartFile.fromBytes(
            'image', bytes, filename: 'frame.jpg'));

        final res  = await req.send().timeout(const Duration(seconds: 8));
        final body = jsonDecode(await res.stream.bytesToString())
            as Map<String, dynamic>;

        if (!mounted) return;
        setState(() {
          _result   = body;
          _offline  = false;
          _errCount = 0;
        });

        final summary   = body['summary']    as String?;
        final topDanger = body['top_danger'] as String? ?? 'safe';

        // TTS with urgent flag — matches RN speechService.ts
        if (summary != null) {
          SpeechService.speak(summary, urgent: topDanger == 'danger');
        }

        // Vibration via HapticService — correct patterns
        if (topDanger == 'danger') {
          HapticService.navigationDanger(); // [0,800,200,800,200,800]
        } else if (topDanger == 'warning') {
          HapticService.navigationWarning(); // [0,80]
        }
      } catch (_) {
        _errCount++;
        if (_errCount >= 3 && mounted) setState(() => _offline = true);
      } finally {
        _processing = false;
      }
    });
  }

  Future<void> _stopNavigation() async {
    _loop?.cancel();
    final lang = context.read<LangProvider>();
    SpeechService.speak(lang.t('navStopped'), urgent: true);
    apiFetch('/session/end', method: 'POST').catchError((_) {});
    if (mounted) context.go('/blind/stop');
  }

  @override
  void dispose() {
    _loop?.cancel();
    _cam?.dispose();
    SpeechService.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lang      = context.watch<LangProvider>();
    final topDanger = _result?['top_danger'] as String? ?? 'scanning';
    final dotColor  = _statusColors[topDanger] ?? AppColors.muted;
    final objects   = (_result?['objects'] as List?)
            ?.cast<Map<String, dynamic>>() ??
        [];

    // Camera not ready
    if (_cam == null || !(_cam?.value.isInitialized ?? false)) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Text(
                lang.t('cameraNeeded'),
                style: const TextStyle(color: AppColors.text, fontSize: 18),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _initCamera,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24, vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(
                  lang.t('allowCamera'),
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600),
                ),
              ),
            ]),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Faint camera preview — opacity:0.12 matches RN
          Positioned.fill(
            child: Opacity(
              opacity: 0.12,
              child: CameraPreview(_cam!),
            ),
          ),

          // ── GAP 1.3 FIX: Offline pill is position:absolute top:56 ──────────
          // RN: position:'absolute', top:56, left:20, right:20
          // It floats over the camera preview and does NOT shift the
          // status dot / summary text when it appears.
          if (_offline)
            Positioned(
              top: 56,
              left: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  // RN: '#FBBF2418' = warning.withOpacity(0.094)
                  color: AppColors.warning.withOpacity(0.094),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    // RN: '#FBBF2444' = warning.withOpacity(0.267)
                    color: AppColors.warning.withOpacity(0.267),
                  ),
                ),
                child: const Row(children: [
                  Icon(Icons.cloud_off_outlined,
                      color: AppColors.warning, size: 14),
                  SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Server unreachable — check WiFi',
                      style: TextStyle(
                          color: AppColors.warning,
                          fontSize: 12,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                ]),
              ),
            ),

          // Content overlay — centered, not affected by offline pill
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Status dot — opacity:0.9 matches RN
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: dotColor.withOpacity(0.9),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Summary text
                  Text(
                    _result?['summary'] as String? ?? lang.t('scanning'),
                    style: TextStyle(
                      color: dotColor,
                      fontSize: 22,
                      fontWeight: FontWeight.w500,
                      height: 1.45,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),

                  // Object list — up to 3 items
                  if (objects.isNotEmpty)
                    ...objects.take(3).map((obj) {
                      final danger = obj['danger_level'] as String? ?? 'safe';
                      final dc     = _statusColors[danger] ?? AppColors.muted;
                      final dist   = (obj['distance_meters'] as num?)
                              ?.toDouble() ??
                          0;
                      final distLabel = dist < 1
                          ? lang.t('veryClose')
                          : '${dist.toStringAsFixed(1)} m';
                      final dir      = obj['direction'] as String? ?? 'center';
                      final dirLabel = dir == 'center'
                          ? lang.t('ahead')
                          : dir == 'left'
                              ? lang.t('onYourLeft')
                              : lang.t('onYourRight');
                      final moving = (obj['is_moving'] as bool? ?? false)
                          ? (lang.lang == 'rw' ? 'igenda ' : 'moving ')
                          : '';
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border(
                              left: BorderSide(color: dc, width: 3)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '$moving${obj['name']}',
                              style: TextStyle(
                                  color: dc,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600),
                            ),
                            Text(
                              '$distLabel  ·  $dirLabel',
                              style: const TextStyle(
                                  color: AppColors.muted, fontSize: 13),
                            ),
                          ],
                        ),
                      );
                    }),
                ],
              ),
            ),
          ),

          // Hold-to-stop zone — 800 ms threshold matching RN delayLongPress={800}
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: RawGestureDetector(
              gestures: {
                LongPressGestureRecognizer:
                    GestureRecognizerFactoryWithHandlers<
                        LongPressGestureRecognizer>(
                  () => LongPressGestureRecognizer(
                    duration: const Duration(milliseconds: 800),
                  ),
                  (r) => r.onLongPress = _stopNavigation,
                ),
              },
              child: Semantics(
                button: true,
                label: lang.t('holdToStop'),
                child: Container(
                  height: 140,
                  alignment: Alignment.center,
                  child: Text(
                    lang.t('holdToStop'),
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 14,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

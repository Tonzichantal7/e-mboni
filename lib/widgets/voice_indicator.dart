import 'package:flutter/material.dart';
import '../constants/colors.dart';

/// Animated voice indicator that mirrors the React Native VoiceIndicator
/// component exactly.
///
/// When [active]:
///   • ring1 — scales 1.0 → 1.8, opacity 0.6 → 0, over 800 ms, loops
///   • ring2 — same but starts 300 ms later, scales 1.0 → 2.2, opacity 0.3 → 0
///   • Mic icon: filled (Icons.mic), tint = AppColors.safe
///   • Label: 'Listening...'
///
/// When inactive:
///   • Rings hidden
///   • Mic icon: outline (Icons.mic_none), tint = AppColors.muted
///   • Label: 'Double tap to speak'
class VoiceIndicator extends StatefulWidget {
  final bool active;
  const VoiceIndicator({super.key, required this.active});

  @override
  State<VoiceIndicator> createState() => _VoiceIndicatorState();
}

class _VoiceIndicatorState extends State<VoiceIndicator>
    with TickerProviderStateMixin {
  // ring1 — immediate start
  late AnimationController _ring1Ctrl;
  late Animation<double>   _ring1Scale;
  late Animation<double>   _ring1Opacity;

  // ring2 — 300 ms delayed start
  late AnimationController _ring2Ctrl;
  late Animation<double>   _ring2Scale;
  late Animation<double>   _ring2Opacity;

  @override
  void initState() {
    super.initState();

    // ── ring1: 800 ms, loops ─────────────────────────────────────────────────
    _ring1Ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _ring1Scale = Tween<double>(begin: 1.0, end: 1.8).animate(
      CurvedAnimation(parent: _ring1Ctrl, curve: Curves.easeOut),
    );
    _ring1Opacity = Tween<double>(begin: 0.6, end: 0.0).animate(
      CurvedAnimation(parent: _ring1Ctrl, curve: Curves.easeOut),
    );

    // ── ring2: 800 ms, loops, starts 300 ms after ring1 ─────────────────────
    _ring2Ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _ring2Scale = Tween<double>(begin: 1.0, end: 2.2).animate(
      CurvedAnimation(parent: _ring2Ctrl, curve: Curves.easeOut),
    );
    _ring2Opacity = Tween<double>(begin: 0.3, end: 0.0).animate(
      CurvedAnimation(parent: _ring2Ctrl, curve: Curves.easeOut),
    );

    if (widget.active) _startAnimations();
  }

  @override
  void didUpdateWidget(VoiceIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active && !oldWidget.active) {
      _startAnimations();
    } else if (!widget.active && oldWidget.active) {
      _stopAnimations();
    }
  }

  void _startAnimations() {
    _ring1Ctrl.repeat();
    // 300 ms delay for ring2 — matches RN Animated.delay(300)
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted && widget.active) _ring2Ctrl.repeat();
    });
  }

  void _stopAnimations() {
    _ring1Ctrl.stop();
    _ring2Ctrl.stop();
    _ring1Ctrl.reset();
    _ring2Ctrl.reset();
  }

  @override
  void dispose() {
    _ring1Ctrl.dispose();
    _ring2Ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.active ? AppColors.safe : AppColors.muted;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 80,
          height: 80,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // ── ring1 ──────────────────────────────────────────────────────
              if (widget.active)
                AnimatedBuilder(
                  animation: _ring1Ctrl,
                  builder: (_, __) => Transform.scale(
                    scale: _ring1Scale.value,
                    child: Opacity(
                      opacity: _ring1Opacity.value,
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.safe,
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

              // ── ring2 ──────────────────────────────────────────────────────
              if (widget.active)
                AnimatedBuilder(
                  animation: _ring2Ctrl,
                  builder: (_, __) => Transform.scale(
                    scale: _ring2Scale.value,
                    child: Opacity(
                      opacity: _ring2Opacity.value,
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.safe,
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

              // ── Mic circle ─────────────────────────────────────────────────
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.active
                      ? AppColors.safe.withOpacity(0.094) // matches '#4ADE8018'
                      : Colors.transparent,
                  border: Border.all(color: color, width: 2),
                ),
                child: Icon(
                  widget.active ? Icons.mic : Icons.mic_none,
                  color: color,
                  size: 32,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 10),

        // ── Label ─────────────────────────────────────────────────────────────
        Text(
          widget.active ? 'Listening...' : 'Double tap to speak',
          style: TextStyle(
            color: color,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

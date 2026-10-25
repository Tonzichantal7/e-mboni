import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/theme_provider.dart';

/// Persistent guardian shell with a floating tab bar that exactly replicates
/// the React Native FloatingTabBar in app/(guardian)/_layout.tsx.
///
/// Spec:
///   wrapper  — position:absolute, bottom:0, paddingH:16,
///              paddingBottom: iOS=24 / Android=12, paddingTop:8
///   container — flexDirection:row, borderRadius:28, borderWidth:1,
///               paddingV:6, paddingH:4, elevation:24,
///               shadowOffset:{0,-2}, shadowOpacity:0.15, shadowRadius:20
///   tab       — flex:1, alignItems:center, paddingV:4, gap:2
///   topDot    — w:4, h:4, borderRadius:2, marginBottom:2
///   iconContainer — w:48, h:36, borderRadius:18, bg: accent+'15' when active
///   label     — fontSize:10, letterSpacing:0.1
///
/// GAP 1.4 / GAP 4.5 FIX:
///   The child is rendered in Positioned.fill with NO extra bottom padding.
///   Each guardian screen already applies paddingBottom:120 in its own
///   SingleChildScrollView contentPadding — adding padding here would
///   double-stack it to 120+80+safeArea = far too much whitespace.
class GuardianShell extends StatefulWidget {
  final Widget child;
  final int    currentIndex;
  final void Function(int) onTap;

  const GuardianShell({
    super.key,
    required this.child,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  State<GuardianShell> createState() => _GuardianShellState();
}

class _GuardianShellState extends State<GuardianShell> {
  static const _tabs = [
    _TabDef(icon: Icons.home_outlined,          iconActive: Icons.home,          label: 'Home'),
    _TabDef(icon: Icons.navigation_outlined,    iconActive: Icons.navigation,    label: 'Tracking'),
    _TabDef(icon: Icons.notifications_outlined, iconActive: Icons.notifications, label: 'Alerts'),
    _TabDef(icon: Icons.person_outline,         iconActive: Icons.person,        label: 'Profile'),
  ];

  @override
  Widget build(BuildContext context) {
    final c             = context.watch<ThemeProvider>();
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    // iOS: use safe-area bottom. Android: fixed 12px extra (matches RN Platform.OS check)
    final extraBottom   = bottomPadding > 0 ? 0.0 : 12.0;

    return Stack(
      children: [
        // ── Screen content — fills entire Stack, no extra padding ─────────────
        // Each screen's own SingleChildScrollView has paddingBottom:120 which
        // is enough to clear the floating tab bar.
        Positioned.fill(
          child: widget.child,
        ),

        // ── Floating tab bar ──────────────────────────────────────────────────
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              16,
              8,
              16,
              bottomPadding > 0 ? bottomPadding : extraBottom,
            ),
            child: Container(
              decoration: BoxDecoration(
                color: c.card,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: c.border),
                boxShadow: const [
                  BoxShadow(
                    // shadowOpacity:0.15 = 0x26 alpha
                    color: Color(0x26000000),
                    offset: Offset(0, -2),
                    blurRadius: 20,
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                child: Row(
                  children: List.generate(_tabs.length, (i) {
                    final tab      = _tabs[i];
                    final isActive = widget.currentIndex == i;

                    return Expanded(
                      child: GestureDetector(
                        onTap: () => widget.onTap(i),
                        behavior: HitTestBehavior.opaque,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Active dot indicator on top — w:4, h:4, borderRadius:2
                            Container(
                              width: 4,
                              height: 4,
                              margin: const EdgeInsets.only(bottom: 2),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isActive
                                    ? c.accent
                                    : Colors.transparent,
                              ),
                            ),

                            // Icon container — w:48, h:36, borderRadius:18
                            // accent+'15' = 0x15/0xFF ≈ 8.2% opacity
                            Container(
                              width: 48,
                              height: 36,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(18),
                                color: isActive
                                    ? c.accent.withOpacity(0.082)
                                    : Colors.transparent,
                              ),
                              child: Icon(
                                isActive ? tab.iconActive : tab.icon,
                                size: 24,
                                color: isActive ? c.accent : c.muted,
                              ),
                            ),

                            const SizedBox(height: 2),

                            // Label — fontSize:10, letterSpacing:0.1
                            Text(
                              tab.label,
                              style: TextStyle(
                                color: isActive ? c.accent : c.muted,
                                fontSize: 10,
                                fontWeight: isActive
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                letterSpacing: 0.1,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _TabDef {
  final IconData icon;
  final IconData iconActive;
  final String   label;
  const _TabDef({
    required this.icon,
    required this.iconActive,
    required this.label,
  });
}

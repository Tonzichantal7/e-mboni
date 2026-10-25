import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'constants/colors.dart';
import 'services/lang_provider.dart';
import 'services/theme_provider.dart';
import 'screens/auth/role_select_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/guardian_register_screen.dart';
import 'screens/auth/blind_register_screen.dart';
import 'screens/blind/home_screen.dart';
import 'screens/blind/navigation_screen.dart';
import 'screens/blind/emergency_screen.dart';
import 'screens/blind/stop_screen.dart';
import 'screens/blind/settings_screen.dart';
import 'screens/guardian/guardian_dashboard_screen.dart';
import 'screens/guardian/alerts_screen.dart';
import 'screens/guardian/tracking_screen.dart';
import 'screens/guardian/guardian_settings_screen.dart';
import 'screens/admin/admin_overview_screen.dart';
import 'screens/admin/admin_users_screen.dart';
import 'widgets/guardian_shell.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final lang  = LangProvider();
  final theme = ThemeProvider();
  await lang.loadSaved();
  await theme.load();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: lang),
        ChangeNotifierProvider.value(value: theme),
      ],
      child: const MyApp(),
    ),
  );
}

// ── Router ─────────────────────────────────────────────────────────────────────
// StatefulShellRoute.indexedStack gives each guardian tab its own Navigator
// stack, matching RN's Expo Router (tabs) persistent layout exactly.
// Branch index → route:
//   0 = /guardian          (dashboard)
//   1 = /guardian/tracking
//   2 = /guardian/alerts
//   3 = /guardian/settings

final _router = GoRouter(
  initialLocation: '/auth',
  routes: [
    // ── Auth ──────────────────────────────────────────────────────────────────
    GoRoute(path: '/auth',                   builder: (_, __) => const RoleSelectScreen()),
    GoRoute(path: '/auth/login',             builder: (_, __) => const LoginScreen()),
    GoRoute(path: '/auth/guardian-register', builder: (_, __) => const GuardianRegisterScreen()),
    GoRoute(
      path: '/auth/blind-register',
      builder: (_, state) {
        final p = state.extra as Map<String, String>? ?? {};
        return BlindRegisterScreen(
          guardianName:  p['guardianName']  ?? '',
          guardianPhone: p['guardianPhone'] ?? '',
          password:      p['password']      ?? '',
          relationship:  p['relationship']  ?? '',
        );
      },
    ),

    // ── Blind user ────────────────────────────────────────────────────────────
    GoRoute(path: '/blind',            builder: (_, __) => const HomeScreen()),
    GoRoute(path: '/blind/navigation', builder: (_, __) => const NavigationScreen()),
    GoRoute(path: '/blind/emergency',  builder: (_, __) => const EmergencyScreen()),
    GoRoute(path: '/blind/stop',       builder: (_, __) => const StopScreen()),
    GoRoute(path: '/blind/settings',   builder: (_, __) => const BlindSettingsScreen()),

    // ── Guardian — StatefulShellRoute keeps each tab's Navigator alive ────────
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) => GuardianShell(
        currentIndex: navigationShell.currentIndex,
        // goBranch with initialLocation:true resets to branch root on re-tap,
        // matching RN's tab press behaviour.
        onTap: (i) => navigationShell.goBranch(
          i,
          initialLocation: i == navigationShell.currentIndex,
        ),
        child: navigationShell,
      ),
      branches: [
        StatefulShellBranch(routes: [
          GoRoute(path: '/guardian', builder: (_, __) => const GuardianDashboardScreen()),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(path: '/guardian/tracking', builder: (_, __) => const TrackingScreen()),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(path: '/guardian/alerts', builder: (_, __) => const AlertsScreen()),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(path: '/guardian/settings', builder: (_, __) => const GuardianSettingsScreen()),
        ]),
      ],
    ),

    // ── Admin ─────────────────────────────────────────────────────────────────
    GoRoute(path: '/admin',       builder: (_, __) => const AdminOverviewScreen()),
    GoRoute(path: '/admin/users', builder: (_, __) => const AdminUsersScreen()),
  ],
);

// ── App ────────────────────────────────────────────────────────────────────────

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();
    return MaterialApp.router(
      title: 'E-mboni',
      debugShowCheckedModeBanner: false,
      theme:        buildLightTheme(),
      darkTheme:    buildDarkTheme(),
      themeMode:    theme.isDark ? ThemeMode.dark : ThemeMode.light,
      routerConfig: _router,
    );
  }
}

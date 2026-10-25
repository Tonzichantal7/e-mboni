import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class AppColors {
  // ── Blind user palette ─────────────────────────────────────────────────────
  static const Color background = Color(0xFF0D0F14);
  static const Color surface    = Color(0xFF161920);
  static const Color text       = Color(0xFFECEEF2);
  static const Color muted      = Color(0xFF5A6070);
  static const Color accent     = Color(0xFFA855F7);
  static const Color safe       = Color(0xFF4ADE80);
  static const Color warning    = Color(0xFFFBBF24);
  static const Color danger     = Color(0xFFF87171);
  static const Color stopButton = Color(0xFF1E2130);
  static const Color button     = Color(0xFFA855F7);
  static const Color buttonText = Color(0xFFFFFFFF);

  // ── Guardian dark theme (G_DARK) ───────────────────────────────────────────
  static const Color gBackground = Color(0xFF0C0B12);
  static const Color gCard       = Color(0xFF13111C);
  static const Color gBorder     = Color(0xFF1E1A2E);
  static const Color gText       = Color(0xFFEDE9F8);
  static const Color gMuted      = Color(0xFF6B6480);
  static const Color gAccent     = Color(0xFFA855F7);
  static const Color gAccent2    = Color(0xFF7C3AED);
  static const Color gSafe       = Color(0xFF4ADE80);
  static const Color gWarning    = Color(0xFFFBBF24);
  static const Color gDanger     = Color(0xFFF87171);

  // ── Guardian light theme (G_LIGHT) ────────────────────────────────────────
  static const Color glBackground = Color(0xFFFAF8FF);
  static const Color glCard       = Color(0xFFFFFFFF);
  static const Color glBorder     = Color(0xFFEDE9F8);
  static const Color glText       = Color(0xFF1A1625);
  static const Color glMuted      = Color(0xFF9B92B0);
  static const Color glAccent     = Color(0xFF9333EA);
  static const Color glAccent2    = Color(0xFF7C3AED);
  static const Color glSafe       = Color(0xFF22C55E);
  static const Color glWarning    = Color(0xFFF59E0B);
  static const Color glDanger     = Color(0xFFEF4444);
}

// ── Theme builders ─────────────────────────────────────────────────────────────
// fontFamily is set only on iOS where SF Pro Display is the system font.
// On Android/Windows/Web we pass null so Flutter uses the platform default
// (Roboto on Android), matching RN's Platform.select({ ios:'system-ui', default:'normal' }).

String? get _systemFont =>
    defaultTargetPlatform == TargetPlatform.iOS ? 'SF Pro Display' : null;

ThemeData buildDarkTheme() => ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.gBackground,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.gAccent,
        surface: AppColors.gCard,
      ),
      fontFamily: _systemFont,
    );

ThemeData buildLightTheme() => ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.glBackground,
      colorScheme: const ColorScheme.light(
        primary: AppColors.glAccent,
        surface: AppColors.glCard,
      ),
      fontFamily: _systemFont,
    );

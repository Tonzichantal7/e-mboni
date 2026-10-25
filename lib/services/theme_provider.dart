import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/colors.dart';

class ThemeProvider extends ChangeNotifier {
  bool _isDark = true;
  bool get isDark => _isDark;

  // ── Semantic color getters — light-mode overrides now applied ─────────────
  Color get background => _isDark ? AppColors.gBackground : AppColors.glBackground;
  Color get card       => _isDark ? AppColors.gCard       : AppColors.glCard;
  Color get border     => _isDark ? AppColors.gBorder     : AppColors.glBorder;
  Color get text       => _isDark ? AppColors.gText       : AppColors.glText;
  Color get muted      => _isDark ? AppColors.gMuted      : AppColors.glMuted;
  Color get accent     => _isDark ? AppColors.gAccent     : AppColors.glAccent;
  Color get accent2    => _isDark ? AppColors.gAccent2    : AppColors.glAccent2;
  // RN G_LIGHT has distinct safe/warning/danger — now correctly branched
  Color get safe       => _isDark ? AppColors.gSafe       : AppColors.glSafe;
  Color get warning    => _isDark ? AppColors.gWarning    : AppColors.glWarning;
  Color get danger     => _isDark ? AppColors.gDanger     : AppColors.glDanger;

  void toggle() {
    _isDark = !_isDark;
    notifyListeners();
    _save();
  }

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _isDark = prefs.getBool('isDark') ?? true;
    notifyListeners();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDark', _isDark);
  }
}

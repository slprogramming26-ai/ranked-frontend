import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Haelt die Dark-Mode-Wahl des Users und persistiert sie in SharedPreferences,
/// damit die Einstellung App-Neustarts ueberlebt.
class ThemeProvider extends ChangeNotifier {
  static const _key = 'dark_mode';

  bool _isDark;
  bool get isDark => _isDark;

  ThemeProvider(this._isDark);

  /// Liest die gespeicherte Wahl VOR runApp (wird in main() awaited, waehrend
  /// der native Splash noch steht). Frueher lud der Konstruktor asynchron
  /// nach -> die App startete immer hell und sprang dann auf dunkel um.
  static Future<ThemeProvider> load() async {
    final prefs = await SharedPreferences.getInstance();
    return ThemeProvider(prefs.getBool(_key) ?? false);
  }

  /// Umschalten + sofort speichern. notifyListeners() rebuildet alles,
  /// was per Consumer/watch an diesem Provider haengt.
  Future<void> toggle(bool value) async {
    _isDark = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, value);
  }
}
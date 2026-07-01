import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Haelt die Dark-Mode-Wahl des Users und persistiert sie in SharedPreferences,
/// damit die Einstellung App-Neustarts ueberlebt.
class ThemeProvider extends ChangeNotifier {
  static const _key = 'dark_mode';

  bool _isDark = false;
  bool get isDark => _isDark;

  ThemeProvider() {
    _load(); // beim Start gespeicherte Wahl nachladen
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    _isDark = prefs.getBool(_key) ?? false;
    notifyListeners();
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
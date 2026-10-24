import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Die drei Wahlmoeglichkeiten in den Settings.
/// system = der Geraetesprache folgen (Standard bei frischer Installation).
enum AppLanguage { system, de, en }

/// Haelt die Sprachwahl des Users und persistiert sie in SharedPreferences.
/// Aufbau wie ThemeProvider: load() vor runApp, Setter speichert sofort.
class LocaleProvider extends ChangeNotifier {
  static const _key = 'app_language';

  AppLanguage _language;
  AppLanguage get language => _language;

  LocaleProvider(this._language);

  /// Fuer MaterialApp(locale: ...). null = "entscheide selbst nach dem
  /// Geraet" -> Flutter folgt dann auch einem Sprachwechsel zur Laufzeit.
  Locale? get locale => switch (_language) {
    AppLanguage.de => const Locale('de'),
    AppLanguage.en => const Locale('en'),
    AppLanguage.system => null,
  };

  /// Liest die Wahl VOR runApp, damit die App nicht erst in der falschen
  /// Sprache startet. Gespeichert ist der Enum-Name als String ("de").
  static Future<LocaleProvider> load() async {
    final prefs = await SharedPreferences.getInstance();
    final languageAsString = prefs.getString(_key);
    for (final l in AppLanguage.values) {
      if (l.name == languageAsString) {
        return LocaleProvider(l);
      }
    }
    // Nichts gespeichert (frische Installation) oder unbekannter Wert.
    return LocaleProvider(AppLanguage.system);
  }

  /// Umschalten + sofort speichern. Gleicher Wert -> nichts tun, sonst
  /// baut notifyListeners() die komplette App umsonst neu.
  Future<void> setLanguage(AppLanguage value) async {
    if (value == _language) return;
    _language = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, value.name);
  }
}

/// Fuer MaterialApp.localeListResolutionCallback: welche App-Sprache passt
/// zur Geraete-Einstellung? Greift nur, wenn locale null ist
/// (Systemsprache), sonst gewinnt die feste Wahl des Users.
///
/// [deviceLocales] = alle Sprachen, die im Handy eingestellt sind, in der
/// Reihenfolge des Users (z.B. [fr_FR, de_DE]). Regel: die ERSTE davon, die
/// wir koennen, gewinnt. Keine passt -> Englisch. Ohne den Callback naehme
/// Flutter bei einer fremden Sprache den ersten Eintrag von supportedLocales,
/// und das ist bei uns Deutsch.
Locale resolveAppLocale(
  List<Locale>? deviceLocales,
  Iterable<Locale> supported,
) {
  for (final device in deviceLocales ?? const <Locale>[]) {
    for (final app in supported) {
      // Nur languageCode vergleichen: de_AT und de_CH sollen auch "de" sein.
      if (app.languageCode == device.languageCode) return app;
    }
  }
  return const Locale('en');
}

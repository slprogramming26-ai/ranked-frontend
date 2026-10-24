import 'package:flutter/material.dart';

/// Farben der App. Jede Farbe ist ein Getter, der je nach [isDark] den Light-
/// oder Dark-Wert zurueckgibt. So bleiben alle Aufrufe (AppColors.surface ...)
/// in der App unveraendert, schalten aber zur Laufzeit um.
///
/// WICHTIG: [isDark] wird ausschliesslich vom ThemeProvider gesetzt (eine
/// Quelle der Wahrheit). Die App-Wurzel haengt per Consumer am ThemeProvider
/// und baut bei Umschaltung den ganzen Baum neu -> die Getter liefern dann die
/// passende Palette.
abstract class AppColors {
  /// Steuert, welche Palette die Getter liefern. Nur vom ThemeProvider setzen.
  static bool isDark = false;

  // Hilfsfunktion: waehlt je nach Modus light oder dark.
  static Color _p(Color light, Color dark) => isDark ? dark : light;

  static Color get primary =>
      _p(const Color(0xFFB41B00), const Color(0xFFFF7058));
  static Color get primaryContainer =>
      _p(const Color(0xFFFF775D), const Color(0xFFFF9478));
  static Color get primaryDark =>
      _p(const Color(0xFF9E1700), const Color(0xFFE85A40));

  static Color get surface =>
      _p(const Color(0xFFFFF4F3), const Color(0xFF14100F));
  // surface + Low bleiben rosa (Identitaet). Die hoeheren Ebenen (Chips,
  // Avatare, Eingabefelder) sind entsaettigt-warm, sonst stapelt sich Rosa
  // auf Rosa und wirkt mauve.
  static Color get surfaceContainer =>
      _p(const Color(0xFFF8E8E6), const Color(0xFF26211F));
  static Color get surfaceContainerLow =>
      _p(const Color(0xFFFFEDEC), const Color(0xFF1E1817));
  static Color get surfaceContainerHigh =>
      _p(const Color(0xFFF3E3E1), const Color(0xFF2E2826));
  static Color get surfaceContainerHighest =>
      _p(const Color(0xFFEEDDDB), const Color(0xFF37302E));

  // Text/Icons/Linien bewusst neutral (minimal warm), damit Farbe nur fuer
  // Aktionen und Brand-Momente bleibt (wie Insta/TikTok).
  static Color get onSurface =>
      _p(const Color(0xFF1C1918), const Color(0xFFF2EEED));
  static Color get onSurfaceVariant =>
      _p(const Color(0xFF736E6C), const Color(0xFFA8A2A0));
  static Color get outlineVariant =>
      _p(const Color(0xFFD9D4D2), const Color(0xFF4A4442));

  static Color get tertiary =>
      _p(const Color(0xFF6C5A00), const Color(0xFFE0C84B));
  static Color get tertiaryContainer =>
      _p(const Color(0xFFFFD709), const Color(0xFF4A3D00));
  static Color get tertiaryFixedDim =>
      _p(const Color(0xFFEFC900), const Color(0xFFEFC900));

  static Color get secondary =>
      _p(const Color(0xFF565D5F), const Color(0xFFBEC6C8));
  static Color get secondaryFixed =>
      _p(const Color(0xFFDDE4E6), const Color(0xFF3A4042));

  // Eingabefelder: Light weiss (hebt sich vom rosa Hintergrund ab), Dark eine
  // Stufe heller als der Hintergrund. Vorher hart Colors.white -> im Dark
  // Mode war helle Schrift auf weissem Feld unlesbar.
  static Color get inputFill =>
      _p(Colors.white, const Color(0xFF241C1B));}

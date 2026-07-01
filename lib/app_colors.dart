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
  static Color get surfaceContainer =>
      _p(const Color(0xFFFFE1E1), const Color(0xFF2A211F));
  static Color get surfaceContainerLow =>
      _p(const Color(0xFFFFEDEC), const Color(0xFF1E1817));
  static Color get surfaceContainerHigh =>
      _p(const Color(0xFFFFDADA), const Color(0xFF332825));
  static Color get surfaceContainerHighest =>
      _p(const Color(0xFFFFD2D3), const Color(0xFF3D302C));

  static Color get onSurface =>
      _p(const Color(0xFF4D2124), const Color(0xFFF2E4E0));
  static Color get onSurfaceVariant =>
      _p(const Color(0xFF834C4F), const Color(0xFFC9A9A3));
  static Color get outlineVariant =>
      _p(const Color(0xFFDF9C9E), const Color(0xFF5C4A45));

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

  // Floating-Nav-Bar (Glas-Optik): Light bleibt weiss, Dark wird dunkles Glas.
  // Opacity wird an der Aufrufstelle draufgelegt.
  static Color get navGlass =>
      _p(Colors.white, const Color(0xFF241C1B));
  static Color get navBorder =>
      _p(Colors.white, const Color(0xFF3D302C));
}

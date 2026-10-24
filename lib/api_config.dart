/// Server-Adressen an EINER Stelle. Standard ist Prod (Railway); zum Testen
/// gegen ein lokales Backend beim Start ueberschreiben:
///
///   flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000
///
/// (10.0.2.2 = der PC aus Sicht des Android-Emulators; echtes Geraet: die
/// lokale IP des PCs.) Ohne --dart-define aendert sich nichts.
///
/// String.fromEnvironment ist const und wird beim Kompilieren eingesetzt -
/// zur Laufzeit umschalten geht damit nicht, dafuer kostet es nichts.
class ApiConfig {
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://web-production-1bb6f.up.railway.app',
  );

  static const String wsUrl = String.fromEnvironment(
    'WS_BASE_URL',
    defaultValue: 'wss://ranked-ws-gateway-production.up.railway.app',
  );
}

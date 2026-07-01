import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'token_storage.dart';

class ApiClient {
  static const String baseUrl = 'https://web-production-1bb6f.up.railway.app';

  // Refresh mit Single-Flight-Lock


  static Future<bool>? _refreshing;

  static Future<bool> _refreshOnce() {
    // ??= startet _runRefresh nur, wenn gerade keins läuft. Alle parallelen
    // 401-Handler bekommen dadurch DASSELBE Future und warten gemeinsam darauf.
    _refreshing ??= _runRefresh();
    return _refreshing!;
  }

  static Future<bool> _runRefresh() async {
    try {
      return await _refresh();
    } finally {
      _refreshing = null; // Lock freigeben, egal ob Erfolg oder Fehler
    }
  }

  static Future<bool> _refresh() async {
    final refreshToken = await TokenStorage.getRefreshToken();
    if (refreshToken == null) return false; // gar kein Token -> direkt raus

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/refresh'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refresh_token': refreshToken}),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // Rotation: neues Paar speichern (alter refresh_token ist serverseitig weg)
        await TokenStorage.saveRefreshToken(data['refresh_token']);
        await TokenStorage.saveToken(data['access_token']);
        return true;
      }
      return false;
    }
    catch (e) {
      return false;
    }


  }

  // ---------------------------------------------------------------------------
  // Kern: Request senden, bei 401 einmal refreshen + wiederholen
  // ---------------------------------------------------------------------------

  /// Führt [sender] aus (bekommt den aktuellen access_token). Ist die Antwort
  /// 401: refreshen und den Request GENAU EINMAL wiederholen.
  static Future<http.Response> _send(
    Future<http.Response> Function(String token) sender,
  ) async {
    final token = await TokenStorage.getToken() ?? '';
    var response = await sender(token);

    if (response.statusCode == 401) {
      final ok = await _refreshOnce();
      if (!ok) {
        await _forceLogout();
        return response; // unverändertes 401 zurück -> Aufrufer reagiert
      }
      final newToken = await TokenStorage.getToken() ?? '';
      response = await sender(newToken); // genau ein Retry mit frischem Token
    }
    return response;
  }

  /// Beim App-Start aufrufen: Refresh-Token vorhanden → /refresh → true/false.
  static Future<bool> tryRefreshOnStart() => _refreshOnce();

  // Widget hört auf diesen Stream und reagiert mit DB-Wipe + Navigation.
  static final _forceLogoutController = StreamController<void>.broadcast();
  static Stream<void> get forceLogoutStream => _forceLogoutController.stream;

  // Verhindert, dass parallele 401s den Logout N-mal auslösen.
  static bool _loggingOut = false;

  static Future<void> _forceLogout() async {
    if (_loggingOut) return; // schon am Ausloggen -> zweiter Aufrufer raus
    _loggingOut = true;
    await TokenStorage.clearAll();
    _forceLogoutController.add(null);
  }

  /// Nach erfolgreichem Login aufrufen: gibt den Logout-Riegel wieder frei,
  /// damit ein spaeterer Zwangs-Logout in derselben App-Session greift.
  static void resetLogoutGuard() => _loggingOut = false;

  /// Freiwilliger Logout (Logout-Button / nach Account-Loeschung):
  /// Token loeschen und denselben Stream feuern wie der Zwangs-Logout.
  /// main.dart reagiert darauf mit lokalem DB-Wipe + Ruecksprung zum Login.
  static Future<void> logout() async {
    await TokenStorage.clearAll();
    _forceLogoutController.add(null);
  }

  // Öffentliche Methoden – spiegeln http.* wider, hängen Auth automatisch an.
  // Jede baut eine Closure (token) => echter Request und gibt sie an _send.


  static Future<http.Response> get(Uri url, {Map<String, String>? headers}) {
    return _send((token) => http.get(url, headers: _auth(token, headers)));
  }

  static Future<http.Response> post(Uri url,
      {Object? body, Map<String, String>? headers}) {
    return _send(
        (token) => http.post(url, headers: _auth(token, headers), body: body));
  }

  static Future<http.Response> put(Uri url,
      {Object? body, Map<String, String>? headers}) {
    return _send(
        (token) => http.put(url, headers: _auth(token, headers), body: body));
  }

  static Future<http.Response> delete(Uri url, {Map<String, String>? headers}) {
    return _send((token) => http.delete(url, headers: _auth(token, headers)));
  }

  static Future<http.Response> uploadFile(Uri url, File file,
      {String field = 'file'}) {
    return _send((token) async {
      final request = http.MultipartRequest('POST', url);
      request.headers['Authorization'] = 'Bearer $token';
      request.files.add(await http.MultipartFile.fromPath(
        field,
        file.path,
        contentType: MediaType('image', 'jpeg'),
      ));
      final streamed = await request.send();
      return http.Response.fromStream(streamed);
    });
  }

  static Map<String, String> _auth(String token, Map<String, String>? extra) {
    return {
      'Authorization': 'Bearer $token',
      ...?extra,
    };
  }
}
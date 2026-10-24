import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'token_storage.dart';
import 'api_client.dart';
import 'api_config.dart';
import '../auth/code_request_result.dart';
import '../auth/delete_result.dart';
import '../e2ee/key_service.dart';
import '../auth/login_result.dart';
import '../moderation/report_reason.dart';
import '../moderation/report_target.dart';
import '../moderation/suspension.dart';
import '../auth/reset_result.dart';
import '../auth/verify_result.dart';

class UserApiService {
  // Für Android Emulator: 10.0.2.2, für echtes Gerät: deine lokale IP
  static const String baseUrl = ApiConfig.baseUrl;

  // login bleibt roher http-Call: hier gibt es noch keinen Token, und der
  // Body ist form-urlencoded (OAuth2PasswordRequestForm), nicht JSON.
  static Future<LoginResult> login(String email, String password) async {
    final http.Response response;
    try {
      response = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {'username': email, 'password': password},
      );
    } catch (_) {
      return const LoginOffline(); // sonst dreht der Login-Spinner ewig
    }

    if (response.statusCode == 200) {
      await _saveSession(response);
      return const LoginOk();
    }
    // VOR der Sperr-Pruefung: auch das ist ein 403, aber keine Sperre ->
    // landete sonst unten bei LoginInvalid ("falsches Passwort").
    if (response.statusCode == 403 &&
        _detailCode(response) == 'email_not_verified') {
      return const LoginNotVerified();
    }
    // login geht nicht ueber ApiClient._send -> die Sperre hier selbst pruefen.
    final suspension = Suspension.fromResponse(response);
    if (suspension != null) return LoginSuspended(suspension);
    return const LoginInvalid();
  }

  static Future<VerifyResult> verify(String email, String code) async {
    final http.Response response;
    try {
      response = await http.post(
        Uri.parse('$baseUrl/users/verify'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'email': email, 'code': code}),
      );
    } catch (_) {
      return const VerifyOffline(); // sonst dreht der Login-Spinner ewig
    }

    switch (response.statusCode) {
      case 200:
        await _saveSession(response); // verify loggt direkt ein
        return const VerifyOk();
      case 403:
        final suspension = Suspension.fromResponse(response);
        return suspension != null
            ? VerifyBanned(suspension)
            : const VerifyError();
      case 400:
        return const VerifyCodeInvalid();
      case 409:
        return const VerifyAlreadyOk();
      case 429:
        return const VerifyTooManyRequests();
    }

    return const VerifyError();
  }

  // Gemeinsam fuer login() und verify(): Beide liefern bei 200 dasselbe
  // Token-Paar. An EINER Stelle, damit resetLogoutGuard nirgends fehlt.
  static Future<void> _saveSession(http.Response response) async {
    final data = jsonDecode(response.body);
    await TokenStorage.saveRefreshToken(data['refresh_token']);
    await TokenStorage.saveToken(data['access_token']);
    ApiClient.resetLogoutGuard(); // Riegel fuer kuenftige Zwangs-Logouts oeffnen
  }

  // Liest detail.code aus einer Fehlerantwort: {"detail": {"code": "..."}}.
  // null, wenn es keinen gibt (kein JSON, detail ist ein Text, ...).
  static String? _detailCode(http.Response response) {
    final detail = _bodyMap(response)?['detail'];
    if (detail is! Map) return null;
    final code = detail['code'];
    return code is String ? code : null;
  }

  // Body als Map, oder null (leer, kein JSON, Liste, ...).
  // Darf NIE werfen - ein Crash hier wuerde den ganzen Login abschiessen.
  static Map<String, dynamic>? _bodyMap(http.Response response) {
    try {
      final body = jsonDecode(utf8.decode(response.bodyBytes));
      return body is Map<String, dynamic> ? body : null;
    } catch (_) {
      return null;
    }
  }

  static Future<CodeRequestResult> resendVerification(String email) =>
      _requestCode('/users/verify/resend', email);

  static Future<CodeRequestResult> forgotPassword(String email) =>
      _requestCode('/users/password/forgot', email);

  // Gemeinsam fuer resend und forgot: Beide Endpoints unterscheiden sich nur
  // in der URL. Reihenfolge (path, email) - beides String, ein Vertauschen
  // faengt der Compiler nicht ab.
  static Future<CodeRequestResult> _requestCode(
    String path,
    String email,
  ) async {
    final http.Response response;
    try {
      response = await http.post(
        Uri.parse('$baseUrl$path'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'email': email}),
      );
    } catch (_) {
      return const CodeRequestOffline(); // sonst dreht der Senden-Spinner ewig
    }
    if (response.statusCode == 429) return const CodeRequestCooldown();
    // Alles andere = "gesendet", siehe CodeRequestSent (keine User-Enumeration).
    return const CodeRequestSent();
  }

  static Future<ResetResult> resetPassword(
    String email,
    String code,
    String newPassword,
  ) async {
    final http.Response response;
    try {
      response = await http.post(
        Uri.parse('$baseUrl/users/password/reset'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': email,
          'code': code,
          'new_password': newPassword,
        }),
      );
    } catch (_) {
      return const ResetOffline(); // sonst dreht der Speichern-Spinner ewig
    }

    switch (response.statusCode) {
      case 204:
        return const ResetOk(); // keine Token -> KEIN _saveSession
      case 400:
        return const ResetCodeInvalid();
      case 429:
        // Zwei Absender: HTTPException (Tageslimit) schreibt immer "detail",
        // der slowapi-Handler immer "error". Bewusst der Key, nicht der
        // Text - sonst bricht das, sobald jemand die Formulierung aendert.
        return _bodyMap(response)?.containsKey('detail') == true
            ? const ResetDailyLimit()
            : const ResetTooManyRequests();
    }

    return const ResetError();
  }

  static Future<Map<String, dynamic>> getCurrentUser() async {
    final response = await ApiClient.get(Uri.parse('$baseUrl/users/'));
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    return {};
  }

  static Future<Map<String, dynamic>> getUser(int userId) async {
    final response = await ApiClient.get(Uri.parse('$baseUrl/users/$userId'));
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    return {};
  }

  static Future<List<Map<String, dynamic>>> getUserByUsername(
    String username,
  ) async {
    final uri = Uri.parse(
      '$baseUrl/users/search',
    ).replace(queryParameters: {'search': username});
    final response = await ApiClient.get(uri);
    if (response.statusCode == 200) {
      final data = jsonDecode(utf8.decode(response.bodyBytes)) as List<dynamic>;
      return data.cast<Map<String, dynamic>>();
    }
    return [];
  }

  // createUser bleibt roher http-Call: Registrierung braucht keinen Token.
  // Gibt null bei Erfolg zurueck, sonst die anzeigbare Fehlermeldung.
  // Das Backend liefert bei 409 (E-Mail/Username vergeben) und 403 (<16)
  // fertige deutsche Texte im "detail"-Feld — die reichen wir 1:1 durch.
  static Future<String?> createUser(
    String email,
    String username,
    String password,
    int age,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/users/'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        "email": email,
        "username": username,
        "passwort": password,
        "age": age,
      }),
    );
    if (response.statusCode == 201) return null;
    try {
      final detail = jsonDecode(utf8.decode(response.bodyBytes))['detail'];
      if (detail is String) return detail;
    } catch (_) {}
    return 'Registrierung fehlgeschlagen (Fehler ${response.statusCode})';
  }

  static Future<Map<String, dynamic>> addUserDetails(
    String? vibe_factor_1,
    String? vibe_factor_2,
    String imageUrl,
    String bio, {
    int? locationId,
  }) async {
    final body = <String, dynamic>{
      "profile_picture_url": imageUrl,
      "biography": bio,
    };
    // exclude_unset im Backend: Keys nur mitschicken, wenn im Sign-up wirklich
    // etwas gewaehlt wurde — Vibes sind optional ("Share only what you want
    // to share"), und `"location_id": null` wuerde einen gesetzten Ort
    // explizit loeschen (siehe setLocation).
    if (vibe_factor_1 != null) body["vibe_factor_1"] = vibe_factor_1;
    if (vibe_factor_2 != null) body["vibe_factor_2"] = vibe_factor_2;
    if (locationId != null) body["location_id"] = locationId;
    await ApiClient.put(
      Uri.parse('$baseUrl/users/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );
    return {};
  }

  static Future<Map<String, dynamic>> setRankingEnabled(
    bool rankingEnabled,
  ) async {
    await ApiClient.put(
      Uri.parse('$baseUrl/users/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({"ranking_enabled": rankingEnabled}),
    );
    return {};
  }

  static Future<String?> uploadUserImage(File imageFile) async {
    final response = await ApiClient.uploadFile(
      Uri.parse('$baseUrl/users/upload'),
      imageFile,
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['image_url'] as String;
    }
    print('Upload fehlgeschlagen: ${response.statusCode} – ${response.body}');
    return null;
  }

  static Future<bool> createFollow(int followeeId, int dir) async {
    final response = await ApiClient.post(
      Uri.parse('$baseUrl/follow/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({"followee_id": followeeId, "dir": dir}),
    );
    return response.statusCode >= 200 && response.statusCode < 300;
  }

  static Future<bool> blockUser(int blockedId) async {
    try {
      final response = await ApiClient.post(
        Uri.parse('$baseUrl/users/block/$blockedId'),
      );
      // 409 = schon blockiert -> Ziel erreicht, also auch Erfolg.
      return response.statusCode == 201 || response.statusCode == 409;
    } catch (_) {
      return false; // kein Netz -> Exception statt Statuscode
    }
  }

  static Future<bool> deleteBlock(int blockedId) async {
    try {
      final response = await ApiClient.delete(
        Uri.parse('$baseUrl/users/block/$blockedId'),
      );
      // 404 = keine Blockade (mehr) da oder User weg -> Ziel erreicht.
      return response.statusCode == 200 || response.statusCode == 404;
    } catch (_) {
      return false; // sonst bleibt der Spinner im Aufheben-Button haengen
    }
  }

  static Future<List<Map<String, dynamic>>?> getBlocks() async {
    try {
      final response = await ApiClient.get(
        Uri.parse('$baseUrl/users/blocked'),
      );
      if (response.statusCode == 200) {
        final data =
            jsonDecode(utf8.decode(response.bodyBytes)) as List<dynamic>;
        return data.cast<Map<String, dynamic>>();
      }
    } catch (_) {
      // kein Netz / kaputtes JSON -> unten null, wie jeder andere Fehler
    }
    return null; // Fehler != leere Liste: der Screen zeigt dann "Erneut versuchen"
  }

  static Future<bool> deleteUser() async {
    final response = await ApiClient.delete(Uri.parse('$baseUrl/users/'));
    return response.statusCode == 204;
  }

  // Fuer Gesperrte: Ein Bann loescht die Refresh-Tokens und /login gibt 403,
  // an deleteUser() oben kommen sie also nie ran. Deshalb E-Mail + Passwort.
  // Roher http-Call, NICHT ApiClient: _send wuerde das 401 ("falsches
  // Passwort") als abgelaufenen Token deuten -> Refresh -> Zwangs-Logout.
  static Future<DeleteResult> deleteSuspendedAccount(
    String email,
    String password,
  ) async {
    final http.Response response;
    try {
      response = await http.post(
        Uri.parse('$baseUrl/users/delete'),
        headers: {'Content-Type': 'application/json'},
        // "passwort" mit t - wie createUser, das Backend-Schema heisst so.
        // E-Mail trimmt + verkleinert der Server selbst.
        body: json.encode({'email': email, 'passwort': password}),
      );
    } catch (_) {
      return const DeleteOffline(); // sonst dreht der Loeschen-Spinner ewig
    }

    switch (response.statusCode) {
      // 200 = neuer Vertrag mit {"user_id"}, 204 = altes Backend ohne Body.
      // Beides heisst: Konto auf dem Server weg.
      case 200:
      case 204:
        await _wipeLocalAccount(_bodyMap(response)?['user_id']);
        return const DeleteOk();
      case 401:
        return const DeleteInvalid();
      case 429:
        return const DeleteTooManyRequests();
    }

    return const DeleteError();
  }

  // Raeumt die Geraete-Daten des GERADE geloeschten Kontos weg. Die DB leert
  // der Aufrufer (braucht den Provider) - hier nur der Secure Storage.
  // Bewusst NUR das Keypair dieser userId: andere Konten auf demselben Geraet
  // behalten ihre Keys (ohne Backup waeren deren Chats sonst fuer immer weg).
  // Gruppen-Keys bleiben liegen wie beim Loeschen in den Settings: ihr
  // Storage-Key hat keine userId und kann einem anderen Konto mitgehoeren.
  static Future<void> _wipeLocalAccount(Object? userId) async {
    // Kein int (204 vom alten Backend) -> Keys bleiben, Konto ist trotzdem weg.
    if (userId is int) await KeyService.deleteKeypair(userId.toString());
    await TokenStorage.clearAll();
  }

  /// Ortssuche fuer den Location-Picker. Liefert max. 20 Orte als
  /// `{id, name}`-Maps, Prefix-Treffer zuerst (macht das Backend).
  static Future<List<Map<String, dynamic>>> getLocations(String search) async {
    final uri = Uri.parse(
      '$baseUrl/locations/',
    ).replace(queryParameters: {'search': search});
    final response = await ApiClient.get(uri);
    if (response.statusCode == 200) {
      // bodyBytes + utf8.decode wegen Umlauten in Ortsnamen (z.B. "Muenchen"
      // vs. "München") — response.body wuerde Latin-1 raten.
      final data = jsonDecode(utf8.decode(response.bodyBytes)) as List<dynamic>;
      return data.cast<Map<String, dynamic>>();
    }
    return [];
  }

  /// Setzt (oder loescht mit `null`) den Heimatort des Users.
  /// Wichtig: Das Backend nutzt exclude_unset — der Key "location_id" muss
  /// also explizit im JSON stehen, sonst passiert gar nichts. jsonEncode
  /// schreibt `"location_id": null` mit rein, das reicht.
  static Future<bool> setLocation(int? locationId) async {
    final response = await ApiClient.put(
      Uri.parse('$baseUrl/users/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({"location_id": locationId}),
    );
    return response.statusCode >= 200 && response.statusCode < 300;
  }

  // Gibt den HTTP-Status zurueck, damit der Aufrufer 201 (ok) von
  // 409 (schon gemeldet) und echten Fehlern unterscheiden kann.
  static Future<int> report(
    ReportTarget target,
    int id,
    ReportReason reason, {
    String? details,
  }) async {
    final trimmed = details?.trim();
    final response = await ApiClient.post(
      Uri.parse('$baseUrl/report/${target.apiValue}/$id'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'reason': reason.apiValue,
        // Backend will 1-500 Zeichen: leerer String waere 422 -> dann weglassen.
        if (trimmed != null && trimmed.isNotEmpty) 'details': trimmed,
      }),
    );
    return response.statusCode;
  }
}

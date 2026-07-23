import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'token_storage.dart';
import 'api_client.dart';

class UserApiService {
  // Für Android Emulator: 10.0.2.2, für echtes Gerät: deine lokale IP
  static const String baseUrl = 'https://web-production-1bb6f.up.railway.app';

  // login bleibt roher http-Call: hier gibt es noch keinen Token, und der
  // Body ist form-urlencoded (OAuth2PasswordRequestForm), nicht JSON.
  static Future<bool> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/login'),
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {
        'username': email,
        'password': password,
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      await TokenStorage.saveRefreshToken(data["refresh_token"]);
      await TokenStorage.saveToken(data['access_token']);
      ApiClient.resetLogoutGuard(); // Riegel fuer kuenftige Zwangs-Logouts oeffnen
      return true;
    } else {
      return false; // Login fehlgeschlagen
    }
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
      String username) async {
    final uri = Uri.parse('$baseUrl/users/search').replace(
      queryParameters: {'search': username},
    );
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

  static Future<Map<String, dynamic>> addUserDetails(String? vibe_factor_1,
      String? vibe_factor_2, String imageUrl, String bio,
      {int? locationId}) async {
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
      bool rankingEnabled) async {
    await ApiClient.put(
      Uri.parse('$baseUrl/users/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        "ranking_enabled": rankingEnabled,
      }),
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
    final response =
        await ApiClient.post(Uri.parse('$baseUrl/users/block/$blockedId'));
    return response.statusCode == 201;
  }

  static Future<bool> deleteBlock(int blockedId) async {
    final response =
        await ApiClient.delete(Uri.parse('$baseUrl/users/block/$blockedId'));
    return response.statusCode == 200;
  }
  
  static Future<bool> deleteUser() async {
    final response =
        await ApiClient.delete(Uri.parse('$baseUrl/users/'));
    return response.statusCode == 204;
  }

  /// Ortssuche fuer den Location-Picker. Liefert max. 20 Orte als
  /// `{id, name}`-Maps, Prefix-Treffer zuerst (macht das Backend).
  static Future<List<Map<String, dynamic>>> getLocations(String search) async {
    final uri = Uri.parse('$baseUrl/locations/').replace(
      queryParameters: {'search': search},
    );
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
  static Future<int> report(int postId, String type, String reason) async  {
    final response = await ApiClient.post(Uri.parse('$baseUrl/report/$type/$postId'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'reason': reason,
      }),
    );
    return response.statusCode;
  }
}
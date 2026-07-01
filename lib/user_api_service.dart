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
  static Future<Map<String, dynamic>> createUser(
    String email,
    String username,
    String password,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/users/'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        "email": email,
        "username": username,
        "passwort": password,
      }),
    );
    if (response.statusCode == 201) {
      return {};
    } else if (response.statusCode == 409) {
      return {"Fehler": "Email oder username schon benutzt"};
    }
    return {};
  }

  static Future<Map<String, dynamic>> addUserDetails(String vibe_factor_1,
      String vibe_factor_2, String imageUrl, String bio) async {
    await ApiClient.put(
      Uri.parse('$baseUrl/users/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        "vibe_factor_1": vibe_factor_1,
        "vibe_factor_2": vibe_factor_2,
        "profile_picture_url": imageUrl,
        "biography": bio
      }),
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
        await ApiClient.delete(Uri.parse('$baseUrl/users/delete'));
    return response.statusCode == 204;
  }
}
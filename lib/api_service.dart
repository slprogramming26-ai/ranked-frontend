import 'package:http/http.dart' as http;
import 'dart:convert';
import 'token_storage.dart';
import 'dart:io';
import 'package:http_parser/http_parser.dart';

class ApiService {
  // Für Android Emulator: 10.0.2.2, für echtes Gerät: deine lokale IP
  static const String baseUrl = 'https://web-production-1bb6f.up.railway.app';

  static Future<String?> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/login'),
      // FastAPI OAuth2PasswordRequestForm erwartet application/x-www-form-urlencoded
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {
        'username':
            email, // dein Backend filtert nach email, aber das Feld heißt username
        'password': password,
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['access_token'] as String;
    } else {
      return null; // Login fehlgeschlagen
    }
  }



  static Future<Map<String, dynamic>> getCurrentUser() async {
    final token = await TokenStorage.getToken();
    final response = await http.get(
      Uri.parse('$baseUrl/users/'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data;
    }
    return {};
  }

  static Future<Map<String, dynamic>> getUser(int userId) async {
    final token = await TokenStorage.getToken();
    final response = await http.get(
      Uri.parse('$baseUrl/users/$userId'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data;
    }
    return {};
  }

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

  static Future<Map<String, dynamic>> addUserDetails(String vibe_factor_1, String vibe_factor_2, String imageUrl, String bio) async {
    final token = await TokenStorage.getToken();

    final response = await http.put(
      Uri.parse('$baseUrl/users/'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        "vibe_factor_1": vibe_factor_1,
        "vibe_factor_2": vibe_factor_2,
        "profile_picture_url": imageUrl,  // ← umbenennen
        "biography": bio
      }),
    );
    return {};
}

  static Future<Map<String, dynamic>> setRankingEnabled(bool rankingEnabled) async {
    final token = await TokenStorage.getToken();
    final response = await http.put(
      Uri.parse('$baseUrl/users/'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        "ranking_enabled": rankingEnabled,
      }),
    );
    return {};
  }


  static Future<String?> uploadUserImage(File imageFile) async {
    final token = await TokenStorage.getToken();
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/users/upload'),
    );
    request.headers['Authorization'] = 'Bearer $token';

    request.files.add(await http.MultipartFile.fromPath('file', imageFile.path, contentType: MediaType('image', 'jpeg'),));

    final response = await request.send();
    final body = await response.stream.bytesToString();

    if (response.statusCode == 200) {
      final data = jsonDecode(body);
      return data['image_url'] as String;
    }
    return null;
  }


  static Future<bool> createFollow(int followeeId, int dir) async {
    final token = await TokenStorage.getToken();
    final response = await http.post(
      Uri.parse('$baseUrl/follow/'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({"followee_id": followeeId, "dir": dir}),
    );
    return response.statusCode == 201;
  }


}

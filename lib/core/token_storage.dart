import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Speichert die beiden Auth-Token:
/// - access_token  -> SharedPreferences (kurzlebig, ~30 Min, wird bei jedem
///   Request gelesen -> schnell, unkritisch weil eh ständig ablaufend)
/// - refresh_token -> flutter_secure_storage (langlebig, ~60 Tage,
///   "Generalschlüssel" -> verschlüsselt im Android Keystore / iOS Keychain)
class TokenStorage {
  static const _accessKey = 'access_token';
  static const _refreshKey = 'refresh_token';

  static const _secure = FlutterSecureStorage();

  // --- Access-Token (SharedPreferences) ---

  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_accessKey, token);
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_accessKey);
  }

  static Future<void> deleteToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_accessKey);
  }

  // --- Refresh-Token (flutter_secure_storage) ---

  static Future<void> saveRefreshToken(String token) async {
    await _secure.write(key: _refreshKey, value: token);
  }

  static Future<String?> getRefreshToken() async {
    return _secure.read(key: _refreshKey);
  }

  static Future<void> deleteRefreshToken() async {
    await _secure.delete(key: _refreshKey);
  }

  // --- Beides löschen (für Logout / Zwangs-Logout) ---

  static Future<void> clearAll() async {
    await deleteToken();
    await deleteRefreshToken();
  }
}
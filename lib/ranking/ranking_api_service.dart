import 'dart:convert';
import '../api_client.dart';

class RankingApiService {
  // Für Android Emulator: 10.0.2.2, für echtes Gerät: deine lokale IP
  static const String baseUrl = 'https://web-production-1bb6f.up.railway.app';

  static Future<Map<String, dynamic>> getRandomTarget() async {
    final response =
        await ApiClient.get(Uri.parse('$baseUrl/ranking/my_target'));
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    return {};
  }

  static Future<Map<String, dynamic>> submitSwipeSession(
    int targetUserId,
    List<Map<String, dynamic>> swipes,
  ) async {
    final response = await ApiClient.post(
      Uri.parse('$baseUrl/ranking/swipe_session'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        "target_user_id": targetUserId,
        "swipes": swipes,
      }),
    );

    if (response.statusCode == 201) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }

    String? detail;
    try {
      detail = (jsonDecode(response.body) as Map<String, dynamic>)['detail']
          as String?;
    } catch (_) {
      detail = null;
    }
    print('swipe_session failed: ${response.statusCode} – $detail');

    return {
      'success': false,
      'status': response.statusCode,
      'detail': detail,
    };
  }

  /// Die letzten 30 Ranking-Events des eingeloggten Users
  /// (z.B. {type: "rated", payload: 45, created_at: "..."}), neueste zuerst.
  static Future<List<Map<String, dynamic>>> getActivity() async {
    final response =
        await ApiClient.get(Uri.parse('$baseUrl/ranking/activity'));
    if (response.statusCode == 200) {
      return (jsonDecode(response.body) as List<dynamic>)
          .cast<Map<String, dynamic>>();
    }
    print('[activity] failed: ${response.statusCode}');
    return [];
  }

  /// Neues Format: Das Backend liefert jetzt ein Objekt
  /// { "entries": [...], "me": {...} } statt einer nackten Liste.
  static Future<Map<String, dynamic>> getLeaderboard() async {
    final response =
        await ApiClient.get(Uri.parse('$baseUrl/ranking/leaderboard'));
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    print('[leaderboard] failed: ${response.statusCode}');
    return {'entries': <Map<String, dynamic>>[], 'me': null};
  }
}
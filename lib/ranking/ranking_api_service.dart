import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/api_client.dart';
import '../core/api_config.dart';
import 'target_result.dart';

class RankingApiService {
  // Für Android Emulator: 10.0.2.2, für echtes Gerät: deine lokale IP
  static const String baseUrl = ApiConfig.baseUrl;

  /// Die beiden 404-Saetze, bei denen heute kein Ranking mehr geht.
  /// Exakter Vergleich: aendert das Backend den Text, landen wir bei
  /// TargetNoneAvailable - also beim alten Verhalten, nichts bricht.
  static const _limitReachedDetails = {
    'Dein heutiges Ranking ist bereits abgeschlossen.',
    'Für heute sind keine weiteren Neuziehungen möglich.',
  };

  /// GET /ranking/my_target -> {user_data, posts}, als TargetResult.
  static Future<TargetResult> getMyTarget() async {
    final http.Response response;
    try {
      response = await ApiClient.get(Uri.parse('$baseUrl/ranking/my_target'));
    } catch (_) {
      return const TargetOffline(); // sonst dreht der Spinner ewig
    }

    try {
      final body = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200) {
        final targetUser = body['user_data'] as Map<String, dynamic>?;
        final posts = body['posts'] as List<dynamic>? ?? [];
        if (targetUser == null || posts.isEmpty) {
          return const TargetNoneAvailable();
        }
        return TargetFound(targetUser: targetUser, posts: posts);
      }

      if (response.statusCode == 404) {
        return _limitReachedDetails.contains(body['detail'])
            ? const TargetLimitReached()
            : const TargetNoneAvailable();
      }
    } catch (_) {
      // Kein JSON-Objekt (z. B. HTML-Fehlerseite vom Proxy) -> TargetError.
    }

    return const TargetError();
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
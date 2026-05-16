import 'package:http/http.dart' as http;
import 'dart:convert';
import 'token_storage.dart';

class RankingApiService {
  // Für Android Emulator: 10.0.2.2, für echtes Gerät: deine lokale IP
  static const String baseUrl = 'https://web-production-1bb6f.up.railway.app';

  static Future<Map<String, dynamic>> getRandomTarget() async {
    final token = await TokenStorage.getToken();
    final response = await http.get(
      Uri.parse('$baseUrl/ranking/my_target'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data;
    }
    return {};
  }

  static Future<List<Map<String, dynamic>>> getLastWeekPosts(
    int targetUserId,
  ) async {
    final token = await TokenStorage.getToken();
    final response = await http.get(
      Uri.parse('$baseUrl/ranking/all_week_posts/$targetUserId'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as List<dynamic>;
      return data.cast<Map<String, dynamic>>();
    }
    if (response.statusCode == 400) {
      return [{'message': 'You already voted today'}];
    }
    return [];
  }

  static Future<bool> pushRankingScores(
    int targetUserId,
    int productivityRating,
    int creativityRating,
    int engagementRating,
  ) async {
    final token = await TokenStorage.getToken();
    final response = await http.post(
      Uri.parse('$baseUrl/ranking/daily_ranking_score'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'target_user_id': targetUserId,
        'productivity_rating': productivityRating,
        'creativity_rating': creativityRating,
        'engagement_rating': engagementRating
      }),
    );

    return response.statusCode == 201;
  }

  static Future<List<Map<String, dynamic>>> getLeaderboard() async {
    final token = await TokenStorage.getToken();
    final response = await http.get(
      Uri.parse('$baseUrl/ranking/leaderboard'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as List<dynamic>;
      return data.cast<Map<String, dynamic>>();
    }
    return [];

  }
}

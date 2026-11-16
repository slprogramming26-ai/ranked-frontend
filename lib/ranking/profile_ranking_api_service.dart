import 'dart:convert';

import '../core/api_client.dart';
import '../core/api_config.dart';
import 'profile_ranking_result.dart';

/// Ein Eintrag aus GET /profile_ranking/users/{id}/posts.
///
/// JSON vom Server:
/// {
///   "post": {...},                  // Feed-Post-Objekt (Map)
///   "ranking_like_count": 12,       // int
///   "ranking_entered_on": "2026-11-14", // UTC-Datum als String
///   "is_active": true,              // bool - NICHT selbst ausrechnen (Zeitzone)
///   "my_swipe": true | false | null // null = ich habe noch nicht bewertet
/// }
class RankedPost {
  const RankedPost({
    required this.post,
    required this.likeCount,
    required this.enteredOn,
    required this.isActive,
    required this.myLike,
  });

  final Map<String, dynamic> post;
  final int likeCount;
  final String enteredOn;
  final bool isActive;
  final bool? myLike;

  factory RankedPost.fromJson(Map<String, dynamic> json) {
    return RankedPost(
      post: json['post'] as Map<String, dynamic>,
    likeCount: json['ranking_like_count'] as int,
      enteredOn: json['ranking_entered_on'] as String,
      isActive: json['is_active'] as bool,
      myLike: json['my_swipe'] as bool?,
    );
  }
}

/// Antwort von GET /profile_ranking/users/{id}/open.
/// canRate = can_swipe vom Server (false bei eigenem Profil, nicht gefolgt,
/// Block, Besitzer gesperrt). posts: max. 7, älteste zuerst, OHNE Like-Zahl.
typedef OpenPosts = ({bool canRate, List<Map<String, dynamic>> posts});

/// Antwort von GET /profile_ranking/slot: Darf ich heute noch einen Post
/// ins Ranking stellen? nextFreeAt = nächster 00:00 UTC (kommt immer mit).
typedef RankingSlot = ({bool free, DateTime nextFreeAt});

class ProfileRankingApiService {
  static const String _base = '${ApiConfig.baseUrl}/profile_ranking';

  /// Posts von [userId], die ich gerade bewerten kann.
  /// null = Fehler (kein Netz, 500, kaputtes JSON).
  static Future<OpenPosts?> getOpenPosts(int userId) async {
    try {
      final response = await ApiClient.get(
        Uri.parse('$_base/users/$userId/open'),
      );
      if (response.statusCode == 200) {
        // bodyBytes + utf8: sonst kommen Umlaute kaputt an.
        final body =
            jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
        return (
          canRate: body['can_swipe'] as bool? ?? false,
          posts: (body['posts'] as List<dynamic>? ?? [])
              .cast<Map<String, dynamic>>(),
        );
      }
    } catch (_) {
      // kein Netz / kaputtes JSON -> unten null
    }
    return null;
  }

  /// Ranking-Liste von [userId] fürs Profil, meiste Likes zuerst.
  /// null = Fehler, [] = Seite leer (= Ende erreicht) ODER 403 (Block):
  /// bei einem Block gibt es schlicht nichts zu zeigen.
  static Future<List<RankedPost>?> getRankedPosts(
    int userId, {
    int skip = 0,
    int limit = 20,
  }) async {
    final uri = Uri.parse(
      '$_base/users/$userId/posts',
    ).replace(queryParameters: {'skip': '$skip', 'limit': '$limit'});
    try {
      final response = await ApiClient.get(uri);
      if (response.statusCode == 200) {
        final data =
            jsonDecode(utf8.decode(response.bodyBytes)) as List<dynamic>;
        return data
            .map((e) => RankedPost.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      if (response.statusCode == 403) return [];
    } catch (_) {
      // kein Netz / kaputtes JSON -> unten null
    }
    return null;
  }

  /// Ist mein Tagesplatz fürs Ranking noch frei?
  /// null = Fehler (dann lassen wir den Schalter offen - der 409 beim
  /// Einstellen ist das Sicherheitsnetz).
  static Future<RankingSlot?> getSlot() async {
    try {
      final response = await ApiClient.get(Uri.parse('$_base/slot'));
      if (response.statusCode == 200) {
        final body =
            jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
        return (
          free: body['free'] as bool,
          // "2026-11-17T00:00:00Z" -> DateTime mit isUtc == true
          nextFreeAt: DateTime.parse(body['next_free_at'] as String),
        );
      }
    } catch (_) {
      // kein Netz / kaputtes JSON -> unten null
    }
    return null;
  }

  // Exakte Backend-Sätze (routers/profile_ranking.py). Ändert das Backend
  // den Text, landen wir im sicheren Fallback - nichts bricht.
  static const _slotTakenDetail =
      'Du hast heute schon einen Post ins Ranking gestellt.';
  static const _alreadyRatedDetail = 'Diesen Post hast du schon bewertet.';

  /// Eigenen Post [postId] ins Profil-Ranking stellen (ohne Body).
  static Future<EnterRankingResult> enterRanking(int postId) async {
    try {
      final response = await ApiClient.post(Uri.parse('$_base/posts/$postId'));
      if (response.statusCode == 201) return const EnterRankingOk();
      if (response.statusCode == 409 &&
          _detail(response.bodyBytes) == _slotTakenDetail) {
        return const EnterRankingSlotTaken();
      }
    } catch (_) {
      // kein Netz -> unten Failed
    }
    return const EnterRankingFailed();
  }

  /// Post [postId] bewerten: [liked] true = Gefällt mir, false = Weiter.
  /// Ein Request pro Post.
  static Future<RateResult> ratePost(int postId, {required bool liked}) async {
    try {
      final response = await ApiClient.post(
        Uri.parse('$_base/swipes'),
        headers: {'Content-Type': 'application/json'},
        // Backend-Feldname bleibt "direction" - nur im UI kein "Swipe".
        body: jsonEncode({'post_id': postId, 'direction': liked}),
      );
      switch (response.statusCode) {
        case 201:
          return const RateDone();
        case 409:
          // Zwei 409er: "schon bewertet" = erledigt, sonst "abgelaufen".
          return _detail(response.bodyBytes) == _alreadyRatedDetail
              ? const RateDone()
              : const RateGone();
        case 403 || 404:
          return const RateGone();
      }
    } catch (_) {
      // kein Netz -> unten Failed
    }
    return const RateFailed();
  }

  /// detail aus einer FastAPI-Fehlerantwort, null wenn kein JSON.
  static String? _detail(List<int> bodyBytes) {
    try {
      return (jsonDecode(utf8.decode(bodyBytes))
              as Map<String, dynamic>)['detail']
          as String?;
    } catch (_) {
      return null;
    }
  }

}

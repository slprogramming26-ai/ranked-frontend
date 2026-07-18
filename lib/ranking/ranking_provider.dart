import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'ranking_api_service.dart';

// ─── RankingProvider ──────────────────────────────────────────────────────────
// Userdaten (id, ranking_enabled, streak_count, ...) kommen NICHT mehr von
// hier, sondern aus ProfileProvider — die haelt sie schon als einzige Quelle
// (siehe profile.dart). Doppelter GET /users/-Call sonst bei jedem ersten
// Besuch des Ranking-Tabs.
class RankingProvider extends ChangeNotifier {

  bool _isLoading = false;
  List<Map<String, dynamic>> _leaderboardData = [];
  // Die "Du"-Zeile: eigener Stand (my_rank / my_points / points_to_next).
  // Kann null sein, wenn das Backend noch keine 'me'-Daten liefert.
  Map<String, dynamic>? _leaderboardMe;
  bool _hasFetchedLeaderboard = false;
  bool _isLoadingLeaderboard = false;

  bool get isLoading => _isLoading;
  List<Map<String, dynamic>> get leaderboardData => _leaderboardData;
  Map<String, dynamic>? get leaderboardMe => _leaderboardMe;
  bool get hasFetchedLeaderboard => _hasFetchedLeaderboard;
  bool get isLoadingLeaderboard => _isLoadingLeaderboard;

  Future<bool> getDidRanking() async {
    final prefs = await SharedPreferences.getInstance();
    return Streak.didActivityToday(prefs);
  }

  void trueLoading() {
    _isLoading = true;
    notifyListeners();
  }

  void falseLoading() {
    _isLoading = false;
    notifyListeners();
  }

  Future<void> fetchLeaderboard() async {
    if (_hasFetchedLeaderboard) return;
    _isLoadingLeaderboard = true;
    notifyListeners();

    try {
      final data = await RankingApiService.getLeaderboard();
      _applyLeaderboard(data);
      _hasFetchedLeaderboard = true;
    } catch (e) {
      print("Fehler beim Laden: $e");
    } finally {
      _isLoadingLeaderboard = false;
      notifyListeners();
    }
  }

  Future<void> refreshLeaderboard() async {
    try {
      final data = await RankingApiService.getLeaderboard();
      _applyLeaderboard(data);
      _hasFetchedLeaderboard = true;
    } catch (e) {
      print("Fehler beim Laden: $e");
    } finally {
      _isLoadingLeaderboard = false;
      notifyListeners();
    }
  }

  // Zerlegt den neuen { entries, me }-Response in unsere beiden Felder.
  void _applyLeaderboard(Map<String, dynamic> data) {
    final entries = (data['entries'] as List<dynamic>? ?? [])
        .cast<Map<String, dynamic>>();
    _leaderboardData = entries;
    _leaderboardMe = data['me'] as Map<String, dynamic>?;
  }
}


class Streak {
  static const _lastActivityKey = 'saved_date_time_key';


  static bool didActivityToday(SharedPreferences prefs) {
    final timestamp = prefs.getInt(_lastActivityKey);
    if (timestamp == null) return false;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final diff = today.difference(DateTime.fromMillisecondsSinceEpoch(timestamp)).inDays;
    return diff == 0;
  }


  static Future<void> markRankedToday() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    await prefs.setInt(_lastActivityKey, today.millisecondsSinceEpoch);
  }
}

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../streak.dart';
import 'ranking_api_service.dart';
import '../user_api_service.dart';

// ─── RankingProvider ──────────────────────────────────────────────────────────
class RankingProvider extends ChangeNotifier {

  bool _isLoading = false;
  bool _isLoadingHome = false;
  bool _hasFetched = false;
  Map<String, dynamic> _userdata = {};
  List<Map<String, dynamic>> _leaderboardData = [];
  // Die "Du"-Zeile: eigener Stand (my_rank / my_points / points_to_next).
  // Kann null sein, wenn das Backend noch keine 'me'-Daten liefert.
  Map<String, dynamic>? _leaderboardMe;
  bool _hasFetchedLeaderboard = false;
  bool _isLoadingLeaderboard = false;
  int _streak = 0;

  bool get isLoading => _isLoading;
  bool get isLoadingHome => _isLoadingHome;
  bool get hasFetched => _hasFetched;
  Map<String, dynamic> get userdata => _userdata;
  List<Map<String, dynamic>> get leaderboardData => _leaderboardData;
  Map<String, dynamic>? get leaderboardMe => _leaderboardMe;
  bool get hasFetchedLeaderboard => _hasFetchedLeaderboard;
  bool get isLoadingLeaderboard => _isLoadingLeaderboard;
  int get streak => _streak;

  Future<bool> getDidRanking() async {
    final prefs = await SharedPreferences.getInstance();
    return Streak.didActivityToday(prefs);
  }

  Future<void> fetchStreak() async {
    final s = await Streak.getStreakWithExpiry();
    _streak = s;
    notifyListeners();
  }

  Future<void> refreshStreak() async {
    final s = await Streak.getStreakWithExpiry();
    _streak = s;
    notifyListeners();
  }

  void trueLoading() {
    _isLoading = true;
    notifyListeners();
  }

  void falseLoading() {
    _isLoading = false;
    notifyListeners();
  }

  Future<void> _fetchUserCredentials() async {
    if (_hasFetched) return;
    _isLoadingHome = true;
    notifyListeners();

    try {
      final data = await UserApiService.getCurrentUser();
      _userdata = data;
      _hasFetched = true;
    } catch (e) {
      print("Fehler beim Laden: $e");
    } finally {
      _isLoadingHome = false;
      notifyListeners();
    }
  }

  Future<void> _fetchLeaderboard() async {
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

  Future<void> _refreshLeaderboard() async {
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

    // TODO(test): nur zum Testen – zeigt die eigene "Du"-Zeile im Log.
    print('[leaderboard] entries: ${entries.length}, me: $_leaderboardMe');
  }
}

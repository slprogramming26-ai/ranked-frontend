import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
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

  bool get isLoading => _isLoading;
  bool get isLoadingHome => _isLoadingHome;
  bool get hasFetched => _hasFetched;
  Map<String, dynamic> get userdata => _userdata;
  List<Map<String, dynamic>> get leaderboardData => _leaderboardData;
  Map<String, dynamic>? get leaderboardMe => _leaderboardMe;
  bool get hasFetchedLeaderboard => _hasFetchedLeaderboard;
  bool get isLoadingLeaderboard => _isLoadingLeaderboard;

  Future<bool> getDidRanking() async {
    final prefs = await SharedPreferences.getInstance();
    return Streak.didActivityToday(prefs);
  }

  Future<void> refetchUserCredentials() async {

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


  void trueLoading() {
    _isLoading = true;
    notifyListeners();
  }

  void falseLoading() {
    _isLoading = false;
    notifyListeners();
  }

  Future<void> fetchUserCredentials() async {
    if (_hasFetched) return;
    _isLoadingHome = true;
    notifyListeners();
    await refetchUserCredentials(); // setzt _isLoadingHome=false im finally
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

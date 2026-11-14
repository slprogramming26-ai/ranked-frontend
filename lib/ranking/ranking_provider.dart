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
  // "Heute schon gerankt?" — eine Quelle fuer Leaderboard-Button UND die
  // Flamme am Ranking-Tab. Startet mit true, damit vor dem Laden keine Flamme
  // kurz aufblitzt.
  bool _rankedToday = true;

  RankingProvider() {
    loadRankedToday();
  }

  bool get isLoading => _isLoading;
  List<Map<String, dynamic>> get leaderboardData => _leaderboardData;
  Map<String, dynamic>? get leaderboardMe => _leaderboardMe;
  bool get hasFetchedLeaderboard => _hasFetchedLeaderboard;
  bool get isLoadingLeaderboard => _isLoadingLeaderboard;
  bool get rankedToday => _rankedToday;

  // Liest den Stand aus SharedPreferences. Billig, darf oft aufgerufen werden
  // (z.B. bei jedem Tab-Wechsel) — so kippt die Flamme auch nach Mitternacht.
  Future<void> loadRankedToday() async {
    final prefs = await SharedPreferences.getInstance();
    final value = Streak.didActivityToday(prefs);
    if (value == _rankedToday) return; // nichts geaendert -> kein Rebuild
    _rankedToday = value;
    notifyListeners();
  }

  // Nach einer abgeschlossenen Swipe-Session: speichern + sofort melden,
  // damit Flamme und Button ohne Neuladen umspringen.
  Future<void> markRankedToday() async {
    await Streak.markRankedToday();
    _rankedToday = true;
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


// "Heute schon gerankt?" als lokaler Cache. Die Wahrheit liegt beim Server:
// my_target meldet "bereits abgeschlossen" -> dann wird hier nachgezogen.
class Streak {
  // Neuer Key-Name statt 'saved_date_time_key': der alte enthaelt einen int,
  // getString() auf einen int-Wert wirft einen TypeError.
  static const _rankedOnKey = 'ranked_on_utc';
  static const _legacyKey = 'saved_date_time_key';

  // "YYYY-MM-DD" in UTC — gleiche Tagesgrenze wie das Backend (Reset 00:00 UTC).
  static String _todayUtc() =>
      DateTime.now().toUtc().toIso8601String().substring(0, 10);

  static bool didActivityToday(SharedPreferences prefs) =>
      prefs.getString(_rankedOnKey) == _todayUtc();

  static Future<void> markRankedToday() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_rankedOnKey, _todayUtc());
  }

  // Der Key haengt am Geraet, nicht am User -> beim Logout loeschen, sonst
  // erbt der naechste Account den Stand.
  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_rankedOnKey);
    await prefs.remove(_legacyKey);
  }
}

import 'package:shared_preferences/shared_preferences.dart';

class Streak {
  static const _streakKey = 'streak';
  static const _lastActivityKey = 'saved_date_time_key';


  // ANGUCKEN

  static Future<int> recordActivity() async {
    final prefs = await SharedPreferences.getInstance();

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final currentStreak = prefs.getInt(_streakKey) ?? 0;
    final lastActivity = _getLastActivity(prefs);

    int newStreak;
    if (lastActivity == null) {
      newStreak = 1;
    } else {
      final lastDay = DateTime(
        lastActivity.year,
        lastActivity.month,
        lastActivity.day,
      );
      final diff = today.difference(lastDay).inDays;

      if (diff == 0) {
        return currentStreak;
      } else if (diff == 1) {
        newStreak = currentStreak + 1;
      } else {
        newStreak = 1;
      }
    }

    await prefs.setInt(_streakKey, newStreak);
    await prefs.setInt(_lastActivityKey, today.millisecondsSinceEpoch);
    return newStreak;
  }


  static Future<int> getStreak() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_streakKey) ?? 0;
  }

  static Future<int> getStreakWithExpiry() async {
    final prefs = await SharedPreferences.getInstance();
    final lastActivity = _getLastActivity(prefs);
    if (lastActivity == null) return 0;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final lastDay = DateTime(
      lastActivity.year,
      lastActivity.month,
      lastActivity.day,
    );
    final diff = today.difference(lastDay).inDays;

    // 0 = heute aktiv, 1 = gestern aktiv (heute noch Zeit) -> Streak gilt.
    if (diff <= 1) return prefs.getInt(_streakKey) ?? 0;

    // Mehr als ein Tag Pause -> Streak ist tot.
    await prefs.setInt(_streakKey, 0);
    return 0;
  }

  static DateTime? _getLastActivity(SharedPreferences prefs) {
    final timestamp = prefs.getInt(_lastActivityKey);
    if (timestamp == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(timestamp);
  }

  static bool didActivityToday(SharedPreferences prefs) {
    final timestamp = prefs.getInt(_lastActivityKey);
    if (timestamp == null) return false;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final diff = today.difference(DateTime.fromMillisecondsSinceEpoch(timestamp)).inDays;
    return diff == 0;
  }
}
import 'package:intl/intl.dart';
import 'package:ranked/l10n/app_localizations.dart';

// Zentrale Zeit-/Datumsanzeige. Nimmt AppLocalizations statt BuildContext,
// damit es auch nach einem await funktioniert (l10n vorher holen).
// Die Sprache fürs Datum kommt aus l.localeName ("de"/"en").

/// "gerade eben" / "vor 5 Min." / "vor 3 Std." / "vor 2 Tg." / ab 7 Tagen
/// das Datum ("3. Okt. 2026" bzw. "Oct 3, 2026").
/// Die Differenz ist unabhängig von UTC/lokal (gleicher absoluter Zeitpunkt),
/// nur fürs Datum am Ende brauchen wir toLocal().
String timeAgo(AppLocalizations l, DateTime dt) {
  final diff = DateTime.now().difference(dt);
  if (diff.inMinutes < 1) return l.timeJustNow;
  if (diff.inMinutes < 60) return l.timeMinutesAgo(diff.inMinutes);
  if (diff.inHours < 24) return l.timeHoursAgo(diff.inHours);
  if (diff.inDays < 7) return l.timeDaysAgo(diff.inDays);
  return DateFormat.yMMMd(l.localeName).format(dt.toLocal());
}

/// Uhrzeit einer Chat-Nachricht: "14:30" (de) bzw. "2:30 PM" (en).
String chatTime(AppLocalizations l, DateTime dt) =>
    DateFormat.jm(l.localeName).format(dt.toLocal());

/// Datums-Trenner im Chat. [day] ist ein lokaler Tag ohne Uhrzeit.
String chatDayLabel(AppLocalizations l, DateTime day) {
  // Über DateTime.utc rechnen: Bei der Zeitumstellung liegen zwei lokale
  // Mitternächte nur 23 h auseinander -> inDays wäre 0 statt 1.
  final now = DateTime.now();
  final today = DateTime.utc(now.year, now.month, now.day);
  final diff = today
      .difference(DateTime.utc(day.year, day.month, day.day))
      .inDays;
  if (diff == 0) return l.timeToday;
  if (diff == 1) return l.timeYesterday;
  return DateFormat.yMMMd(l.localeName).format(day);
}

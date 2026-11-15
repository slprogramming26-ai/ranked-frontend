// Ergebnisse der beiden POST-Calls im ProfileRankingApiService.
// sealed wie TargetResult: ein vergessener Fall im switch ist ein
// Compile-Fehler.

// ── POST /profile_ranking/posts/{post_id} ────────────────────────────────────

/// Was beim Eintragen eines eigenen Posts ins Profil-Ranking herauskommt.
///
/// Nur 3 Fälle statt aller Backend-Fehler: Eingetragen wird nur direkt
/// nach dem Posten. Ein frischer eigener Post kann nicht "existiert nicht"
/// (404), "nicht deiner" (403), "zu alt" (400) oder "schon im Ranking"
/// (409) sein. Sollte trotzdem so etwas kommen -> EnterRankingFailed.
sealed class EnterRankingResult {
  const EnterRankingResult();
}

/// 201 -> Post ist ab heute im Ranking.
class EnterRankingOk extends EnterRankingResult {
  const EnterRankingOk();
}

/// 409 "Du hast heute schon einen Post ins Ranking gestellt."
/// Der Post ist trotzdem online, nur nicht im Ranking. Ab 00:00 UTC frei.
class EnterRankingSlotTaken extends EnterRankingResult {
  const EnterRankingSlotTaken();
}

/// Alles andere: kein Netz, 500, unerwarteter Fehler.
class EnterRankingFailed extends EnterRankingResult {
  const EnterRankingFailed();
}

// ── POST /profile_ranking/swipes ─────────────────────────────────────────────

/// Was beim Bewerten eines fremden Posts herauskommt.
sealed class RateResult {
  const RateResult();
}

/// 201 ODER 409 "schon bewertet" -> für uns dasselbe: erledigt, weiter.
class RateDone extends RateResult {
  const RateDone();
}

/// 403 / 404 / 409 "abgelaufen": Den Post gibt es fürs Bewerten nicht mehr
/// (entfolgt, Block, gelöscht, 7 Tage vorbei). Lokal entfernen, weiter.
class RateGone extends RateResult {
  const RateGone();
}

/// Kein Netz / 500 -> Bewertung ist NICHT gespeichert.
class RateFailed extends RateResult {
  const RateFailed();
}

/// Was bei RankingApiService.getMyTarget herauskommt (GET /ranking/my_target).
/// sealed wie VerifyResult: ein vergessener Fall im switch ist ein
/// Compile-Fehler.
sealed class TargetResult {
  const TargetResult();
}

/// 200 mit mindestens einem Post -> es kann bewertet werden.
/// posts ist nie leer (200 ohne Posts wird zu TargetNoneAvailable).
class TargetFound extends TargetResult {
  const TargetFound({required this.targetUser, required this.posts});

  /// user_data aus der Antwort (UserOut) - wer heute bewertet wird.
  final Map<String, dynamic> targetUser;

  /// Bare Post-Objekte, max. 20.
  final List<dynamic> posts;
}

/// 404 "Dein heutiges Ranking ist bereits abgeschlossen." ODER
/// 404 "Für heute sind keine weiteren Neuziehungen möglich."
/// Heute geht nichts mehr -> NICHT neu laden (sonst Schleife).
class TargetLimitReached extends TargetResult {
  const TargetLimitReached();
}

/// Jede andere 404 (oder 200 ohne Posts): gerade ist niemand zum
/// Bewerten da. Auch der Fallback, falls das Backend seine Saetze aendert.
class TargetNoneAvailable extends TargetResult {
  const TargetNoneAvailable();
}

/// Server nicht erreichbar (kein Netz, DNS, Timeout ...).
class TargetOffline extends TargetResult {
  const TargetOffline();
}

/// Alles Unerwartete (500, kaputtes JSON ...).
class TargetError extends TargetResult {
  const TargetError();
}

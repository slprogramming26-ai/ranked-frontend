/// Was bei UserApiService.resetPassword herauskommt
/// (POST /users/password/reset).
/// sealed wie VerifyResult: ein vergessener Fall im switch ist ein
/// Compile-Fehler.
sealed class ResetResult {
  const ResetResult();
}

/// 204: Passwort geaendert. Anders als bei verify gibt es KEINE Token ->
/// zurueck zum Login, dort mit dem neuen Passwort anmelden.
class ResetOk extends ResetResult {
  const ResetOk();
}

/// 400: falsch, abgelaufen, 5 Versuche weg oder unbekannte E-Mail -
/// der Server unterscheidet das absichtlich nicht.
class ResetCodeInvalid extends ResetResult {
  const ResetCodeInvalid();
}

/// 429 mit "detail": 10 Fehlversuche heute -> erst morgen wieder.
class ResetDailyLimit extends ResetResult {
  const ResetDailyLimit();
}

/// 429 von slowapi ("error"): zu viele Requests pro Minute -> kurz warten.
class ResetTooManyRequests extends ResetResult {
  const ResetTooManyRequests();
}

/// Server nicht erreichbar (kein Netz, DNS, Timeout ...).
class ResetOffline extends ResetResult {
  const ResetOffline();
}

/// Alles Unerwartete (422 trotz UI-Pruefung, 500, kaputte Antwort ...).
class ResetError extends ResetResult {
  const ResetError();
}

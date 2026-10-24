/// Was bei UserApiService.deleteSuspendedAccount herauskommt
/// (POST /users/delete - Konto per E-Mail + Passwort loeschen, ohne Token).
/// sealed wie ResetResult: ein vergessener Fall im switch ist ein
/// Compile-Fehler.
sealed class DeleteResult {
  const DeleteResult();
}

/// 200/204: Konto ist auf dem Server weg. Keypair + Token sind schon
/// geloescht, die lokale DB muss der Aufrufer noch leeren.
class DeleteOk extends DeleteResult {
  const DeleteOk();
}

/// 401: E-Mail unbekannt oder Passwort falsch - der Server unterscheidet
/// das absichtlich nicht (keine User-Enumeration).
class DeleteInvalid extends DeleteResult {
  const DeleteInvalid();
}

/// 429: mehr als 5 Versuche pro Minute -> kurz warten.
class DeleteTooManyRequests extends DeleteResult {
  const DeleteTooManyRequests();
}

/// Server nicht erreichbar (kein Netz, DNS, Timeout ...).
class DeleteOffline extends DeleteResult {
  const DeleteOffline();
}

/// Alles Unerwartete (422 trotz UI-Pruefung, 500, ...).
class DeleteError extends DeleteResult {
  const DeleteError();
}

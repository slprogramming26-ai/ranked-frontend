/// Was bei UserApiService.resendVerification und .forgotPassword
/// herauskommt (POST /users/verify/resend, /users/password/forgot).
/// sealed wie VerifyResult: ein vergessener Fall im switch ist ein
/// Compile-Fehler.
sealed class CodeRequestResult {
  const CodeRequestResult();
}

/// 204 - und bewusst auch jeder andere unerwartete Status: Der Server
/// antwortet bei unbekannter E-Mail ebenfalls mit 204, damit niemand
/// testen kann, welche Adressen registriert sind. Die App darf das nicht
/// durch eine eigene Fehlermeldung verraten.
class CodeRequestSent extends CodeRequestResult {
  const CodeRequestSent();
}

/// 429: der letzte Code ist keine 60 s alt.
class CodeRequestCooldown extends CodeRequestResult {
  const CodeRequestCooldown();
}

/// Server nicht erreichbar (kein Netz, DNS, Timeout ...).
class CodeRequestOffline extends CodeRequestResult {
  const CodeRequestOffline();
}

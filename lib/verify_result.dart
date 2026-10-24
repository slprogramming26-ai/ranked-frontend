import 'moderation/suspension.dart';

/// Was bei UserApiService.verify herauskommt (POST /users/verify).
/// sealed wie LoginResult: ein vergessener Fall im switch ist ein
/// Compile-Fehler.
sealed class VerifyResult {
  const VerifyResult();
}

/// 200: Code stimmt, Token sind gespeichert -> direkt eingeloggt.
class VerifyOk extends VerifyResult {
  const VerifyOk();
}

/// 400: falsch, abgelaufen, 5 Versuche weg oder unbekannte E-Mail -
/// der Server unterscheidet das absichtlich nicht.
class VerifyCodeInvalid extends VerifyResult {
  const VerifyCodeInvalid();
}

/// 409: E-Mail war schon bestaetigt -> zum Login.
class VerifyAlreadyOk extends VerifyResult {
  const VerifyAlreadyOk();
}

/// 429: zu viele Versuche in kurzer Zeit.
class VerifyTooManyRequests extends VerifyResult {
  const VerifyTooManyRequests();
}

/// Server nicht erreichbar (kein Netz, DNS, Timeout ...).
class VerifyOffline extends VerifyResult {
  const VerifyOffline();
}

/// 403: Account gesperrt - dieselbe Sperr-Info wie beim Login.
class VerifyBanned extends VerifyResult {
  const VerifyBanned(this.suspension);
  final Suspension suspension;
}

/// Alles Unerwartete (500, kaputte Antwort ...).
class VerifyError extends VerifyResult {
  const VerifyError();
}

import 'moderation/suspension.dart';

/// Was bei UserApiService.login herauskommt.
///
/// sealed statt enum: eine feste Auswahl wie beim enum, aber jede Variante
/// darf eigene Daten tragen (LoginSuspended bringt die Sperre mit). Ein
/// switch darueber braucht kein default -> ein vergessener Fall ist ein
/// Compile-Fehler.
sealed class LoginResult {
  const LoginResult();
}

/// 200: Token sind gespeichert.
class LoginOk extends LoginResult {
  const LoginOk();
}

/// Falsche E-Mail/Passwort oder sonst eine Absage vom Server.
class LoginInvalid extends LoginResult {
  const LoginInvalid();
}

/// Der Server war nicht erreichbar (kein Netz, DNS, Timeout ...).
class LoginOffline extends LoginResult {
  const LoginOffline();
}

/// 403: Passwort war richtig, aber der Account ist gesperrt.
class LoginSuspended extends LoginResult {
  const LoginSuspended(this.suspension);
  final Suspension suspension;
}

// Passwort-Regel fuer neue Passwoerter (Registrierung + Reset).
// Gleich wie PasswordReset.new_password im Backend. NICHT beim Login
// pruefen: Altkonten koennen kuerzere Passwoerter haben.

const minPasswordLength = 8;
const maxPasswordLength = 128;

/// runes = Unicode-Zeichen wie Pythons len(). .length zaehlt UTF-16-
/// Einheiten -> ein Emoji waere hier 2, im Backend 1 -> 422 trotz Pruefung.
int passwordLength(String password) => password.runes.length;

bool isValidPasswordLength(String password) {
  final length = passwordLength(password);
  return length >= minPasswordLength && length <= maxPasswordLength;
}

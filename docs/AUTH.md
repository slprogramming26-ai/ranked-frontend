# Auth: Login, Session, Logout — Übersicht

Stand: 14.11.2026. Nachschlagewerk: Wie kommt man rein, wie bleibt man drin, wie fliegt man raus, und was passiert dabei mit den Daten.
Was beim Login mit den Chat-Schlüsseln passiert, steht in `docs/E2EE.md` (Abschnitt 3 + 4). Die Messenger-Verbindung steht in `docs/MESSENGER.md`.

## Das Grundprinzip in einem Bild

Zwei Tokens, ein Wächter, ein Notausgang.

```
  REINKOMMEN                    DRINBLEIBEN                     RAUSFLIEGEN
  ──────────                    ───────────                     ───────────
  Login / Verify                ApiClient._send                 ApiClient.forceLogoutStream
  → access + refresh            jeder Request:                  (EIN Stream für ALLE Logouts)
    speichern                    401 → refresh → 1× wiederholen          │
                                 403-Sperre → raus                       ▼
  App-Start mit                                                 main.dart-Listener:
  Refresh-Token                                                  Messenger stoppen
  → /refresh                                                     DB leeren
    (Session-Restore)                                            Session neu bauen
                                                                 → LoginScreen
```

**Merksatz:** Egal **warum** jemand ausgeloggt wird (Button, Token tot, gesperrt, Konto gelöscht, Chat-Key veraltet), es endet immer im **selben** Stream und damit im **selben** Aufräumcode in `main.dart`. Es gibt keinen zweiten Logout-Weg.

---

## 0. Die zwei Tokens

| | Access-Token | Refresh-Token |
|---|---|---|
| Lebensdauer | kurz (~30 min) | lang (~60 Tage) |
| Gespeichert in | `SharedPreferences` (schnell, wird bei jedem Request gelesen) | `flutter_secure_storage` (Keystore / Keychain) |
| Wofür | `Authorization: Bearer …` bei jedem Request, `?token=` beim WebSocket | nur für POST `/refresh` |
| Code | `lib/core/token_storage.dart` → `saveToken`, `getToken` | `saveRefreshToken`, `getRefreshToken` |

- **Rotation:** Jeder `/refresh` liefert ein **neues Paar**. Der alte Refresh-Token ist danach serverseitig ungültig.
- `TokenStorage.clearAll()` löscht beide. Das ist der Kern jedes Logouts.
- Der Passwort-Reset und ein Bann löschen im Backend **alle** Refresh-Tokens des Users. Andere Geräte fliegen beim nächsten Refresh raus.

---

## 1. Der Wächter: `ApiClient._send`

Alle authentifizierten Requests (`ApiClient.get/post/put/patch/delete/uploadFile`) laufen hier durch.

```
Token lesen → Request senden
 │
 ├─ 401?  → _refreshOnce()  (Single-Flight: parallele 401s warten auf DENSELBEN Refresh)
 │           ├─ ok    → neuen Token lesen, Request GENAU EINMAL wiederholen
 │           └─ nicht → _forceLogout(), das 401 an den Aufrufer zurückgeben
 │
 └─ danach: Antwort ist 403 mit Sperre?  (Suspension.fromResponse)
             → _forceLogout(suspension: …)
```

- Die Sperr-Prüfung kommt **nach** dem 401-Block. Bei abgelaufenem Token kommt das 403 erst beim Retry mit dem frischen Token.
- `_refreshOnce` hält das laufende Refresh-Future in `_refreshing`. Ohne den Lock würden fünf parallele 401s fünf Refreshes starten, und wegen der Rotation wären vier davon mit einem schon verbrauchten Token unterwegs → Logout.
- `_loggingOut` verhindert, dass parallele Fehler den Zwangs-Logout mehrfach auslösen. `resetLogoutGuard()` gibt ihn nach dem nächsten erfolgreichen Login wieder frei (in `UserApiService._saveSession`).
- **Ein einziger `http.Client`** für alle Requests (Keep-Alive, kein neuer TLS-Handshake pro Request).

### Bewusst NICHT über `ApiClient`

Diese Calls nutzen rohes `http.post`, weil `_send` ihr 401/403 falsch deuten würde oder es noch gar keinen Token gibt:

| Call | Warum roh |
|---|---|
| `UserApiService.login` | noch kein Token, Body ist form-urlencoded (OAuth2-Form); prüft die Sperre selbst |
| `verify`, `resendVerification`, `forgotPassword`, `resetPassword` | noch kein Token |
| `createUser` | Registrierung, noch kein Token |
| `deleteSuspendedAccount` | ein 401 heißt hier „falsches Passwort“. `_send` würde es als abgelaufenen Token lesen → Refresh → Zwangs-Logout |
| `ApiClient._refresh` | sonst würde der Refresh sich selbst refreshen |

Alle rohen Calls fangen Netzwerkfehler ab und geben einen `…Offline`-Fall zurück, sonst dreht der Spinner ewig.

---

## 2. App-Start: Session-Restore

`main.dart` → `_MyHomePageState._checkExistingSession`

```
Splash an (mindestens 1,1 s, läuft parallel)
Refresh-Token vorhanden?
 ├─ nein → LoginScreen
 └─ ja   → ApiClient.tryRefreshOnStart() (= POST /refresh)
            ├─ ok    → Home + _startMessenger() + Entwurf retten
            └─ nicht → LoginScreen
```

- Beim Session-Restore läuft **kein** `KeySetup`, denn es gibt kein Passwort. Der Messenger lädt nur den lokalen Key und gleicht den Pubkey mit dem Server ab (`MessengerController._checkOwnPublicKey`). Ist er veraltet → Logout mit Hinweis (siehe 5.).
- Daraus folgt eine wichtige Regel: **Tokens dürfen nur gespeichert bleiben, wenn das KeySetup durch ist.** Sonst würde der nächste App-Start ohne Keys einloggen. Deshalb löschen Login und Onboarding die Tokens in jedem Fehlerpfad wieder (siehe 3. und 4.).

---

## 3. Login

`lib/auth/login_screen.dart` → `_handleLogin`, Ergebnis-Typ `lib/auth/login_result.dart` (sealed).

```
UserApiService.login(email, passwort)
 ├─ LoginOk            → Tokens gespeichert, weiter unten
 ├─ LoginInvalid       → "E-Mail oder Passwort falsch"
 ├─ LoginOffline       → "Server nicht erreichbar"
 ├─ LoginSuspended     → SuspendedScreen (Sperre aus der 403-Antwort)
 └─ LoginNotVerified   → VerifyEmailScreen (schickt gleich einen neuen Code)
                          ├─ abgebrochen → zurück zum Formular
                          └─ bestätigt   → verify()-Tokens wegwerfen, _handleLogin() nochmal

nach LoginOk:
 getCurrentUser() → userId
 KeySetup.afterLogin(userId, passwort, passwordChanged: _passwordJustReset)
 _resolveKeySetup → Dialoge (Backup-Passwort / "Chats zurücksetzen")
  ├─ ready → widget.onLoginSuccess()
  └─ sonst → TokenStorage.clearAll(), Fehlermeldung, im Login bleiben

onLoginSuccess (main.dart):
 db.clearDatabase()  → kein Rest eines früheren Users
 Tab-Cache leeren, Tab 0
 loggedIn = true → _startMessenger()
```

- **Warum werden die `verify()`-Tokens weggeworfen?** `verify` loggt zwar direkt ein, aber ohne Passwort-Kontext für das KeySetup. Scheitert der zweite Login (z.B. offline), würden sie liegen bleiben, und der nächste App-Start würde ohne Keys einloggen.
- `LoginResult` ist `sealed`, und der `switch` hat kein `default`. Ein neuer Fall ist damit ein Compile-Fehler statt eines vergessenen Pfads.

### Passwort vergessen

`forgot_password_screen.dart`: Code anfordern → Code + neues Passwort → 204. Der Screen gibt E-Mail + neues Passwort an den LoginScreen zurück. Der füllt die Felder, setzt `_passwordJustReset = true` und loggt automatisch ein. Was dabei mit dem Key-Backup passiert: `docs/E2EE.md` Abschnitt 4.

`resetPassword` speichert **keine** Tokens (204 ohne Body). Eingeloggt wird erst über den normalen Login.

Code-Anfragen (`resend`, `forgot`) melden außer 429 immer „gesendet“, auch wenn es die E-Mail nicht gibt. So verrät die App nicht, welche Adressen registriert sind.

---

## 4. Registrierung (Onboarding)

`lib/onboarding/onboarding_flow.dart` → `_handleNextStep`, Prinzip **collect-first, create-last**: Erst der letzte Button legt das Konto an.

```
createUser(email, username, passwort, alter)   (nur bei NEUER E-Mail, sonst Konto wiederverwenden)
VerifyEmailScreen                              → verify() speichert Tokens
UserApiService.login(email, passwort)          → nochmal, denn bei 409 "schon bestätigt" gibt verify keine Tokens
 └─ nicht ok → TokenStorage.clearAll(), Fehler anzeigen
KeySetup.afterRegistration (best-effort)       → scheitert es, holt der nächste Login es nach
Bild hochladen + Details (best-effort)
Navigator.pushReplacement(MyHomePage)          → Session-Restore dort findet die Tokens
```

Ab dem erfolgreichen Login ist alles best-effort: Das Konto existiert schon, der User muss in die App kommen. Bild, Bio und Vibes kann er im Profil nachtragen.

---

## 5. Logout: alle Wege, ein Ziel

### Die Auslöser

| Auslöser | Wo | Aufruf | Besonderheit |
|---|---|---|---|
| Logout-Button | `settings_screen.dart` → `_handleLogout` | `ApiClient.logout()` | nur lokal, es gibt noch keinen `/logout`-Endpoint |
| Konto löschen | `settings_screen.dart` → `_handleDelete` | DELETE `/users/` → Keypair löschen → `ApiClient.logout()` | einziger Weg (neben gesperrt löschen), der das E2EE-Keypair löscht |
| Refresh scheitert | `ApiClient._send` | `_forceLogout()` | Refresh-Token abgelaufen, rotiert, oder vom Server gelöscht (Reset/Bann) |
| Account gesperrt (REST) | `ApiClient._send` | `_forceLogout(suspension: …)` | jedes 403 mit Sperr-Body |
| Account gesperrt (WS) | `_handleDrop` bei Close-Code 4003 | `ApiClient.checkSuspension()` → GET `/users/` → 403 → wie oben | kein Reconnect |
| Chat-Key veraltet | `MessengerController._checkOwnPublicKey` | Keypair löschen → `KeySetup.setLogoutNotice(…)` → `ApiClient.logout()` | „Chats zurücksetzen“ auf einem anderen Gerät |

`logout()` und `_forceLogout()` machen dasselbe: `TokenStorage.clearAll()` + Event auf `forceLogoutStream`. `_forceLogout` hat zusätzlich den `_loggingOut`-Riegel und kann eine Sperre mitgeben.

### Der Aufräumcode (`main.dart`, Listener in `initState`)

```
forceLogoutStream
 1. MessengerController.shutdown()     ← ZUERST, sonst schreibt der WS evtl. noch in die DB
 2. db.clearDatabase()                 ← alle Tabellen, eine Transaktion
 3. Streak.clear()                     ← "heute gerankt"-Cache (hängt am Gerät, nicht am User)
 4. SessionScopeState.startNewSession()
 5. loggedIn = false                   → LoginScreen
```

**`startNewSession`** zählt einen Key hoch, der am `ProviderScope` in `SessionScope` hängt. Flutter wirft dadurch den kompletten Unterbaum weg und baut ihn neu: alle `ChangeNotifier` (Ranking, Post, Story, Profile, MessengerController), den ganzen Riverpod-Speicher und auch die `MaterialApp` samt Navigator-Stack. So sieht der nächste User garantiert nichts vom vorherigen. Konkret passiert ist das vorher mit gecachten Kommentaren (`is_mine` vom alten User).

Der `ProviderScope` steht deshalb **in** `SessionScope` und nicht ganz oben in `runApp`, sonst würde er den Logout überleben.

### Briefkästen für den LoginScreen

Der LoginScreen wird beim Logout neu gebaut. Ein Feld darin wäre also sofort weg. Deshalb gibt es zwei statische „Briefkästen“, die der LoginScreen in `initState` **einmal** leert (lesen + löschen in einem Schritt):

| Briefkasten | Setzt | Zeigt |
|---|---|---|
| `ApiClient.takeSuspension()` | `_forceLogout(suspension:)` | `SuspendedScreen` statt Formular |
| `KeySetup.takeLogoutNotice()` | `_checkOwnPublicKey` | Hinweis „Chat-Schlüssel auf anderem Gerät zurückgesetzt“ |

Die Sperre wird **vor** dem Stream-Event eingeworfen, sonst wäre der Briefkasten leer, wenn der neue LoginScreen nachschaut.

### Was überlebt einen Logout, was nicht

| Bleibt | Wird gelöscht |
|---|---|
| E2EE-Identity-Keypair (pro userId im Secure Storage) | Access- + Refresh-Token |
| Gruppen-Keys | komplette Drift-DB (Chats, Chatliste, Marker, Suchverlauf, Post-Entwurf) |
| Dark Mode, Sprache (Geräte-Einstellungen) | „heute gerankt“-Cache |
| | alle Provider + Riverpod-Zustand im RAM |

Das Keypair bleibt, damit ein Re-Login auf demselben Gerät sofort alle Chats lesen kann.

---

## 6. Gesperrt & Konto löschen

### Sperre erkennen (`lib/moderation/suspension.dart`)

`Suspension.fromResponse` versteht zwei Formen eines 403:
- `{"detail": "account suspended until 2026-…"}` (Text)
- `{"detail": {"code": "account_suspended", "banned_until": "…", "ban_reason": "…"}}` (Map)

Dauerhaft = Jahr 9999. Die Methode **wirft nie**, denn sie läuft für jedes 403 in `_send`. Ein normales 403 (z.B. keine Rechte) ergibt `null` und ist dann keine Sperre.

### Konto löschen

| Weg | Endpoint | Warum so |
|---|---|---|
| Normal (Settings) | DELETE `/users/` über `ApiClient` | eingeloggt, Token vorhanden |
| Gesperrt (`delete_suspended_dialog.dart`) | POST `/users/delete` mit E-Mail + Passwort, roh | Ein Bann löscht die Refresh-Tokens und `/login` gibt 403, ein Token ist also nicht zu bekommen |

Den Gesperrt-Weg gibt es an zwei Stellen: im `SuspendedScreen` nach Login/Zwangs-Logout und im `VerifyEmailScreen`, wenn `verify()` eine Sperre meldet (`VerifyBanned`). Dort meldet `onAccountDeleted` dem Aufrufer, dass das Konto weg ist (Onboarding legt beim nächsten Absenden ein neues an, der Login leert die Felder).

Beide Löschwege entfernen **nur das Keypair dieser userId**. Andere Konten auf demselben Gerät behalten ihre Keys.

---

## Die Regeln, die alles zusammenhalten

1. **Ein Logout-Weg.** Wer ausloggen will, ruft `ApiClient.logout()` (oder es passiert in `_send`). Niemand räumt selbst DB oder Provider auf, das macht nur der Listener in `main.dart`.
2. **Tokens nur mit fertigem KeySetup.** Jeder Fehlerpfad nach einem erfolgreichen `/login` ruft `TokenStorage.clearAll()`. Sonst würde der Session-Restore ohne Keys einloggen.
3. **Erst Messenger stoppen, dann DB leeren.**
4. **Session-Neustart statt Einzel-Reset.** Kein Provider muss selbst wissen, was er beim Logout zurücksetzt, der Key-Wechsel in `SessionScope` erzeugt alle neu.
5. **Refresh nur Single-Flight.** Wegen der Rotation darf nie mehr als ein `/refresh` gleichzeitig laufen.

---

## Bekannte Grenzen & offene Punkte

| # | Punkt | Schwere | Plan |
|---|---|---|---|
| 1 | Logout ist nur lokal. Der Refresh-Token bleibt auf dem Server gültig, bis er abläuft. Wer ihn vorher kopiert hat, bleibt drin. | mittel | `/logout`-Endpoint im Backend, dann in `_handleLogout` vor `ApiClient.logout()` aufrufen (TODO steht im Code). |
| 2 | **Offline-Start landet im LoginScreen**, obwohl die Session gültig ist: `tryRefreshOnStart` scheitert ohne Netz → `loggedIn = false`. Die Tokens bleiben aber liegen, mit Netz klappt der nächste Start. | mittel | Hängt an „App-Start Polish“ Phase 3b (cache-first). Netzfehler ≠ abgelehnter Token unterscheiden. |
| 3 | Das Onboarding endet mit `pushReplacement(MyHomePage(...))`. Damit liegen **zwei** `MyHomePage` im Navigator (die alte zeigt darunter den LoginScreen). `initialLoggedIn` wird nirgends gelesen, die neue zeigt deshalb nochmal den Splash und macht einen Session-Restore. Beim nächsten Logout laufen **beide** `forceLogoutStream`-Listener (doppeltes shutdown/clearDatabase/startNewSession). Funktioniert, weil alles idempotent ist und `startNewSession` den Navigator ohnehin neu baut. | niedrig | Onboarding wie den Login über einen `onLoginSuccess`-Callback zurückgeben statt eine zweite Home-Seite zu pushen. `initialLoggedIn` dann entfernen. |
| 4 | `ApiClient` hat kein Timeout. Ein hängender Server lässt Spinner beliebig lang drehen. | niedrig | Später `.timeout(...)` in `_send` und den rohen Calls. |
| 5 | Der Access-Token liegt unverschlüsselt in SharedPreferences. | bekannt | Bewusst. Er ist kurzlebig, der langlebige Refresh-Token liegt im Secure Storage. |
| 6 | Kein „Passwort ändern“ in den Settings. | — | Kommt mit Backup-Rewrap (`passwordChanged: true`, siehe `E2EE.md` #8). |
| 7 | Widerspruch gegen eine Sperre ist nicht möglich. | — | Später. |

## Glossar

- **Access-Token:** kurzlebiger Ausweis, geht bei jedem Request mit.
- **Refresh-Token:** langlebiger Schlüssel, mit dem man sich einen neuen Access-Token holt. Gibt man ihn ab, bekommt man ein neues Paar (Rotation).
- **Rotation:** Jeder Refresh-Token ist nur einmal benutzbar. Ein gestohlener und schon benutzter Token ist damit wertlos.
- **Session-Restore:** beim App-Start ohne Passwort einloggen, nur mit dem gespeicherten Refresh-Token.
- **Zwangs-Logout:** Logout, den nicht der User auslöst (Token tot, Sperre, Key veraltet).
- **Single-Flight:** Läuft ein Refresh schon, warten alle weiteren auf genau diesen statt einen eigenen zu starten.
- **Briefkasten (take…):** statisches Feld, das genau einmal gelesen und dabei geleert wird, um eine Nachricht über einen Neuaufbau des Screens hinweg zu transportieren.
- **SessionScope / startNewSession:** Key-Wechsel am obersten Session-Widget. Alles darunter wird weggeworfen und frisch erzeugt.
- **User-Enumeration:** herausfinden, welche E-Mails registriert sind, anhand unterschiedlicher Server-Antworten. Deshalb antworten die Code-Anfragen immer gleich.

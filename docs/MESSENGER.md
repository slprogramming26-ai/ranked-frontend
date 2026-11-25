# Messenger & WebSocket — Übersicht

Stand: 14.11.2026. Nachschlagewerk: Wie kommen Nachrichten rein und raus, wer besitzt die Verbindung, wo liegt was.
Die Verschlüsselung selbst steht in `docs/E2EE.md`, Login/Logout in `docs/AUTH.md`.

## Das Grundprinzip in einem Bild

Es gibt **zwei Wege** für Nachrichten und **eine** Stelle, aus der die UI liest.

```
        SERVER
   ┌───────────────┐                 ┌──────────────────────────┐
   │  REST-API     │ ── Nachsync ──▶ │                          │
   │  /messages/…  │  (bei Connect)  │   Drift-DB (lokal)       │
   ├───────────────┤                 │   Klartext, dedupliziert │ ──watch()──▶  UI
   │  WS-Gateway   │ ── live ──────▶ │   über client_msg_id     │   (Chatliste,
   │  /ws/chat     │  (_events-Band) │                          │    Chat-Screen)
   └───────────────┘                 └──────────────────────────┘
          ▲
          └── Senden: immer über den WebSocket
```

**Merksätze:**
- **REST holt nach, WebSocket liefert live.** Bei jedem (Re)connect läuft zuerst der REST-Sync, erst danach geht der WebSocket auf.
- **Die UI liest nur aus der DB.** Sie hört nicht direkt auf den WebSocket. Alles, was ankommt, wird erst gespeichert, und die `watch()`-Streams der DB bauen die UI neu.
- **Doppelt ankommen ist egal.** Jede Nachricht trägt eine `client_msg_id` (UUID). Die Spalte ist `unique`, gespeichert wird mit `insertOrIgnore`. Lokales Echo, WS-Push und REST-Sync derselben Nachricht ergeben genau eine Zeile.
- **Der Server ist die Wahrheit** für Gruppen-Mitgliedschaften (Name, Bild, ob ich noch drin bin).

---

## 0. Wer besitzt was

| Was | Wo |
|---|---|
| App-weiter Besitzer der Verbindung | `lib/messenger/messenger_controller.dart` → `MessengerController` (ChangeNotifier in `SessionScope`, `main.dart`) |
| Service: Zustand + Gruppen-REST (static) | `messenger_api_service.dart` → `MessengerApiService` |
| Verbinden, Heartbeat, Reconnect | `messenger_api_service.connection.dart` → `connect`, `_doConnect`, `reconnect`, `disconnect`, `dispose`, `_handleDrop`, `_scheduleReconnect` |
| Empfangen speichern + REST-Nachsync | `messenger_api_service.sync.dart` → `_persistIncoming`, `_syncAll`, `_syncDmHistory`, `_syncGroupHistory` |
| Senden | `messenger_api_service.send.dart` → `sendDirectMessage`, `sendGroupMessage`, `_awaitGroupResponse` |
| Ver-/Entschlüsseln | `messenger_api_service.crypto.dart` (siehe `docs/E2EE.md`) |
| Protokoll-Vokabular | `chat_event.dart` → `ChatEvent` (sealed) + `parseChatEvent` |
| Lokale Tabellen | `lib/local_data/tables.dart` → `DmChatHistory`, `GroupChatHistory`, `OpenChats`, `SyncMarkers` |
| Adressen | `lib/core/api_config.dart` → `baseUrl` (REST), `wsUrl` (Gateway) |

Der Service ist per `part` auf mehrere Dateien verteilt. Alle Parts sind **eine** Library und dürfen deshalb auf die privaten Felder in `messenger_api_service.dart` zugreifen.

---

## 1. Lebenszyklus der Verbindung

### Wer startet und stoppt

```
Login / Session-Restore (main.dart → _startMessenger)
        │  ProfileProvider.fetchUser() → userId
        ▼
MessengerController.init(db, userId)
        │  idempotent: gleicher User → nichts tun, anderer User → erst shutdown()
        │  addObserver(this)               → App-Lifecycle mithören
        │  _service = MessengerApiService(db, userId)
        │  _service.incoming.listen(...)   → EINMAL abonnieren reicht
        │  _service.connect()
        │  _checkOwnPublicKey() parallel   → E2EE-Abgleich (siehe E2EE.md)
        ▼
   … App läuft, Verbindung lebt die ganze Login-Session …
        ▼
Logout (forceLogoutStream in main.dart)
        │  MessengerController.shutdown()  → removeObserver, Abo weg, service.dispose()
        ▼
   erst DANACH db.clearDatabase()
```

Reihenfolge beim Logout ist wichtig: **erst Messenger stoppen, dann DB leeren.** Andersrum könnte eine eingehende Nachricht zwischen Leeren und Stoppen noch in die DB schreiben.

### Das Förderband (`_events`)

```
 WebSocket #1 ──┐
 WebSocket #2 ──┼──▶  _events (StreamController.broadcast, lebt so lange wie der Service)
 WebSocket #3 ──┘          │
                           ├──▶ _enqueue → _persistIncoming   (im Konstruktor angehängt → DB)
                           ├──▶ MessengerController._handleEvent (nur Debug-Log)
                           └──▶ _awaitGroupResponse (kurzzeitig, pro Gruppen-Send)
```

Jede einzelne WebSocket-Verbindung kippt ihre geparsten Events auf **dasselbe** Band. Deshalb muss nach einem Reconnect niemand neu abonnieren. `disconnect()` schließt nur die Verbindung, `dispose()` schließt zusätzlich das Band.

### Die Persistenz-Kette (`_persistQueue`)

Das Band ruft seinen Listener für jedes Event sofort auf, auch wenn das vorige noch mitten in einem `await` steckt. Früher liefen deshalb zwei schnelle DMs eines Fremden **parallel** durch `_ensureDmOpenChat`: Beide sahen „kein Chat da“, beide legten eine Zeile an. Danach warf `getSingleOrNull` einen `StateError`, und Live-Empfang und Sync waren tot.

Heute hängt `_enqueue` jedes Event hinten an eine Future-Kette:

```
_persistQueue = _persistQueue
    .then((_) => _persistIncoming(e).timeout(30 s))   ← erst wenn das vorige fertig ist
    .catchError(log)                                   ← ohne das würde ein Fehler die Kette für immer töten
```

- **Nacheinander:** Events werden genau in Empfangsreihenfolge gespeichert, keine Duplikate, keine vertauschte Reihenfolge.
- **Timeout innen:** Die 30 s laufen erst, wenn das Event an der Reihe ist. Ein hängendes Event blockiert so nicht alle folgenden. (Das Timeout bricht die Arbeit nicht ab. Ein Nachzügler trifft dann auf `insertOrIgnore`.)
- Zweite Schutzschicht für Wege, die **nicht** durch die Kette laufen (Sync gegen Live, UI-Inserts): der Unique-Index auf `OpenChats` (Abschnitt 6).
- Test: `test/messenger_race_test.dart` (3 DMs direkt hintereinander → genau 1 Anfrage, 3 Nachrichten in Reihenfolge).

### `connect()` — Single-Flight

```
connect()
 ├─ _channel != null           → schon verbunden, fertig
 └─ _connectFuture ??= _doConnect()   → läuft schon ein Aufbau, hängen sich alle dran

_doConnect()
 1. _manuallyClosed = false
 2. await _syncAll()            ← REST-Nachsync (Abschnitt 3)
    wirft (offline, Server down) → _scheduleReconnect, WS bewusst NICHT öffnen
 3. abgebrochen? (disconnect() kam dazwischen) → raus
 4. Token lesen, IOWebSocketChannel.connect('$wsUrl/ws/chat?token=…', pingInterval: 20 s)
 5. stream.listen: JSON → parseChatEvent → _events.add
                   onDone / onError → _handleDrop
```

Warum bei Sync-Fehler kein WebSocket? Würde der WS trotzdem aufgehen, schöbe die erste Live-Nachricht den Marker über die nicht nachgeholte Lücke hinweg, und die verpassten Nachrichten kämen nie mehr. Früher fing niemand den Fehler, der Reconnect-Timer starb, und der Messenger blieb bis zum Logout offline.

Nebeneffekt von Schritt 2: Der Sync geht über `ApiClient`. Ist der Access-Token abgelaufen, wird er dort refresht. Der Token, der in Schritt 4 in die WS-URL wandert, ist deshalb frisch.

### Heartbeat, Abriss, Auto-Reconnect

| Situation | Was passiert |
|---|---|
| Verbindung still tot (Funkloch, OS kappt im Standby) | `dart:io` schickt alle **20 s** ein Ping. Bleibt das Pong aus, wird geschlossen → `_handleDrop` |
| `_handleDrop`, normal | `_scheduleReconnect`: Backoff **1, 2, 4, 8, 16 s**, gedeckelt bei 30 s. Jede empfangene Nachricht setzt den Zähler auf 0 |
| Sync in `_doConnect` scheitert (z. B. Flugmodus) | Log `[WS] Sync fehlgeschlagen`, `_scheduleReconnect` mit demselben Backoff. Kein WS, bis ein Sync klappt |
| `_handleDrop`, Close-Code **4003** (Account gesperrt) | **Kein** Reconnect. `ApiClient.checkSuspension()` macht einen REST-Call, der liefert das 403 mit Sperr-Details → Zwangs-Logout + Sperr-Screen (siehe `AUTH.md`) |
| `_handleDrop` nach `disconnect()` | `_manuallyClosed` ist true → nichts tun |
| App kommt in den Vordergrund (`resumed`) | `MessengerController.didChangeAppLifecycleState` → `reconnect()`: wartet einen laufenden Aufbau ab, dann `disconnect()` + `connect()`. Also **immer** frische Verbindung + Nachsync |

Den Close-Code liest `_handleDrop` **bevor** `_channel` genullt wird, danach wäre er weg.

---

## 2. Das Protokoll auf der Leitung

**Verbindung:** `wss://<gateway>/ws/chat?token=<access_token>`. Der Access-Token steht im Query-String, nicht im `Authorization`-Header.

### Client → Server

```json
{ "kind": "dm",    "to": <userId>,  "message": "v1:…", "client_msg_id": "<uuid>" }
{ "kind": "group", "to": <groupId>, "message": "g1:…", "key_version": <epoche>, "client_msg_id": "<uuid>" }
```

### Server → Client (`parseChatEvent`)

| `kind` | Dart-Klasse | Felder | Wer reagiert |
|---|---|---|---|
| `dm` | `IncomingDm` | `sender_id`, `message`, `created_at`, `client_msg_id` | `_persistIncoming` → DB |
| `group` | `InComingGroupChat` | + `group_chat_id`, `key_version` | `_persistIncoming` → DB |
| `ack` | `MessageAck` | `to`, `delivered_live` | `_awaitGroupResponse` (Gruppen-Send) |
| `rekey_required` | `GroupRekeyRequired` | `group_chat_id` | Gruppen-Send → Rekey, nochmal senden |
| `key_outdated` | `GroupKeyOutdated` | `group_chat_id`, `current_version` | Gruppen-Send → Key holen, nochmal senden |
| `error` | `ChatErrorEvent` | `detail` | Gruppen-Send bricht ab |
| unbekannt | `null` | — | ignoriert |

`ChatEvent` ist `sealed`. Ein `switch` darüber braucht kein `default`, ein neuer Event-Typ wird zum Compile-Fehler an jeder Stelle, die ihn vergisst.

### REST-Endpunkte des Messengers

| Endpunkt | Wofür |
|---|---|
| GET `/messages/?since=…` | alle DMs (beide Richtungen), global für alle Partner |
| GET `/messages/group/{id}?since=…` | Verlauf einer Gruppe |
| GET `/group_chat/my` | meine Gruppen (id, Name, Bild) → Discovery |
| GET `/group_chat/{id}/members` | Mitglieder + Rollen (Info-Sheet, Rekey) |
| POST `/group_chat/create`, `/join/{code}`, `/group_chat_join_code/{id}`, `/{id}/transfer/{user}`, `/{id}/picture` | Gruppe anlegen, beitreten, Code, übergeben, Bild |
| PATCH `/group_chat/{id}`, `/{id}/members/{user}/role` | umbenennen, Rolle setzen |
| DELETE `/group_chat/{id}`, `/leave/{id}`, `/kick/{id}/{user}` | löschen, verlassen, rauswerfen |
| `/keys/…` | Schlüssel, siehe `E2EE.md` |

Die Gruppen-Endpunkte sind `static` auf `MessengerApiService`, weil sie keinen Verbindungszustand brauchen. Rollen und Mitgliederwechsel kommen **nicht** per WebSocket. Wer aktuelle Rollen braucht, lädt die Mitgliederliste neu.

---

## 3. Nachsync über REST (`_syncAll`)

### SyncMarker

Tabelle `SyncMarkers` (Key → `lastSyncedAt`). Gemerkt wird das neueste **Server**-`created_at`, das wir pro Quelle gesehen haben:

| Key | Quelle |
|---|---|
| `dm` | ein globaler Marker für **alle** DMs (es gibt nur einen Endpunkt) |
| `group:<id>` | ein Marker pro Gruppe |

Kein Marker = alles holen (z.B. nach frischem Login, die DB wurde ja geleert).

### Ablauf

```
_syncAll()
 1. DMs:  GET /messages/?since=<dm-Marker>
          → entschlüsseln, saveDm, Partner sammeln
          → je Partner OpenChat sicherstellen (Anfrage-Regel, s.u.)
          → dm-Marker = neuestes created_at
 2. Discovery: GET /group_chat/my
          ├─ ok   → je Gruppe _upsertGroupFromServer (Name/Bild angleichen)
          │         → _pruneGroups: lokal bekannt, Server nicht mehr → samt Verlauf löschen
          └─ Fehler (null) → NICHTS löschen (ein Server-Schluckauf darf nicht alles abräumen)
 3. Je Gruppe in OpenChats: GET /messages/group/{id}?since=<group-Marker>
          → entschlüsseln, saveGroupMessage, Marker fortschreiben
```

Ohne Schritt 2 wäre die Gruppenschleife nach einem frischen Login leer. DMs brauchen keine Discovery, ihre Partner stehen direkt in `/messages/`.

`fetchMyGroups` gibt bei Fehler bewusst `null` zurück und **keine** leere Liste. Eine leere Liste würde `_pruneGroups` als „du bist in keiner Gruppe mehr“ lesen.

### Live-Nachrichten und der Marker

`_persistIncoming` schreibt bei jeder Live-Nachricht nur den Marker fort, macht aber **keinen** REST-Call. Sonst würde der nächste Reconnect-Sync alles Live-Empfangene noch einmal holen. Lücken deckt der Sync beim nächsten (Re)connect ab.

---

## 4. Empfangen (`_persistIncoming`)

| Event | Was passiert |
|---|---|
| `IncomingDm` | `_ensureDmOpenChat(sender, pending: true)` → entschlüsseln → `saveDm` → Marker `dm` |
| `InComingGroupChat` | `_ensureGroupOpenChat(id)` (Fallback-Name „Gruppe <id>“, echter Name kommt mit dem nächsten Discovery-Sync) → entschlüsseln → `saveGroupMessage` → Marker `group:<id>` |
| alles andere | nicht speichern, ist nur Feedback für den Sende-Flow |

### Chat-Anfragen (`OpenChats.isPending`)

- **Live:** Entsteht durch eine eingehende DM eine **neue** Chatlisten-Zeile, ist das ein Erstkontakt durch einen Fremden → `isPending = true`. Bestehende Zeilen werden nie umgeflaggt, einmal angenommen bleibt angenommen.
- **Nach Re-Login** (DB leer, der Server kennt kein „angenommen“): Habe ich dem Partner jemals selbst geschrieben → angenommen, sonst Anfrage.
- Selbst gestartete Chats (User-Suche, Gruppen-Beitritt) sind nie pending.
- **Selbst senden nimmt an.** `sendDirectMessage` setzt nach erfolgreichem Versand `isPending = false`. Das gilt zentral für jeden Sendeweg (Chat, Share-Sheet, später Outbox). Bricht der Versand vorher ab (Key fehlt), bleibt die Anfrage offen. Die User-Suche (`_startPrivateChat`) nimmt schon beim **Öffnen** an.

---

## 5. Senden

### DM (`sendDirectMessage`) — fire and forget

```
1. client_msg_id = UUID v4
2. Partner-Pubkey holen (Cache → Server)        fehlt → abbrechen, nichts senden
3. eigenen Secret Key laden                      fehlt → abbrechen (kein Klartext-Fallback!)
4. crypto_box → "v1:…"
5. _channel?.sink.add({kind: dm, …})
6. KLARTEXT lokal speichern (saveDm, created_at = jetzt)
7. offene Anfrage zu diesem Partner annehmen (UPDATE nur wo isPending = true,
   sonst würde die Chatliste bei jeder Nachricht neu bauen)
```

Für DMs wird **nicht** auf ein Ack gewartet.

### Gruppe (`sendGroupMessage`) — mit Antwort-Schleife

```
1. client_msg_id = UUID v4
2. Klartext SOFORT lokal speichern (optimistisch)
3. bis zu 4 Anläufe:
   a. Epoche bestimmen: lokal → vom Server holen → notfalls selbst rekeyen   (keine → aufgeben)
   b. verschlüsseln → "g1:…"
   c. Antwort-Listener scharf schalten (VOR dem Senden, sonst Race), dann senden
   d. Antwort (Timeout 10 s):
        ack             → fertig
        rekey_required  → _performRekey, nochmal
        key_outdated    → aktuellen Key holen, nochmal
        error / Timeout → aufgeben
```

Alle Anläufe nutzen **dieselbe** `client_msg_id`. Kommt die Nachricht doppelt beim Server oder im Sync an, bleibt es trotzdem eine Zeile.

---

## 6. Lokale Daten

| Tabelle | Inhalt |
|---|---|
| `DmChatHistory` | DMs im **Klartext**, `clientMsgId` unique (nullable, alte Nachrichten haben keine) |
| `GroupChatHistory` | Gruppennachrichten im Klartext, `clientMsgId` unique |
| `OpenChats` | Chatliste: `id` (User- bzw. Gruppen-ID), `isGroupChat`, Name, Avatar, `isPending`. **Unique-Index `open_chats_peer` auf `(id, isGroupChat)`** (Schema v12), alle Inserts mit `insertOrIgnore` |
| `SyncMarkers` | `dm` / `group:<id>` → neuestes `created_at` |

- Die DB ist vom Android-/iOS-Auto-Backup ausgeschlossen und wird bei **jedem** Logout und Login komplett geleert (`clearDatabase`).
- `removeGroupLocally` löscht Chat, Verlauf und Marker einer Gruppe in einer Transaktion (Prune, Verlassen, Löschen).
- Die v12-Migration räumt vor dem Index alte Duplikate weg („besserer Zwilling“ bleibt: angenommen vor Anfrage, sonst die ältere Zeile). Nötig, weil Tester-Builds den Race-Bug schon hatten.

---

## Die Regeln, die alles zusammenhalten

1. **Nur der `MessengerController` besitzt den Service.** Screens holen ihn über `context.read<MessengerController>().service`, sie bauen nie selbst eine Verbindung.
2. **Ein Band, ein Abo.** `_events` überlebt alle Reconnects. Wer einen neuen Listener braucht, hängt sich an `incoming` und baut keinen zweiten WebSocket.
3. **Erst Sync, dann Live.** `_doConnect` holt per REST nach und öffnet erst danach den WebSocket. Scheitert der Sync, bleibt der WebSocket zu.
4. **Nie ohne Server-Antwort löschen.** Fehler ≠ leere Liste (`fetchMyGroups`).
5. **Gewollt geschlossen heißt still.** `_manuallyClosed` blockt jeden Auto-Reconnect, und 4003 setzt es ebenfalls.
6. **Speichern nacheinander.** Live-Events gehen nur über `_enqueue` in die DB, nie direkt an `_persistIncoming`.

---

## Bekannte Grenzen & offene Punkte

| # | Punkt | Schwere | Plan |
|---|---|---|---|
| 1 | **DM ohne Verbindung geht still verloren.** `_channel?.sink.add` macht bei `_channel == null` nichts, die Nachricht wird aber lokal gespeichert und sieht gesendet aus. Es gibt keinen Retry und keine Outbox. | mittel | Outbox: Status-Spalte (`pending`/`sent`) + erneut senden nach Connect, DM-Ack auswerten. |
| 2 | Gruppen-Send scheitert (Error, Timeout, kein Key): Die optimistisch gespeicherte Nachricht bleibt stehen, ohne Fehlermarkierung. | mittel | Mit #1 lösen (gleiche Status-Spalte). |
| 3 | Mögliche Lücke beim Connect: Kommt eine Nachricht beim Server an, **nachdem** `_syncAll` fertig ist, aber **bevor** der WebSocket offen ist, wird sie weder live noch per Sync geliefert. Die nächste Live-Nachricht schiebt den Marker darüber hinweg. | niedrig | Prüfen, ob das Gateway beim Connect Verpasstes nachliefert. Falls nicht: Marker nur im REST-Sync fortschreiben oder nach dem WS-Open kurz nachsyncen. |
| 4 | `_awaitGroupResponse` ordnet Antworten nur per Gruppen-ID zu (`ack.to`), nicht per `client_msg_id`. Zwei parallele Sends in dieselbe Gruppe können ihre Acks vertauschen, und ein `error` trifft jeden wartenden Send. | niedrig | Backend: `client_msg_id` in `ack`/`error` zurückgeben, dann darauf filtern. |
| 5 | Der Access-Token steht in der WS-URL (Query-String) und kann so in Server-/Proxy-Logs landen. | bekannt | Hingenommen. Er ist kurzlebig (~30 min). |
| 6 | Bei jedem `resumed` gibt es einen kompletten Reconnect + Sync, auch wenn die Verbindung noch gesund war. | niedrig | Bewusst so: einfach und robust. Optimieren nur bei spürbarer Last. |
| 7 | Rollen, Mitgliederwechsel und Gruppenname kommen nicht per WebSocket, erst mit dem nächsten Sync bzw. beim Öffnen des Info-Sheets. | bekannt | Backend-Wunsch: WS-Events dafür. |
| 8 | Fotos im Chat gibt es noch nicht. | — | Geplant als verschlüsselter Blob-Upload + Pointer-Nachricht (nicht Base64 über WS), wartet auf Backend-Media-Endpoint. |
| 9 | Kein Ungelesen-Marker pro Chat. | — | Später über `lastReadAt`. |

## Glossar

- **WebSocket (WS):** dauerhaft offene Verbindung, über die der Server von sich aus Nachrichten schicken kann.
- **Gateway:** eigener Server-Dienst (`wsUrl`), der die WebSockets hält. Die REST-API läuft getrennt davon (`baseUrl`).
- **Förderband (`_events`):** der Broadcast-Stream, auf den alle Verbindungen nacheinander ihre Events legen.
- **Single-Flight:** Läuft eine Operation schon, bekommen weitere Aufrufer dasselbe Future statt eines zweiten Durchlaufs (`connect`, auch `ApiClient._refreshOnce`).
- **Backoff:** Wartezeit zwischen Reconnect-Versuchen, die sich jedes Mal verdoppelt, damit ein toter Server nicht im Sekundentakt bestürmt wird.
- **Heartbeat / Ping-Pong:** regelmäßiges „bist du noch da?“, um eine still gestorbene Verbindung zu erkennen.
- **SyncMarker:** „bis hierhin habe ich schon alles“, das neueste bekannte `created_at` pro Quelle.
- **`client_msg_id`:** UUID, die der Absender erzeugt. Sie macht Speichern idempotent: dieselbe Nachricht ergibt nie zwei Zeilen.
- **Optimistisch speichern:** Die eigene Nachricht wird sofort angezeigt, noch bevor der Server sie bestätigt hat.
- **Discovery:** „In welchen Gruppen bin ich?“ vom Server holen (`/group_chat/my`), damit der Sync weiß, was er nachholen muss.
- **Prune:** lokal löschen, was es auf dem Server nicht mehr gibt.
- **Persistenz-Kette (`_persistQueue`):** Future-Kette, an die jedes Live-Event hinten angehängt wird, damit sie strikt nacheinander gespeichert werden.
- **Race (Wettlauf):** Zwei Abläufe greifen gleichzeitig auf dieselben Daten zu, das Ergebnis hängt davon ab, wer zuerst fertig ist. Klassiker: beide prüfen „gibt's noch nicht“, beide legen an.

# Impression-Tracker — Übersicht

Nachschlagewerk: Wie das Frontend misst, welche Feed-Posts wirklich gesehen wurden, und wie es das an den Server schickt. Zeilenangaben beziehen sich auf den Stand beim Schreiben und können wandern.

---

## 1. Wozu

Lytir (das Empfehlungsmodell) lernt aus Interaktionen: Likes, Kommentare, Shares. Dabei fehlt ihm die andere Hälfte: **Posts, die der User gesehen, aber nicht angefasst hat.** Das sind die Negativ-Beispiele („hat ihn nicht interessiert“).

Der Tracker liefert genau das: Pro Post, der im Feed sichtbar war, eine Zeile mit

- wie lange er sichtbar war (`dwell_ms`),
- an welcher Position er stand,
- ob der User etwas damit gemacht hat (`voted`, `opened_comments`, `shared`, `reported`).

Ein Post mit `dwell_ms: 8000` und allen Flags `false` = „gesehen, ignoriert“. Ohne Tracker gäbe es diese Zeile nie.

---

## 2. Bausteine und wer was aufruft

```
 posts_feed.dart                         main.dart
 ┌────────────────────────┐              ┌───────────────────────────┐
 │ _fetchData()           │              │ SessionScope              │
 │  └ startFeedSession ───┼──┐           │  └ Provider(ImpressionTracker)
 │ RouteAware             │  │           │      dispose → tracker.dispose()
 │  └ didPush/PopNext ────┼──┤ setGate   │ NavBar onTabSelected      │
 │ AppLifecycleListener ──┼──┤ (route/   │  └ setGate(tab) ──────────┼──┐
 └────────────────────────┘  │ lifecycle)└───────────────────────────┘  │
                             ▼                                           │
 ImpressionWrapper ──onVisible/onHidden──►  ImpressionTracker  ◄─────────┘
 (VisibilityDetector, je Post)              _records / _dirty / Gates
                                                  ▲        │ alle 10 s + bei Pausen
 text_post.dart ── markEngaged(voted, …) ─────────┘        ▼
                                                  POST /impressions/
```

| Baustein | Datei | Aufgabe |
|---|---|---|
| `ImpressionTracker` | `lib/post/impression_tracker.dart:43` | Hält alle Records, Gates, Timer, sendet |
| `ImpressionWrapper` | `lib/post/widgets/impression_wrapper.dart:11` | Umhüllt jeden Feed-Post, meldet sichtbar/unsichtbar |
| `PostsFeed` | `lib/post/posts_feed.dart` | Startet Feed-Sessions, schließt Route- und Lifecycle-Gate |
| `SessionScope` | `lib/main.dart:98` | Erzeugt den Tracker (ein Provider), wirft ihn beim Logout weg |
| Tab-Gate | `lib/main.dart:463` | Feed-Tab (Index 0) offen oder nicht |
| `markEngaged` | `lib/post/widgets/text_post.dart:101, 139, 635, 725` | Meldet Interaktionen |

Der Wrapper wird in `posts_feed.dart:297` um jeden Post gelegt, mit `position: index - 1` (der Index ist um 1 verschoben, weil Index 0 die Story-Row ist).

---

## 3. Lebenszyklus eines Records

Ein `_Record` (`impression_tracker.dart:14`) ist das Aggregat **eines Posts in einer Feed-Session**. `_records` ist eine `Map<postId, _Record>`, es gibt also genau einen pro Post, egal wie oft er rein- und rausscrollt.

1. **Erster Sichtkontakt.** Der `VisibilityDetector` meldet im Wrapper (`impression_wrapper.dart:52`) „mehr als die Hälfte sichtbar“ → `onVisible` (`:80`). `putIfAbsent` legt den Record an und friert `position` und `shownAt` ein, beides gilt für den *ersten* Sichtkontakt.
   - Die Schwelle ist nicht `visibleFraction >= 0.5`, sondern „sichtbare Höhe ≥ 50 % von `min(Posthöhe, Screenhöhe)`“ (`impression_wrapper.dart:57`). Grund: Ein Post mit großem Bild ist höher als der Screen und würde die 0,5 nie erreichen.
   - Der Detector tickt alle 300 ms (`posts_feed.dart:57`).
2. **Stopuhr läuft.** `visibleSince` wird gesetzt (`??=`, damit ein doppelter Callback die laufende Phase nicht zurücksetzt).
3. **Pause / Wegscrollen.** `onHidden` (`:93`) addiert `jetzt - visibleSince` auf `dwellMs` und setzt `visibleSince = null`. Ein Post kann mehrere Sichtphasen haben, `dwellMs` ist die Summe. Auch `dispose()` im Wrapper (`impression_wrapper.dart:42`) ruft `onHidden`, damit die Uhr nicht ewig weiterläuft, wenn der Post aus dem Baum fällt.
4. **Engagement.** `markEngaged` (`:105`) setzt eines der vier Flags. Gibt es keinen Record (Post nie gesehen), passiert nichts: keine erfundene Zeile mit `dwell_ms: 0, voted: true`.
5. **Flush.** Jede Änderung trägt die postId in `_dirty` ein. `flush()` (`:242`) schickt alle dirty Records.
6. **Fertig.** Nach dem Senden fliegt ein Record aus `_dirty`, wenn seine Stopuhr steht **oder** der Cap erreicht ist (`:261`). Läuft die Uhr noch, bleibt er dirty, der nächste Flush schickt den höheren Stand. Aus `_records` verschwindet er erst bei `startFeedSession` (er bleibt also als „schon gesehen“ in der Session).

`reported` ist ein **negatives** Signal („weniger davon“), die anderen drei sind positiv. Deshalb der Warnkommentar bei `_Record.reported`.

Reihenfolge-Falle beim Kommentar-Öffnen: `markEngaged` muss **vor** dem Push stehen (`text_post.dart:134`), weil der Push über `didPushNext` das Route-Gate schließt und das einen Flush auslöst. Käme das Flag danach, ginge es erst im nächsten Flush mit.

---

## 4. Die drei Gates und warum `_pausedIds` nötig ist

Gezählt wird nur, wenn **kein** Gate blockt (`_blockedBy.isEmpty`, `:125`). Drei unabhängige Gründe:

| Gate | Blockt, wenn … | Gesetzt in |
|---|---|---|
| `tab` | ein anderer Tab als der Feed offen ist | `main.dart:463` |
| `route` | etwas über den Feed gepusht wurde (Suche, StoryViewer, Kommentar-Sheet) | `posts_feed.dart:98/102` (`RouteAware`) |
| `lifecycle` | die App im Hintergrund / Bildschirm aus ist | `posts_feed.dart:66` (`AppLifecycleListener`: hide/pause/show) |

`setGate` (`:151`) reagiert nur auf den **echten Wechsel** von aktiv ↔ blockiert. Geht das Kommentar-Sheet zu, während man schon auf einem anderen Tab ist, ändert sich nichts.

**Warum `_pausedIds`?** Die Tabs liegen in einem `IndexedStack`. Der Feed bleibt gemountet, wenn man den Tab wechselt, und der `VisibilityDetector` meldet deshalb **kein** „unsichtbar“. Er meldet bei der Rückkehr auch kein „wieder sichtbar“. Also macht der Tracker beides selbst:

- **Pause:** Alle laufenden Stopuhren per `onHidden` anhalten und ihre IDs in `_pausedIds` merken, dann sofort `flush()` (`:182-187`).
- **Weiter:** Genau diese Posts bekommen `visibleSince = jetzt` und werden wieder `_dirty` (`:161-178`). Das `_dirty` ist wichtig: Beim Pausieren wurde es geleert, und der Detector meldet nichts Neues, sonst würde kein Flush den Post mehr mitnehmen.

`onHidden` räumt die ID auch wieder aus `_pausedIds`, falls der Post während der Pause aus dem Baum fällt.

---

## 5. Senden

`flush()` läuft aus drei Stellen: 10-s-Timer (`:60`), `setGate` bei Pause (`:187`), `startFeedSession` (`:68`). Es ist synchron und **fire-and-forget**: `_post` wird nicht awaited, Fehler (auch Netzfehler) werden nur per `debugPrint` geloggt. Kaputte Telemetrie darf nie einen Like oder Tab-Wechsel verzögern.

**Endpoint:** `POST {baseUrl}/impressions/` über `ApiClient.post` (`:269`).

**Payload** (`_buildPayload`, `:204`):

```json
{
  "feed_session_id": "<uuid v4>",
  "feed_variant": "for_you" | "local",
  "client_sent_at": "<ISO-8601 UTC>",
  "items": [
    {
      "post_id": 123,
      "position": 4,
      "shown_at": "<ISO-8601 UTC, erster Sichtkontakt>",
      "dwell_ms": 8200,
      "voted": false,
      "opened_comments": false,
      "shared": false,
      "reported": false
    }
  ]
}
```

Regeln dahinter:

- **Kumulativ statt Deltas.** Jeder Eintrag enthält die *Gesamt*-`dwell_ms` des Posts, nicht die Zeit seit dem letzten Senden. Ein Post taucht über die Zeit mehrfach auf, der Server überschreibt/aktualisiert pro (`feed_session_id`, `post_id`). Vorteil: Geht ein Request verloren, korrigiert der nächste automatisch, nichts muss gezählt oder nachgeschickt werden.
- **Laufende Uhr zählt mit.** `_dwellNow` (`:195`) rechnet die offene Phase live dazu, auch wenn `onHidden` noch nicht kam.
- **Mindest-Dwell 1 s** (`_minDwellMs`, `:190`): Alles darunter wird nicht gesendet. Schnell durchgescrollte Posts sind kein Signal. Sie bleiben aber dirty und gehen mit, sobald sie die Sekunde knacken.
- **Cap 3 min** (`_maxDwellMs`, `:193`): `min(raw, 180000)`. Fängt vergessene Geräte ab (Desktop, Handy liegt mit offenem Feed da). Ist der Cap erreicht, gilt der Record als fertig (siehe Abschnitt 3), sonst würde er alle 10 s unverändert erneut rausgehen.
- **Nichts zu senden** (`items` leer) → `_buildPayload` liefert `null`, kein Request.
- **Responses ≥ 400** werden nur geloggt (`:276`).

---

## 6. Feed-Sessions

Eine Feed-Session = ein Feed-Load, erkennbar an `_feedSessionId` (UUID v4, `:48`). Der Server kann so „diese 20 Posts wurden gemeinsam ausgeliefert“ rekonstruieren.

**Neue Session** (`startFeedSession`, `:63`, aufgerufen in `posts_feed.dart:193`):
- Initial-Load
- Pull-to-Refresh
- Feed-Wechsel „Für dich“ ↔ „Lokal“ (setzt auch `feed_variant`)

**Keine neue Session** beim Nachladen weiterer Seiten (`_fetchMoreData`): Dieselbe Liste wird nur länger.

Der Aufruf sitzt bewusst **nach** dem erfolgreichen Fetch, direkt vor `provider.setPosts` (`posts_feed.dart:189-195`). Ein fehlgeschlagener Fetch lässt die laufende Session unangetastet.

**Reihenfolge in `startFeedSession`:** `flush()` zuerst, danach `_records`, `_dirty`, `_pausedIds` leeren, dann neue ID. `_buildPayload` stempelt die *aktuelle* ID in den Body. Würde die ID vorher gewechselt, landeten die letzten bis zu 10 s im falschen Bucket oder gingen verloren.

---

## 7. Logout / SessionScope

Der Tracker hängt als `ProxyProvider(create:, update:, dispose:)` im `SessionScope` (`main.dart:107-116`). Beim Logout ändert sich `_sessionId`, der Scope baut sich komplett neu auf (siehe Memory „Session Provider Reset“), der alte Tracker bekommt `dispose()` (`impression_tracker.dart:285`), ein neuer entsteht leer.

Folge: Impressions von User A können nie in der Session von User B landen. `dispose()` stoppt nur den Timer und flusht **bewusst nicht**: Beim Logout sind die Tokens schon weg, der Request käme als 401 zurück.

---

## 8. Einwilligung (`impressions_enabled`)

**Backend-Vertrag:**
- Opt-in, Default `false`. Kommt mit `GET /users/`, gesetzt per `PUT /users/ {"impressions_enabled": bool}`.
- Ist es aus, antwortet `POST /impressions/` mit **204** und speichert nichts.
- `PUT` mit `false` löscht serverseitig alle bisherigen Impressions des Users.

**Tracker** (`impression_tracker.dart`):
- `_enabled` startet `false`: Solange das Profil nicht geladen ist, ist die Einwilligung unbekannt, und bei einem Opt-in heißt „unbekannt“ „nein“.
- `onVisible` und `flush` brechen ab, solange `_enabled` falsch ist.
- `setEnabled(false)` verwirft `_records`, `_dirty`, `_pausedIds` **ohne Flush**. Der Server löscht ohnehin alles, Nachschicken wäre genau das, was der User abgelehnt hat.

**Kopplung** (`main.dart`, SessionScope): `ProxyProvider<ProfileProvider, ImpressionTracker>`. Bei jedem `notifyListeners()` des ProfileProviders läuft `setEnabled(userdata['impressions_enabled'] == true)` auf **demselben** Tracker-Objekt. Weil das sehr oft passiert, macht `setEnabled` bei gleichem Wert sofort `return`.

**Schalter** (`settings_screen.dart`, Block „Daten & Personalisierung“):
- Einschalten: kein Dialog, keine Hervorhebung (kein Dark Pattern). PUT, erst bei Erfolg `setUserField(true)`.
- Ausschalten: Bestätigungsdialog („Daten werden gelöscht“), dann **erst lokal** `setUserField(false)` (Tracker stoppt sofort), **danach** PUT. Umgekehrt könnte der 10-s-Timer zwischen PUT und Antwort noch Daten nachschieben.
- Schlägt der PUT fehl, wird auf den alten Wert zurückgesetzt + Snackbar.
- Ob der PUT geklappt hat, entscheidet `updated_fields` in der Antwort (`UserApiService.setPrivacyFlag`): Fehlt der Key, gilt es als Fehler (z. B. Backend noch ohne das Feld).

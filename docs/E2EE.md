# E2EE im Messenger — Übersicht

Stand: 26.09.2026 (Key-Backup Schritt 3a). Nachschlagewerk: Was gibt es, wozu, wo liegt es.

## Das Grundprinzip in einem Bild

Alles hängt an **einem** Schlüssel pro User. Die übrigen Teile benutzen, retten oder bewachen ihn.

```
            ┌──────────────────────────────────┐
            │   IDENTITY-KEYPAIR (pro User)    │
            │   priv: nur auf dem Handy        │  flutter_secure_storage
            │   pub:  auf dem Server           │  (Keystore / Keychain)
            └────────────────┬─────────────────┘
      ┌──────────────────────┼──────────────────────┐
      ▼                      ▼                      ▼
  1. DMs                 2. Gruppen              3. Backup
  benutzt den Key        benutzt den Key         rettet den Key
  crypto_box             Epochen-Key (secretBox) priv+pub mit Passwort
  mein priv +            pro Mitglied an dessen  verschlüsselt auf dem
  Partner-pub            pub versiegelt          Server → neues Handy
                                                 bekommt DENSELBEN Key
```

**Merksatz:** Wer den Private Key hat, kann alle DMs und alle Gruppen-Keys lesen.
Deshalb gilt:
- Der Private Key verlässt das Handy nie im Klartext.
- Der Server darf ihn nie benutzbar haben. Er bekommt nur den verschlüsselten Backup-Blob.
- Ein **neuer** Private Key heißt: alte Nachrichten sind weg. Er entsteht deshalb nur an zwei Stellen (siehe 3.).

Alle Krypto-Funktionen kommen aus libsodium (Paket `sodium`). Argon2 gibt es nur über `SodiumSumoInit`, nativ ist das dieselbe Bibliothek.

---

## 0. Identity-Keypair

| Was | Wo |
|---|---|
| Speichern / Laden / Löschen | `lib/key_service.dart`: `ensureKeypair`, `getSecretKey`, `hasLocalKeypair`, `loadLocalPublicKey`, `storeKeypair`, `deleteKeypair` |
| Pubkey hoch / runter | `uploadPublicKey` (PUT `/keys/`), `fetchPartnerPublicKey`, `fetchOwnPublicKey` (GET `/keys/{id}`) |
| Storage-Keys | `e2ee_priv_<userId>`, `e2ee_pub_<userId>` |

- Das Keypair **überlebt den Logout**, weil es pro userId gespeichert ist. Gelöscht wird es nur beim Löschen des Accounts (`settings_screen.dart`).
- Der Private Key wird im RAM gecacht (`_secretKeyCache`), damit nicht jede Nachricht den teuren Keystore-Zugriff braucht.
- Vom Android-/iOS-Auto-Backup ist es ausgeschlossen.

---

## 1. DMs

| Was | Wo |
|---|---|
| Verschlüsseln + senden | `messenger_api_service.send.dart` → `sendDirectMessage` |
| Entschlüsseln | `messenger_api_service.crypto.dart` → `_decryptDm` |
| Aufrufer beim Empfangen | `messenger_api_service.sync.dart` (live + History-Sync) |

- `crypto_box(Nachricht, nonce, Partner-pub, mein priv)`
- Format auf der Leitung: `v1:` + Base64(nonce ‖ Ciphertext). Nachrichten ohne `v1:` sind alte Klartext-Nachrichten und werden unverändert angezeigt.
- **Lokal (Drift-DB) liegt der Klartext**, nie der Ciphertext. Die DB ist vom Auto-Backup ausgeschlossen und wird beim Logout geleert.
- Partner-Pubkeys werden im RAM gecacht (`_partnerPubKeyCache`, lebt eine App-Session lang).

---

## 2. Gruppen

| Was | Wo |
|---|---|
| Senden inkl. Epochen-Logik | `messenger_api_service.send.dart` → `sendGroupMessage` |
| Ver-/Entschlüsseln, Rekey | `messenger_api_service.crypto.dart` → `_encryptGroup`, `_decryptGroup`, `_ensureGroupKey`, `_fetchAndStoreCurrentKey`, `_performRekey` |
| Gruppen-Keys speichern, versiegeln | `key_service.dart` → `saveGroupKey`, `getGroupKey`, `generateGroupKey`, `sealGroupKeyFor`, `openSealedGroupKey` |
| REST | POST `/keys/group/{id}/rekey`, GET `/keys/group/{id}/key` (aktuell), GET `/keys/group/{id}/keys` (alle meine) |

**Idee:** Eine Gruppe hat pro **Epoche** einen zufälligen symmetrischen Key. Wer eine neue Epoche startet (Rekey), versiegelt diesen Key für **jedes** Mitglied mit dessen Pubkey (Sealed Box) und lädt alle Pakete hoch. Jedes Mitglied öffnet sein Paket mit dem eigenen Private Key.

- Format auf der Leitung: `g1:` + Base64(nonce ‖ Ciphertext), dazu `key_version` = Epoche.
- **Neue Epoche** bei Mitgliederwechsel. Der Server meldet `rekey_required`, der nächste Sender führt den Rekey aus. `409` heißt, die Mitgliederliste hat sich geändert: neu laden und nochmal versuchen (bis 3×).
- `key_outdated`: Der Absender hatte eine alte Epoche, holt die aktuelle und sendet erneut (bis 4 Anläufe).
- Neues Mitglied: bekommt nur Keys ab seiner Epoche und kann ältere Nachrichten nicht lesen. Das ist gewollt.
- Neues Gerät: `fetchAllGroupKeys` holt alle meine Pakete. Die lassen sich mit dem (wiederhergestellten) Identity-Key öffnen, die History ist also wieder lesbar.
- Storage-Keys: `e2ee_gkey_<gruppe>_<epoche>`, Zeiger auf die aktuelle Epoche: `e2ee_gkey_cur_<gruppe>`.

---

## 3. Key-Backup

| Was | Wo |
|---|---|
| Datenklassen | `lib/key_backup.dart` → `BackupSecretType`, `KeyBackup`, `UnwrapResult`, `FetchBackupResult` |
| Krypto + REST | `key_service.dart` → `wrapKeyBackup`, `unwrapKeyBackup`, `uploadBackup`, `fetchBackup` |
| Ablauf beim Login | `lib/key_setup.dart` → `afterLogin`, `afterRegistration`, `retryWithPassword`, `startFresh` |
| Login-Einbau + Dialoge | `lib/login_screen.dart` → `_handleLogin`, `_resolveKeySetup`; `lib/key_restore_dialogs.dart` |
| Registrierung | `onboarding/onboarding_flow.dart` → `_handleNextStep` ruft `afterRegistration` best-effort vor dem Home-Wechsel (scheitert es, holt der nächste Login alles nach) |
| Abgleich zur Laufzeit | `messenger_controller.dart` → `_checkOwnPublicKey` (veraltet → Logout + Hinweis über `KeySetup.setLogoutNotice`) |
| Tests | `test/key_backup_test.dart` |
| REST | PUT / GET / DELETE `/keys/backup` |

**Verpacken:** `Argon2id(Passwort, Salt)` ergibt den KEK, damit wird `secretBox(priv ‖ pub)` verschlüsselt. Der Server speichert salt, nonce, ciphertext, opslimit, memlimit und `secret_type`. Argon2 läuft im Isolate (~1 s).

**Ablauf beim Login (`afterLogin`):**
```
Server-Pubkey holen (Fehler → error)
Lokaler Key da?
 ├─ Server leer oder gleich → ggf. Backup nachholen → ready
 └─ Server anders → lokaler Key veraltet → löschen, weiter unten
Backup holen:
 ├─ found → entpacken, Pubkey muss zum Server passen → ready
 │           falsches Passwort → needsPassword (Dialog)
 ├─ none + Server hat Pubkey → noRecovery (nur „Chats zurücksetzen“)
 ├─ none + Server leer → erstes Gerät, neu anlegen → ready
 └─ Fehler / 429 → error (Login abbrechen, KEIN neuer Key)
```

**Die drei Regeln, die alles zusammenhalten:**
1. **Nur `KeySetup` erzeugt Keys.** Nur dort liegt das Passwort vor. Der MessengerController lädt und vergleicht nur.
2. **Der eigene Pubkey auf dem Server ist die aktuelle Schlüssel-Generation.** Ein vorhandener Server-Pubkey wird **nie still überschrieben**. Das passiert nur beim allerersten Key (Server 404) oder bei `startFresh` nach Bestätigung durch den User.
3. **Im Zweifel abbrechen, nie neu erzeugen.** Netzwerkfehler ≠ 404.

**`startFresh` = Notausgang** („Chats zurücksetzen“), für Passwort-Reset, vergessenes Backup-Passwort oder ein kaputtes Backup. Ohne ihn wäre der User ausgesperrt. Andere Geräte merken den Wechsel am Pubkey-Vergleich und melden sich neu an.

Reihenfolge in `_createFresh`: **erst Backup, dann Pubkey**. Scheitert das Backup, bleibt der alte Pubkey stehen.

---

## Bekannte Grenzen & offene Punkte

| # | Punkt | Schwere | Plan |
|---|---|---|---|
| 1 | ~~`sendDirectMessage` sendete Klartext, wenn der eigene Private Key fehlt.~~ | — | **Behoben (3b):** Versand wird blockiert. |
| 2 | Kein Hinweis bei Schlüsselwechsel eines Partners. Wer das Passwort hat (oder ein böswilliger Server), kann einen neuen Key unterschieben. | mittel | TOFU: Partner-Pubkey lokal merken, bei Änderung Systemhinweis im Chat. Direkt nach dem Backup. |
| 3 | Partner-Pubkey-Cache wird innerhalb einer Session nie invalidiert. Nach `startFresh` eines Partners wird bis zum App-Neustart an den alten Key verschlüsselt. | mittel | Wird mit #2 gelöst. |
| 4 | Nach `startFresh` eines Partners: Seine **alten** DMs sind auf einem neuen Gerät nicht mehr lesbar (Entschlüsseln nutzt seinen aktuellen Pubkey). Bestehende Geräte haben den Klartext lokal. | niedrig | Hinnehmen (so ist E2EE). |
| 5 | Variante `login_password`: Der Server sieht beim Login das Passwort. Das Backup schützt also gegen ein DB-Leak, nicht gegen einen böswilligen Server. | bekannt | Später optionales eigenes Backup-Passwort (`custom`) in den Settings. |
| 6 | Keine Forward Secrecy (statische Keys, kein Double Ratchet). Ein geleakter Private Key öffnet alle alten Nachrichten. | bekannt | Bewusst nicht geplant, zu komplex für den Nutzen. |
| 7 | Gruppen: Der Epochen-Key ist geteilt, der Absender ist nicht kryptografisch signiert. Mitglieder (und der Server über `sender_id`) könnten sich als jemand anders ausgeben. | bekannt | Bewusst nicht geplant. |
| 8 | Passwort ändern → Backup neu verpacken | — | Schritt 4 |

## Glossar

- **Keypair:** Private Key (geheim) + Public Key (öffentlich). Was mit dem Public Key verschlüsselt wird, öffnet nur der Private Key.
- **crypto_box:** Verschlüsselung zwischen zwei Keypairs (DMs).
- **secretBox:** Verschlüsselung mit einem gemeinsamen symmetrischen Key (Gruppen, Backup).
- **Sealed Box:** anonym an einen Public Key verschlüsseln. Damit werden Gruppen-Keys verteilt.
- **Nonce:** Zufallswert pro Verschlüsselung, liegt offen neben dem Ciphertext.
- **MAC:** Prüfsumme im Ciphertext. Schlägt sie fehl, war der Key falsch oder die Daten wurden verändert.
- **Epoche:** Version des Gruppen-Keys. Eine neue gibt es bei jedem Mitgliederwechsel.
- **Argon2id / KEK:** macht aus einem Passwort langsam einen Schlüssel (Key Encryption Key), damit Durchprobieren teuer wird.
- **TOFU:** Trust On First Use. Den ersten gesehenen Key eines Partners merken und bei Änderung warnen.

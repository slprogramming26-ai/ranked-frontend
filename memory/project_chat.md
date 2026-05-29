---
name: project-chat
description: Ranked app has a FastAPI WebSocket chat backend and a Flutter frontend that's being built; backend lives outside this repo
metadata:
  type: project
---

Chat-System für die Ranked App.

**Backend (extern, Python/FastAPI):**
- WebSocket auf `/ws/chat?token=<jwt>`
- Empfängt vom Client: `{"to": <user_id>, "message": "..."}`
- Schickt an Empfänger live: `{"sender_id": ..., "message": "...", "created_at": "..."}`
- Schickt dem Sender ein ACK: `{"to": ..., "delivered": true|false}`
- Fehler: `{"type": "error", "detail": [...]}`
- `flush_pending` schickt beim Connect alle in der DB geparkten Nachrichten und löscht sie dort
- Wichtig: das Backend echoed *nicht* eigene Sendungen zurück an den Sender

**Frontend (dieses Repo):**
- `lib/messenger_api_service.dart` — WebSocket-Wrapper
- `lib/chat_screen.dart` — UI
- `lib/local_data/` — drift DB mit `MessageHistory`-Tabelle für lokales Persistieren
- Hosted unter `wss://web-production-1bb6f.up.railway.app`

**Why:** Eigenes Backend wegen voller Kontrolle über Schema/Auth.
**How to apply:** Bei Frontend-Arbeit immer dran denken: eigene Nachrichten muss der Client selbst in die lokale Liste & DB schreiben, nicht warten dass sie zurückkommen.

**Zukunftspläne (User-Aussage 2026-05-24):**
- Leaderboard NICHT mit WebSocket — User hat verstanden dass Push für seltene/vorhersehbare Updates Overkill ist; nutzt stattdessen Refresh-on-Action oder Polling.
- Gruppenchat ist als nächstes echtes WebSocket-Projekt angedacht — gleiches Pattern wie 1:1-Chat, plus Räume + Sender-Info pro Nachricht + komplexere Read-Receipts.
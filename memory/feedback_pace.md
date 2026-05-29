---
name: feedback-pace
description: For learning sessions, deliver ONE small building block at a time and wait for an explicit "verstanden" before the next step — no big code dumps, no multi-feature responses.
metadata:
  type: feedback
---

Bei Lern-Sessions (besonders Messenger/WebSocket-Arbeit): **immer nur einen winzigen Baustein pro Antwort**, dann eine kurze Erklärung (Zeile-für-Zeile / *warum* statt nur *was*), und am Ende die Aufforderung: "Sag verstanden, dann kommt der nächste Schritt."

**Why:** User hat explizit gesagt dass er beim letzten Mal (großer kompletter `MessengerApiService` auf einmal) "gar nichts gecheckt" hat und deshalb von vorne anfangen wollte. Lange Code-Blöcke + lange Erklärtexte überfordern ihn, auch wenn der Inhalt korrekt ist.

**How to apply:**
- Eine Methode / ein Konzept pro Antwort. Nicht "hier ist die ganze Klasse".
- Erst Mini-Code-Diff, dann kurze Erklärung was passiert und *warum* (nicht nur *was*).
- Auf "verstanden" warten. Nicht selbst entscheiden weiterzumachen.
- Wenn er selbst etwas ergänzt (siehe [[project-chat]] — er hat `sendGroupMessage` analog zu `sendDirectMessage` selbst gebaut): kurz bestätigen, nicht groß loben, weitermachen.
- Gilt nicht für reine Routine-Fragen ("was macht Uri.parse") — da reicht eine kompakte Erklärung ohne Code.
import 'dart:math';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:ranked/api_client.dart';
import 'package:uuid/uuid.dart';

/// Die drei unabhaengigen Gruende, aus denen der Feed gerade nicht gezaehlt
/// wird. Gezaehlt wird nur, wenn KEINER davon blockt.
enum ImpressionGate { tab, route, lifecycle }

enum ImpressionEngagement { voted, openedComments, shared, reported }

class _Record {
  _Record({required this.position, required this.shownAt});

  /// Position im Feed beim ERSTEN Sichtkontakt (0-basiert).
  final int position;

  /// wan ist der post zuerst sichtbar
  final DateTime shownAt;

  /// gesamte summer der sichtphasen
  int dwellMs = 0;

  /// startzeit der laufenden phase; null = nicht sichtbar
  DateTime? visibleSince;

  bool voted = false;
  bool openedComments = false;
  bool shared = false;

  /// ACHTUNG, anders als die drei darueber: negatives Signal. Ein Report heisst
  /// "weniger davon", nicht "mehr davon".
  bool reported = false;
}

/// Sammelt, welche Posts im Feed wirklich gesehen wurden — die
/// Negativ-Beispiele, die Lytir zum Lernen fehlen.
///
/// Lebt im SessionScope (main.dart): beim Logout wird er mit weggeworfen,
/// damit nie Impressions von User A in der Session von User B landen.
class ImpressionTracker {
  static const _uuid = Uuid();

  /// Ein Feed-Load = eine Session. Neu bei Initial-Load, Pull-to-Refresh und
  /// Feed-Wechsel — NICHT beim Nachladen weiterer Seiten.
  String _feedSessionId = _uuid.v4();
  bool _isLocalFeed = false;

  /// postId -> Aggregat. Genau EIN Record pro Post und Feed-Session.
  final Map<int, _Record> _records = {};

  /// Records, die sich seit dem letzten Senden geaendert haben.
  final Set<int> _dirty = {};
  static const _flushInterval = Duration(seconds: 10);
  Timer? _flushTimer;

  ImpressionTracker() {
    _flushTimer = Timer.periodic(_flushInterval, (_) => flush());
  }

  void startFeedSession({required bool isLocal}) {
    // Muss VOR dem Neusetzen von _feedSessionId laufen: _buildPayload stempelt
    // die aktuelle Session-ID in den Body. Danach ist der Stand raus und die
    // Records duerfen weg — sonst verliert jeder Pull-to-Refresh die letzten
    // bis zu 10 Sekunden.
    flush();
    _records.clear();
    _dirty.clear();
    // Muss mit: sonst zeigen die IDs auf Records, die es nicht mehr gibt. Der
    // null-Guard in setGate faengt das zwar ab, aber stehen lassen heisst nur,
    // sich auf ihn zu verlassen.
    _pausedIds.clear();
    _feedSessionId = _uuid.v4();
    _isLocalFeed = isLocal;
  }

  // Post hat die Sichtbarkeitsschwelle von oben erreicht.
  void onVisible(int postId, int position) {
    if (!_active) return;
    final record = _records.putIfAbsent(
      postId,
      () => _Record(position: position, shownAt: DateTime.timestamp()),
    );
    // ??= statt =: laeuft die Stopuhr schon, war das ein doppelter Callback.
    // Neu setzen wuerde die bereits gelaufene Zeit dieser Phase wegwerfen.
    record.visibleSince ??= DateTime.timestamp();
    _dirty.add(postId);
  }

  /// Post ist unter die Schwelle gerutscht.
  void onHidden(int postId) {
    final record = _records[postId];
    final since = record?.visibleSince;
    if (record == null || since == null) return; // Stopuhr stand schon
    record.dwellMs += DateTime.timestamp().difference(since).inMilliseconds;
    record.visibleSince = null;
    _pausedIds.remove(postId);
    _dirty.add(postId);
  }

  /// Fire-and-forget aus der UI: darf NIE werfen und nie awaited werden —
  /// kaputte Telemetrie darf keinen Like verhindern.
  void markEngaged(int postId, ImpressionEngagement kind) {
    final record = _records[postId];
    // Kein Record = kein Sichtkontakt in dieser Feed-Session. Dann hier auch
    // keine Impression erfinden: eine Zeile mit dwell_ms 0 und voted: true
    // waere fuer das Modell ein Widerspruch.
    if (record == null) return;

    switch (kind) {
      case ImpressionEngagement.voted:
        record.voted = true;
      case ImpressionEngagement.openedComments:
        record.openedComments = true;
      case ImpressionEngagement.shared:
        record.shared = true;
      case ImpressionEngagement.reported:
        record.reported = true;
    }
    _dirty.add(postId);
  }

  final Set<ImpressionGate> _blockedBy = {};
  bool get _active => _blockedBy.isEmpty;

  // posts deren stoppuhr beim pausieren wechsel lief.
  final Set<int> _pausedIds = {};

  void setGate(ImpressionGate gate, {required bool open}) {
    final wasActive = _active;
    if (open) {
      _blockedBy.remove(gate);
    } else {
      _blockedBy.add(gate);
    }
    // Nur der echte Wechsel zaehlt. Geht das Kommentar-Sheet zu, waehrend der
    // User laengst auf einem anderen Tab ist, bleibt alles stehen.
    if (_active == wasActive) return;
    if (_active) {
      // Weiter: genau die Stopuhren neu starten, die wir angehalten haben.
      // Auf den VisibilityDetector koennen wir uns hier NICHT verlassen — er
      // hat beim Weggehen nie "unsichtbar" gemeldet (IndexedStack laesst den
      // Feed gemountet) und meldet darum auch keine Rueckkehr.
      final now = DateTime.timestamp();
      for (final postId in _pausedIds) {
        final record = _records[postId];
        if (record == null) continue;
        record.visibleSince = now;
        // Ohne das laeuft die Stopuhr zwar wieder, aber kein Flush nimmt den
        // Post mehr mit: _dirty wurde beim Pausieren geleert, und der
        // VisibilityDetector meldet nichts Neues — unter dem Kommentar-Sheet
        // war der Post nie unsichtbar.
        _dirty.add(postId);
      }
      _pausedIds.clear();
      return;
    }
    // Pause: laufende Stopuhren einfrieren, sonst zaehlt die Zeit im anderen
    // Tab als Dwell.
    for (final entry in _records.entries) {
      if (entry.value.visibleSince == null) continue;
      onHidden(entry.key);
      _pausedIds.add(entry.key);
    }
    flush();
  }

  static const _minDwellMs = 1000;

  //desktop stunden lan geöffnet (irrelevant)
  static const _maxDwellMs = 3 * 60 * 1000;

  int _dwellNow(_Record record) {
    final since = record.visibleSince;
    final raw = since == null
        ? record.dwellMs
        : record.dwellMs +
              DateTime.timestamp().difference(since).inMilliseconds;
    return min(raw, _maxDwellMs);
  }

  ({Map<String, dynamic> body, Set<int> sendIds})? _buildPayload() {
    final items = <Map<String, dynamic>>[];
    final sendIds = <int>{};

    for (final postId in _dirty) {
      final record = _records[postId];
      if (record == null) continue;

      final dwellMs = _dwellNow(record);
      if (dwellMs < _minDwellMs) continue;

      sendIds.add(postId);
      items.add({
        'post_id': postId,
        'position': record.position,
        'shown_at': record.shownAt.toIso8601String(),
        'dwell_ms': dwellMs,
        'voted': record.voted,
        'opened_comments': record.openedComments,
        'shared': record.shared,
        'reported': record.reported
      });
    }
    if (items.isEmpty) return null;

    return (
      body: {
        'feed_session_id': _feedSessionId,
        'feed_variant': _isLocalFeed ? 'local' : 'for_you',
        'client_sent_at': DateTime.timestamp().toIso8601String(),
        'items': items,
      },
      sendIds: sendIds,
    );
  }

  /// Schickt den aktuellen kumulativen Stand raus. Fire-and-forget:
  /// darf nie werfen und nie den Aufrufer warten lassen.
  void flush() {
    final payload = _buildPayload();
    if (payload == null) return;

    // Bewusst kein await: flush() muss synchron bleiben. Es wird aus setGate(),
    // dem 10-s-Timer und dispose() gerufen — keiner davon darf auf ein
    // Netzwerk-Ergebnis warten, nur damit der Tab-Wechsel fluessig bleibt.
    _post(payload.body);

    // Gesendete Posts sind sauber - ausser die Stopuhr laeuft noch: deren
    // dwell_ms waechst weiter, der naechste Flush muss sie wieder mitnehmen.
    // Fertig ist ein Record, wenn die Stopuhr steht ODER der Cap erreicht ist —
    // in beiden Faellen kann dwell_ms sich nicht mehr aendern. Ohne den zweiten
    // Fall bliebe ein gedeckelter Post fuer immer dirty und ginge alle 10 s
    // unveraendert erneut raus.
    for (final postId in payload.sendIds) {
      final record = _records[postId];
      if (record == null) continue;
      if (record.visibleSince == null || _dwellNow(record) >= _maxDwellMs) {
        _dirty.remove(postId);
      }
    }
  }
  
  Future<void> _post(Map<String,dynamic> body) async {
    try {
      final response = await ApiClient.post(
        Uri.parse('${ApiClient.baseUrl}/impressions/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );
      // Solange der Endpoint noch nicht existiert, ist das hier der 404 — bis
      // dahin die einzige Rueckmeldung, dass ueberhaupt etwas rausgeht.
      if (response.statusCode >= 400) {
        debugPrint('IMPRESSIONS ${response.statusCode} $body');
      }
    }
    catch (e) {
      debugPrint('IMPRESSIONS failed: $e');
    }
  }

  void dispose() {
    _flushTimer?.cancel();
    _flushTimer = null;
    // Bewusst KEIN flush(): dispose() laeuft praktisch nur beim Logout, und da
    // sind die Tokens schon weg. .
  }
}

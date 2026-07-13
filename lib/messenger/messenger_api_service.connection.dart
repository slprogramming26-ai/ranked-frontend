// =============================================================================
//  Verbindung: Aufbau, Heartbeat, Auto-Reconnect, Abbau
// =============================================================================
part of 'messenger_api_service.dart';

// dart:io schickt alle _pingInterval automatisch ein Ping. Bleibt das Pong
// aus, gilt die Verbindung als tot und wird geschlossen (-> onDone/onError).
const _pingInterval = Duration(seconds: 20);
// Auto-Reconnect-Backoff waechst 1,2,4,8,16s und wird hier gedeckelt.
const _maxBackoff = Duration(seconds: 30);

extension MessengerConnection on MessengerApiService {
  bool get isConnected => _channel != null;

  // Der STABILE Stream, auf den die UI hoert. Bleibt ueber alle Reconnects
  // hinweg derselbe — die UI muss nie neu abonnieren.
  Stream<ChatEvent> get incoming => _events.stream;

  /// Baut die Verbindung auf — Single-Flight: Es laeuft immer hoechstens EIN
  /// Aufbau. Kommt waehrend eines laufenden Aufbaus ein zweiter connect()-
  /// Aufruf (z.B. Login-Init + Resume-Reconnect gleichzeitig), bekommt er
  /// dasselbe Future zurueck und wartet einfach mit, statt einen zweiten
  /// WebSocket zu oeffnen.
  Future<void> connect() {
    if (_channel != null) {
      return Future.value(); // schon verbunden -> nichts zu tun
    }
    // ??= startet nur dann einen NEUEN Aufbau, wenn keiner unterwegs ist.
    // whenComplete raeumt das Feld hinterher wieder ab (auch bei Fehler),
    // damit ein spaeterer connect() wieder frisch starten kann.
    return _connectFuture ??=
        _doConnect().whenComplete(() => _connectFuture = null);
  }

  /// Der eigentliche Aufbau. Holt zuerst per REST alles Verpasste nach
  /// (_syncAll), oeffnet dann den WebSocket und leitet eingehende Nachrichten
  /// auf das dauerhafte _events-Band. Nie direkt aufrufen — nur ueber
  /// connect(), das haelt die Single-Flight-Garantie ein.
  Future<void> _doConnect() async {
    _manuallyClosed = false;

    await _syncAll();
    if (_manuallyClosed) return; // waehrend des Syncs kam ein disconnect()

    final token = await TokenStorage.getToken();
    if (_manuallyClosed) return; // disconnect() kam waehrend des Token-Reads
    final uri = Uri.parse('$_baseWsUrl/ws/chat?token=$token');
    // IOWebSocketChannel (statt WebSocketChannel) erlaubt pingInterval — den
    // automatischen Heartbeat, der einen stillen Verbindungstod erkennt.
    _channel = IOWebSocketChannel.connect(uri, pingInterval: _pingInterval);

    // Diese Verbindung hoert auf rohe Nachrichten, parst sie und kippt das
    // Ergebnis auf das dauerhafte _events-Band. Das Band selbst bleibt bestehen,
    // egal wie oft wir hier neu verbinden.
    _channelSub = _channel!.stream.listen(
      (raw) {
        _reconnectAttempts = 0; // wir empfangen -> Verbindung ist gesund
        final event = parseChatEvent(
          jsonDecode(raw as String) as Map<String, dynamic>,
        );
        if (event != null) _events.add(event);
      },
      onDone: _handleDrop, // Verbindung sauber geschlossen (z.B. nach Ping-Timeout)
      onError: (_) => _handleDrop(), // Netzwerkfehler
      cancelOnError: true,
    );
  }

  /// Erzwingt sofort eine frische Verbindung (z.B. bei Rueckkehr aus dem
  /// Hintergrund): sauber schliessen, dann neu verbinden. connect() zieht dabei
  /// _syncAll() mit, holt also alles nach, was verpasst wurde.
  Future<void> reconnect() async {
    // Laeuft gerade noch ein Aufbau, erst dessen Ende abwarten: disconnect()
    // wuerde ihn zwar abbrechen (_manuallyClosed), aber unser connect() unten
    // wuerde sich per Single-Flight an genau diesen abgebrochenen Aufbau
    // haengen — und danach waere gar keine Verbindung offen.
    final inFlight = _connectFuture;
    if (inFlight != null) await inFlight;
    disconnect();
    await connect();
  }

  /// Gewolltes Schliessen. Setzt das Flag, damit ein nachfolgendes Schliessen
  /// KEINEN Auto-Reconnect ausloest, und bricht einen geplanten Reconnect ab.
  void disconnect() {
    _manuallyClosed = true;
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    // Nur die aktuelle Verbindung schliessen. Das dauerhafte _events-Band
    // bleibt offen, damit ein spaeteres reconnect() denselben Stream weiterfuehrt.
    _channelSub?.cancel();
    _channelSub = null;
    _channel?.sink.close();
    _channel = null;
  }

  /// Endgueltiges Aufraeumen, wenn der Service nicht mehr gebraucht wird.
  /// Schliesst zusaetzlich das _events-Band (anders als disconnect()).
  void dispose() {
    disconnect();
    _events.close();
  }

  // Verbindung ist (ungewollt) abgerissen: aufraeumen und — sofern wir nicht
  // selbst geschlossen haben — einen Reconnect einplanen.
  void _handleDrop() {
    _channelSub?.cancel();
    _channelSub = null;
    _channel = null;
    if (_manuallyClosed) return; // gewolltes Schliessen -> nichts tun
    _scheduleReconnect();
  }

  // Plant einen Reconnect-Versuch mit Exponential Backoff (1,2,4,8,16s, max 30s).
  void _scheduleReconnect() {
    if (_reconnectTimer != null) return; // es ist schon einer unterwegs
    final secs = min(_maxBackoff.inSeconds, 1 << _reconnectAttempts);
    if (_reconnectAttempts < 5) _reconnectAttempts++; // deckeln, kein Overflow
    _reconnectTimer = Timer(Duration(seconds: secs), () async {
      _reconnectTimer = null;
      if (_manuallyClosed || _channel != null) return;
      await connect(); // zieht _syncAll() mit -> Verpasstes wird nachgeholt
    });
  }
}
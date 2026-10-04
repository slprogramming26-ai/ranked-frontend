// =============================================================================
//  MessengerController — app-weiter Besitzer des MessengerApiService
// =============================================================================
//  Vorher lebte der Service im State des Messenger-Screens: Verbindung entstand
//  erst beim Oeffnen des Messengers und starb beim Verlassen. Jetzt besitzt
//  DIESER Controller den Service fuer die ganze Login-Session, damit auch
//  andere Screens (z.B. das Share-Sheet im Feed) senden koennen.
//
//  Lebenszyklus:
//    * init(db, userId)  -> beim Login / Session-Restore aufrufen
//    * shutdown()        -> beim Logout aufrufen
//  init() ist idempotent: doppelter Aufruf fuer denselben User ist ein No-Op.
// =============================================================================

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:ranked/local_data/database.dart';
import 'messenger_api_service.dart';
import '../api_client.dart';
import '../key_service.dart';
import '../key_setup.dart';

class MessengerController extends ChangeNotifier with WidgetsBindingObserver {
  MessengerApiService? _service;
  StreamSubscription<ChatEvent>? _subscription;
  int? _userId;

  /// Der laufende Service — null, solange kein User eingeloggt ist.
  MessengerApiService? get service => _service;
  int? get userId => _userId;

  Future<void> init(AppDatabase db, int userId) async {
    // Idempotenz-Guard: derselbe User ist schon initialisiert -> nichts tun.
    // Wichtig, weil sowohl Session-Restore als auch der Messenger-Screen
    // (Lazy-Fallback) init() aufrufen duerfen, ohne eine zweite
    // WebSocket-Verbindung zu erzeugen.
    if (_service != null && _userId == userId) return;
    // Anderer User als der laufende Service (Logout wurde verpasst o.ae.):
    // erst sauber abbauen, dann neu aufbauen.
    if (_service != null) await shutdown();

    _userId = userId;
    // Ab jetzt bekommt der CONTROLLER die App-Zustandswechsel gemeldet —
    // der Resume-Reconnect funktioniert damit app-weit, nicht mehr nur
    // solange der Messenger-Screen offen ist.
    WidgetsBinding.instance.addObserver(this);

    _service = MessengerApiService(db, userId);
    // Stabiles _events-Band -> EINMAL abonnieren genuegt fuer die ganze
    // Lebenszeit, unabhaengig von spaeteren (Re)connects.
    _subscription = _service!.incoming.listen(_handleEvent);
    _service!.connect().then((_) => notifyListeners());
    // E2EE: lokalen Pubkey mit dem Server abgleichen, parallel zu connect
    _checkOwnPublicKey(userId).catchError((_) {
      debugPrint('[E2EE] Pubkey-Abgleich fehlgeschlagen');
    });
    notifyListeners();
  }

  // Erzeugt NIE ein Keypair — das macht nur KeySetup beim Login (hier, z.B.
  // beim Session-Restore, gibt es kein Passwort fuer das Backup).
  // Der Server-Pubkey ist die aktuelle Schluessel-Generation:
  //   404       -> noch keiner da, unseren hochladen
  //   gleich    -> alles aktuell
  //   anders    -> auf einem anderen Geraet wurde "Chats zuruecksetzen"
  //                gewaehlt, unser Key ist veraltet. NICHT hochladen (das waere
  //                das alte Ping-Pong), sondern lokal loeschen + ausloggen;
  //                beim naechsten Login holt KeySetup den neuen aus dem Backup.
  //   Fehler    -> nichts tun, beim naechsten Start wieder pruefen.
  Future<void> _checkOwnPublicKey(int userId) async {
    final uid = userId.toString();
    final localPub = await KeyService.loadLocalPublicKey(uid);
    if (localPub == null) {
      debugPrint('[E2EE] Kein lokales Keypair — entsteht nur beim Login');
      return;
    }
    final server = await KeyService.fetchOwnPublicKey(userId);
    if (!server.ok) return;
    if (server.publicKey == null) {
      await KeyService.uploadPublicKey(localPub);
    } else if (server.publicKey != localPub) {
      debugPrint('[E2EE] Lokaler Key veraltet -> Keypair loeschen + Logout');
      await KeyService.deleteKeypair(uid);
      KeySetup.setLogoutNotice(
        'Deine Chat-Schlüssel wurden auf einem anderen Gerät zurückgesetzt. '
        'Bitte melde dich neu an.',
      );
      await ApiClient.logout();
    }
  }

  // Flutter ruft das bei jedem Wechsel des App-Zustands auf. Uns interessiert
  // nur die Rueckkehr in den Vordergrund (resumed) — dann war die App evtl. im
  // Hintergrund/Standby und der WebSocket wurde vom OS still gekappt.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Das _events-Band im Service ist stabil und ueberlebt den reconnect().
      // Deshalb muessen wir NICHT neu abonnieren — einmal in init() reicht.
      _service?.reconnect();
    }
  }

  void _handleEvent(ChatEvent event) {
    switch (event) {
      case IncomingDm(:final senderId, :final message):
        debugPrint('DM von $senderId: $message');
      case InComingGroupChat(
        :final groupChatId,
        :final senderId,
        :final message,
      ):
        debugPrint('Group $groupChatId, $senderId: $message');
      case MessageAck(:final to, :final deliveredLive):
        debugPrint('ACK to=$to delivered=$deliveredLive');
      case ChatErrorEvent(:final detail):
        debugPrint('Server-Fehler: $detail');
      case GroupRekeyRequired(:final groupChatId):
        debugPrint('Rekey for group $groupChatId required');
      case GroupKeyOutdated(:final groupChatId, :final currentVersion):
        debugPrint('Key with $currentVersion for group $groupChatId is outdated');
    }
  }

  /// Beim Logout aufrufen: baut Verbindung, Abo und Observer sauber ab.
  Future<void> shutdown() async {
    // removeObserver ist Pflicht, sonst haelt Flutter den Controller fest
    // und der Resume-Reconnect feuert weiter, obwohl niemand eingeloggt ist.
    WidgetsBinding.instance.removeObserver(this);
    await _subscription?.cancel();
    _subscription = null;
    _service?.dispose(); // schliesst Verbindung UND das _events-Band
    _service = null;
    _userId = null;
    notifyListeners();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _subscription?.cancel();
    _service?.dispose();
    super.dispose();
  }
}
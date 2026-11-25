// Regressionstest fuer Phase 0a (Race beim Erstkontakt):
// Zwei+ schnelle DMs eines Fremden durften frueher doppelte OpenChats-Zeilen
// erzeugen -> getSingleOrNull warf StateError -> Messenger tot.
//
// Kein Server noetig: Events gehen direkt aufs _events-Band, die DB liegt im RAM.
// getUser scheitert im Test (kein Token/Netz) -> Fallback "User 42". Genau
// dieses await in _ensureDmOpenChat ist die Luecke, in der das Race entsteht.
// Texte ohne "v1:" reicht _decryptDm unveraendert durch -> keine Krypto noetig.

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ranked/local_data/database.dart';
import 'package:ranked/messenger/messenger_api_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const me = 1;
  const stranger = 42;

  late AppDatabase db;
  late MessengerApiService service;
  late List<String> logs;
  late DebugPrintCallback originalDebugPrint;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    service = MessengerApiService(db, me);

    // debugPrint mitschneiden, um "persist fehlgeschlagen" zu erkennen.
    logs = [];
    originalDebugPrint = debugPrint;
    debugPrint = (String? message, {int? wrapWidth}) {
      if (message != null) logs.add(message);
    };
  });

  tearDown(() async {
    debugPrint = originalDebugPrint;
    service.dispose();
    await db.close();
  });

  IncomingDm dm(int n) => IncomingDm(
    senderId: stranger,
    message: 'race $n',
    createdAt: DateTime.utc(2026, 11, 25, 12, 0, n),
    clientMsgId: 'race-test-$n', // je Nachricht verschieden (unique!)
  );

  // Erst Microtasks laufen lassen: der StreamController liefert Events nicht
  // sofort, sondern im naechsten Microtask aus -> vorher ist die Kette leer.
  Future<void> waitForPersist() async {
    await Future<void>.delayed(Duration.zero);
    await service.debugPersistDone;
  }

  Future<List<OpenChat>> chatsWithStranger() =>
      (db.select(db.openChats)
            ..where((t) => t.id.equals(stranger) & t.isGroupChat.equals(false)))
          .get();

  test('3 schnelle DMs eines Fremden -> genau 1 Anfrage, 3 Nachrichten', () async {
    // Direkt hintereinander, ohne await dazwischen = das Race.
    service.debugAddEvent(dm(1));
    service.debugAddEvent(dm(2));
    service.debugAddEvent(dm(3));
    await waitForPersist();

    final chats = await chatsWithStranger();
    expect(chats, hasLength(1), reason: 'doppelte OpenChats-Zeile');
    expect(chats.single.isPending, isTrue, reason: 'Fremder -> Anfrage');

    final messages = await (db.select(
      db.dmChatHistory,
    )..where((t) => t.senderId.equals(stranger))).get();
    expect(messages.map((m) => m.message), ['race 1', 'race 2', 'race 3']);

    expect(
      logs.where((l) => l.contains('persist fehlgeschlagen')),
      isEmpty,
      reason: logs.join('\n'),
    );
  });

  test('angenommener Chat bleibt angenommen, auch bei neuen DMs', () async {
    await db
        .into(db.openChats)
        .insert(
          OpenChatsCompanion.insert(
            id: stranger,
            isGroupChat: false,
            username: const Value('bekannt'),
          ),
        );

    service.debugAddEvent(dm(1));
    service.debugAddEvent(dm(2));
    await waitForPersist();

    final chats = await chatsWithStranger();
    expect(chats, hasLength(1));
    expect(chats.single.isPending, isFalse);
    expect(chats.single.username, 'bekannt');
  });
}

import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'tables.dart';

part 'database.g.dart';

@DriftDatabase(
  tables: [UserSearchHistory, DmChatHistory, GroupChatHistory, OpenChats, SyncMarkers, PostDrafts],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(driftDatabase(name: 'ranked'));

  @override
  int get schemaVersion => 9;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    onUpgrade: (m, from, to) async {
      if (from < 6) {
        // Wechsel auf Text-Storage macht die alten Integer-Zeitwerte unlesbar.
        // Alle Tabellen mit DateTime-Spalten sind reiner Cache -> verwerfen und
        // neu bauen; der Sync vom Server fuellt sie wieder.
        await m.deleteTable('user_search_history');
        await m.deleteTable('dm_chat_history');
        await m.deleteTable('group_chat_history');
        await m.createTable(userSearchHistory);
        await m.createTable(dmChatHistory);
        await m.createTable(groupChatHistory);

        // OpenChats behalten (Gruppen-Mitgliedschaften kann der Client nicht neu
        // vom Server holen), nur die alte lastSyncedAt-Spalte entfernen.
        await m.alterTable(TableMigration(openChats));

        // Neue zentrale Marker-Tabelle.
        await m.createTable(syncMarkers);
      }
      if (from < 7) {
        // client_msg_id (Idempotenz-Key) kommt an die Message-Tabellen.
        // SQLite kann eine UNIQUE-Spalte nicht per ALTER nachruesten -> wir
        // bauen die reinen Cache-Tabellen neu. Die Marker werfen wir mit weg,
        // damit der naechste connect() einen VOLLEN Re-Sync macht und die neue
        // Spalte fuellt (sonst blieben die alten Zeilen ohne Key liegen).
        await m.deleteTable('dm_chat_history');
        await m.deleteTable('group_chat_history');
        await m.deleteTable('sync_markers');
        await m.createTable(dmChatHistory);
        await m.createTable(groupChatHistory);
        await m.createTable(syncMarkers);
      }
      if (from < 8) {
        // createTable baut die Tabelle nach aktuellem Schema -> draft_type ist
        // hier schon drin, Schritt 9 wird nicht mehr gebraucht.
        await m.createTable(postDrafts);
      } else if (from < 9) {
        await m.addColumn(postDrafts, postDrafts.draftType);
      }
    },
  );

  // ------------------------------------------------------------------
  //  User-Such-Historie
  // ------------------------------------------------------------------

  Future<void> saveUserSearchHistory(
    int userId,
    String username, {
    String? avatarUrl,
    String? vibe1,
    String? vibe2,
  }) async {
    await into(userSearchHistory).insert(
      UserSearchHistoryCompanion(
        userId: Value(userId),
        username: Value(username),
        avatarUrl: Value(avatarUrl),
        vibe1: Value(vibe1),
        vibe2: Value(vibe2),
      ),
    );
  }

  Future<List<UserSearchHistoryData>> getRecentSearches({int limit = 20}) {
    return (select(userSearchHistory)
          ..orderBy([(t) => OrderingTerm.desc(t.clickedAt)])
          ..limit(limit))
        .get();
  }

  Stream<List<UserSearchHistoryData>> watchRecentSearches({int limit = 20}) {
    return (select(userSearchHistory)
          ..orderBy([(t) => OrderingTerm.desc(t.clickedAt)])
          ..limit(limit))
        .watch();
  }

  Future<int> clearSearchHistory() => delete(userSearchHistory).go();

  Future<void> saveDm({
    required int senderId,
    required int recipientId,
    required String message,
    required DateTime createdAt,
    String? clientMsgId,
  }) async {
    // insertOrIgnore: kollidiert clientMsgId mit einer schon vorhandenen Zeile
    // (Echo <-> spaeter gesyncte Server-Zeile), wird der zweite Insert verworfen
    // statt zu duplizieren. clientMsgId == null -> kein Konflikt (mehrere NULLs
    // erlaubt), verhaelt sich wie ein normaler Insert.
    await into(dmChatHistory).insert(
      DmChatHistoryCompanion(
        senderId: Value(senderId),
        recipientId: Value(recipientId),
        message: Value(message),
        createdAt: Value(createdAt),
        clientMsgId: Value(clientMsgId),
      ),
      mode: InsertMode.insertOrIgnore,
    );
  }

  Future<void> saveGroupMessage({
    required int senderId,
    required int groupChatId,
    required String message,
    required DateTime createdAt,
    String? clientMsgId,
  }) async {
    await into(groupChatHistory).insert(
      GroupChatHistoryCompanion(
        senderId: Value(senderId),
        groupChatId: Value(groupChatId),
        message: Value(message),
        createdAt: Value(createdAt),
        clientMsgId: Value(clientMsgId),
      ),
      mode: InsertMode.insertOrIgnore,
    );
  }

  // Chat-Fenster: Wir laden nie den kompletten Verlauf in den Speicher,
  // sondern nur die juengsten N Nachrichten. Dafuer MUSS absteigend sortiert
  // werden (neueste zuerst) — nur so greift das LIMIT das richtige Ende.
  static const chatWindowSize = 200;

  Stream<List<DmChatHistoryData>> watchDmConversation({
    required int myUserId,
    required int otherUserId,
  }) {
    return (select(dmChatHistory)
          ..where(
            (t) =>
                (t.senderId.equals(myUserId) &
                    t.recipientId.equals(otherUserId)) |
                (t.senderId.equals(otherUserId) &
                    t.recipientId.equals(myUserId)),
          )
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)])
          ..limit(chatWindowSize))
        .watch();
  }

  Stream<List<GroupChatHistoryData>> watchGroupConversation({
    required int groupChatId,
  }) {
    return (select(groupChatHistory)
          ..where((t) => t.groupChatId.equals(groupChatId))
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)])
          ..limit(chatWindowSize))
        .watch();
  }
  
  Future<void> saveNewOpenChats({
    required int id, required bool isGroupChat, String? avatarUrl, String? username
})  async {
    await into(openChats).insert(OpenChatsCompanion(
      id: Value(id),
      isGroupChat: Value(isGroupChat),
      username: username != null
          ? Value(username)
          : const Value.absent(),
      avatarUrl: Value(avatarUrl)
      
    ));
  }

  Stream<List<OpenChat>> watchAllContacts() {
    return select(openChats).watch();
  }

  // Liest den Marker fuer einen Scope ("dm" / "group:<id>").
  // null = noch nie gesynct -> Aufrufer holt kompletten Verlauf.
  Future<DateTime?> getSyncMarker(String key) async {
    final row = await (select(syncMarkers)..where((t) => t.key.equals(key)))
        .getSingleOrNull();
    return row?.lastSyncedAt;
  }

  // Setzt den Marker auf max(bestehend, ts). Aelteres ueberschreibt nie.
  Future<void> updateSyncMarker(String key, DateTime ts) async {
    final existing = await getSyncMarker(key);
    if (existing != null && !ts.isAfter(existing)) return;
    await into(syncMarkers).insertOnConflictUpdate(
      SyncMarkersCompanion(key: Value(key), lastSyncedAt: Value(ts)),
    );
  }

  Future<List<OpenChat>> getAllContacts() => select(openChats).get();

  // ------------------------------------------------------------------
  //  Post-Entwurf (genau eine Zeile, id = 0)
  // ------------------------------------------------------------------

  // insertOnConflictUpdate + feste id 0: existiert schon ein Entwurf, wird
  // er ueberschrieben statt eine zweite Zeile anzulegen.
  Future<void> savePostDraft({
    required String title,
    required String content,
    String? tag,
    required bool isPublic,
    String? imagePath,
    String draftType = 'post',
  }) async {
    await into(postDrafts).insertOnConflictUpdate(
      PostDraftsCompanion(
        id: const Value(0),
        draftType: Value(draftType),
        title: Value(title),
        content: Value(content),
        tag: Value(tag),
        isPublic: Value(isPublic),
        imagePath: Value(imagePath),
        savedAt: Value(DateTime.now()),
      ),
    );
  }

  // PATCH: haengt nur das Bild an den bestehenden Entwurf, Titel/Text/Tag
  // bleiben unberuehrt (alle anderen Companion-Felder sind Value.absent()).
  // Gibt es noch keinen Entwurf (Kamera ohne getippten Text geoeffnet),
  // wird stattdessen ein leerer mit dem Bild angelegt.
  Future<void> attachImageToPostDraft(String imagePath) async {
    final updated = await (update(postDrafts)..where((t) => t.id.equals(0)))
        .write(
          PostDraftsCompanion(
            imagePath: Value(imagePath),
            savedAt: Value(DateTime.now()),
          ),
        );
    if (updated == 0) {
      await savePostDraft(
        title: '',
        content: '',
        isPublic: true,
        imagePath: imagePath,
      );
    }
  }

  // null = kein Entwurf vorhanden.
  Future<PostDraft?> getPostDraft() =>
      (select(postDrafts)..where((t) => t.id.equals(0))).getSingleOrNull();

  Future<void> deletePostDraft() async {
    await delete(postDrafts).go();
  }

  Future<void> clearDatabase() async {
    await transaction(() async {
      for (final table in allTables.toList().reversed) {
        await delete(table).go();
      }
    });

  }
}

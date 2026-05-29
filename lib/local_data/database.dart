import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'tables.dart';

part 'database.g.dart';

@DriftDatabase(tables: [UserSearchHistory, DmChatHistory, GroupChatHistory, OpenChats])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(driftDatabase(name: 'ranked'));

  @override
  int get schemaVersion => 4;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    onUpgrade: (m, from, to) async {
      if (from < 3) {
        await m.createTable(dmChatHistory);
        await m.createTable(groupChatHistory);
      }
      if (from < 4) {
        await m.createTable(openChats); // 'contacts' wird von Drift klein geschrieben generiert
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
  }) async {
    await into(dmChatHistory).insert(
      DmChatHistoryCompanion(
        senderId: Value(senderId),
        recipientId: Value(recipientId),
        message: Value(message),
        createdAt: Value(createdAt),
      ),
    );
  }

  Future<void> saveGroupMessage({
    required int senderId,
    required int groupChatId,
    required String message,
    required DateTime createdAt,
  }) async {
    await into(groupChatHistory).insert(
      GroupChatHistoryCompanion(
        senderId: Value(senderId),
        groupChatId: Value(groupChatId),
        message: Value(message),
        createdAt: Value(createdAt),
      ),
    );
  }

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
          ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
        .watch();
  }

  Stream<List<GroupChatHistoryData>> watchGroupConversation({
    required int groupChatId,
  }) {
    return (select(groupChatHistory)
      ..where((t) => t.groupChatId.equals(groupChatId))
      ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
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

}

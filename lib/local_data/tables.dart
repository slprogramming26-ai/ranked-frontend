
import 'package:drift/drift.dart';

class UserSearchHistory extends Table {

  IntColumn get id => integer().autoIncrement()();

  IntColumn get userId => integer()();
  TextColumn get username => text()();
  TextColumn get avatarUrl => text().nullable()();
  TextColumn get vibe1 => text().nullable()();
  TextColumn get vibe2 => text().nullable()();
  DateTimeColumn get clickedAt => dateTime().withDefault(currentDateAndTime)();
}


class DmChatHistory extends Table {

  IntColumn get id => integer().autoIncrement()();
  IntColumn get senderId => integer()();
  IntColumn get recipientId => integer()();
  TextColumn get message => text()();
  DateTimeColumn get createdAt => dateTime()();

  // Idempotenz-Key: vom Client beim Senden erzeugte UUID. Wandert mit zum Server,
  // kommt in WS-Push UND REST-Sync zurueck. unique -> das lokale Echo und die
  // spaeter gesyncte Server-Zeile haben denselben Key, der zweite Insert wird
  // ignoriert (insertOrIgnore) statt zu duplizieren. nullable, weil alte/fremde
  // Nachrichten (noch) keinen Key haben; mehrere NULLs sind in SQLite erlaubt.
  TextColumn get clientMsgId => text().nullable().unique()();

}

class GroupChatHistory extends Table {

  IntColumn get id => integer().autoIncrement()();
  IntColumn get senderId => integer()();
  IntColumn get groupChatId => integer()();
  TextColumn get message => text()();
  DateTimeColumn get createdAt => dateTime()();

  // Siehe DmChatHistory.clientMsgId.
  TextColumn get clientMsgId => text().nullable().unique()();

}


class OpenChats extends Table {

  IntColumn get localId => integer().autoIncrement()(); //id dieses chats (nur auf handy)
  BoolColumn get isGroupChat => boolean()();
  IntColumn get id => integer()(); //id des gruppenchats, nutzer auf server
  TextColumn get username => text().withDefault(const Constant('New'))();
  TextColumn get avatarUrl => text().nullable()();

}

// Zentraler Sync-Marker-Speicher (Key-Value).
// key = "dm" fuer alle Direktnachrichten (ein globaler Endpoint -> ein Marker),
//       "group:<id>" pro Gruppe (ein Endpoint pro Gruppe -> ein Marker je Gruppe).
// lastSyncedAt = neuester created_at, den wir fuer diesen Scope gesehen haben.
class SyncMarkers extends Table {

  TextColumn get key => text()();
  DateTimeColumn get lastSyncedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {key};

}
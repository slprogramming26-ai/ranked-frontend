
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

}

class GroupChatHistory extends Table {

  IntColumn get id => integer().autoIncrement()();
  IntColumn get senderId => integer()();
  IntColumn get groupChatId => integer()();
  TextColumn get message => text()();
  DateTimeColumn get createdAt => dateTime()();

}


class OpenChats extends Table {

  IntColumn get localId => integer().autoIncrement()();
  BoolColumn get isGroupChat => boolean()();
  IntColumn get id => integer()();
  TextColumn get username => text().withDefault(const Constant('New'))();
  TextColumn get avatarUrl => text().nullable()();

}
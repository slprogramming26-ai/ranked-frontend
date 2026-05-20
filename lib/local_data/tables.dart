
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
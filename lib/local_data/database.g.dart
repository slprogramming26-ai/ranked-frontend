// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $UserSearchHistoryTable extends UserSearchHistory
    with TableInfo<$UserSearchHistoryTable, UserSearchHistoryData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $UserSearchHistoryTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<int> userId = GeneratedColumn<int>(
    'user_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _usernameMeta = const VerificationMeta(
    'username',
  );
  @override
  late final GeneratedColumn<String> username = GeneratedColumn<String>(
    'username',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _avatarUrlMeta = const VerificationMeta(
    'avatarUrl',
  );
  @override
  late final GeneratedColumn<String> avatarUrl = GeneratedColumn<String>(
    'avatar_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _vibe1Meta = const VerificationMeta('vibe1');
  @override
  late final GeneratedColumn<String> vibe1 = GeneratedColumn<String>(
    'vibe1',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _vibe2Meta = const VerificationMeta('vibe2');
  @override
  late final GeneratedColumn<String> vibe2 = GeneratedColumn<String>(
    'vibe2',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _clickedAtMeta = const VerificationMeta(
    'clickedAt',
  );
  @override
  late final GeneratedColumn<DateTime> clickedAt = GeneratedColumn<DateTime>(
    'clicked_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    userId,
    username,
    avatarUrl,
    vibe1,
    vibe2,
    clickedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'user_search_history';
  @override
  VerificationContext validateIntegrity(
    Insertable<UserSearchHistoryData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('username')) {
      context.handle(
        _usernameMeta,
        username.isAcceptableOrUnknown(data['username']!, _usernameMeta),
      );
    } else if (isInserting) {
      context.missing(_usernameMeta);
    }
    if (data.containsKey('avatar_url')) {
      context.handle(
        _avatarUrlMeta,
        avatarUrl.isAcceptableOrUnknown(data['avatar_url']!, _avatarUrlMeta),
      );
    }
    if (data.containsKey('vibe1')) {
      context.handle(
        _vibe1Meta,
        vibe1.isAcceptableOrUnknown(data['vibe1']!, _vibe1Meta),
      );
    }
    if (data.containsKey('vibe2')) {
      context.handle(
        _vibe2Meta,
        vibe2.isAcceptableOrUnknown(data['vibe2']!, _vibe2Meta),
      );
    }
    if (data.containsKey('clicked_at')) {
      context.handle(
        _clickedAtMeta,
        clickedAt.isAcceptableOrUnknown(data['clicked_at']!, _clickedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  UserSearchHistoryData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return UserSearchHistoryData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}user_id'],
      )!,
      username: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}username'],
      )!,
      avatarUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}avatar_url'],
      ),
      vibe1: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}vibe1'],
      ),
      vibe2: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}vibe2'],
      ),
      clickedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}clicked_at'],
      )!,
    );
  }

  @override
  $UserSearchHistoryTable createAlias(String alias) {
    return $UserSearchHistoryTable(attachedDatabase, alias);
  }
}

class UserSearchHistoryData extends DataClass
    implements Insertable<UserSearchHistoryData> {
  final int id;
  final int userId;
  final String username;
  final String? avatarUrl;
  final String? vibe1;
  final String? vibe2;
  final DateTime clickedAt;
  const UserSearchHistoryData({
    required this.id,
    required this.userId,
    required this.username,
    this.avatarUrl,
    this.vibe1,
    this.vibe2,
    required this.clickedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['user_id'] = Variable<int>(userId);
    map['username'] = Variable<String>(username);
    if (!nullToAbsent || avatarUrl != null) {
      map['avatar_url'] = Variable<String>(avatarUrl);
    }
    if (!nullToAbsent || vibe1 != null) {
      map['vibe1'] = Variable<String>(vibe1);
    }
    if (!nullToAbsent || vibe2 != null) {
      map['vibe2'] = Variable<String>(vibe2);
    }
    map['clicked_at'] = Variable<DateTime>(clickedAt);
    return map;
  }

  UserSearchHistoryCompanion toCompanion(bool nullToAbsent) {
    return UserSearchHistoryCompanion(
      id: Value(id),
      userId: Value(userId),
      username: Value(username),
      avatarUrl: avatarUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(avatarUrl),
      vibe1: vibe1 == null && nullToAbsent
          ? const Value.absent()
          : Value(vibe1),
      vibe2: vibe2 == null && nullToAbsent
          ? const Value.absent()
          : Value(vibe2),
      clickedAt: Value(clickedAt),
    );
  }

  factory UserSearchHistoryData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return UserSearchHistoryData(
      id: serializer.fromJson<int>(json['id']),
      userId: serializer.fromJson<int>(json['userId']),
      username: serializer.fromJson<String>(json['username']),
      avatarUrl: serializer.fromJson<String?>(json['avatarUrl']),
      vibe1: serializer.fromJson<String?>(json['vibe1']),
      vibe2: serializer.fromJson<String?>(json['vibe2']),
      clickedAt: serializer.fromJson<DateTime>(json['clickedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'userId': serializer.toJson<int>(userId),
      'username': serializer.toJson<String>(username),
      'avatarUrl': serializer.toJson<String?>(avatarUrl),
      'vibe1': serializer.toJson<String?>(vibe1),
      'vibe2': serializer.toJson<String?>(vibe2),
      'clickedAt': serializer.toJson<DateTime>(clickedAt),
    };
  }

  UserSearchHistoryData copyWith({
    int? id,
    int? userId,
    String? username,
    Value<String?> avatarUrl = const Value.absent(),
    Value<String?> vibe1 = const Value.absent(),
    Value<String?> vibe2 = const Value.absent(),
    DateTime? clickedAt,
  }) => UserSearchHistoryData(
    id: id ?? this.id,
    userId: userId ?? this.userId,
    username: username ?? this.username,
    avatarUrl: avatarUrl.present ? avatarUrl.value : this.avatarUrl,
    vibe1: vibe1.present ? vibe1.value : this.vibe1,
    vibe2: vibe2.present ? vibe2.value : this.vibe2,
    clickedAt: clickedAt ?? this.clickedAt,
  );
  UserSearchHistoryData copyWithCompanion(UserSearchHistoryCompanion data) {
    return UserSearchHistoryData(
      id: data.id.present ? data.id.value : this.id,
      userId: data.userId.present ? data.userId.value : this.userId,
      username: data.username.present ? data.username.value : this.username,
      avatarUrl: data.avatarUrl.present ? data.avatarUrl.value : this.avatarUrl,
      vibe1: data.vibe1.present ? data.vibe1.value : this.vibe1,
      vibe2: data.vibe2.present ? data.vibe2.value : this.vibe2,
      clickedAt: data.clickedAt.present ? data.clickedAt.value : this.clickedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('UserSearchHistoryData(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('username: $username, ')
          ..write('avatarUrl: $avatarUrl, ')
          ..write('vibe1: $vibe1, ')
          ..write('vibe2: $vibe2, ')
          ..write('clickedAt: $clickedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, userId, username, avatarUrl, vibe1, vibe2, clickedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is UserSearchHistoryData &&
          other.id == this.id &&
          other.userId == this.userId &&
          other.username == this.username &&
          other.avatarUrl == this.avatarUrl &&
          other.vibe1 == this.vibe1 &&
          other.vibe2 == this.vibe2 &&
          other.clickedAt == this.clickedAt);
}

class UserSearchHistoryCompanion
    extends UpdateCompanion<UserSearchHistoryData> {
  final Value<int> id;
  final Value<int> userId;
  final Value<String> username;
  final Value<String?> avatarUrl;
  final Value<String?> vibe1;
  final Value<String?> vibe2;
  final Value<DateTime> clickedAt;
  const UserSearchHistoryCompanion({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.username = const Value.absent(),
    this.avatarUrl = const Value.absent(),
    this.vibe1 = const Value.absent(),
    this.vibe2 = const Value.absent(),
    this.clickedAt = const Value.absent(),
  });
  UserSearchHistoryCompanion.insert({
    this.id = const Value.absent(),
    required int userId,
    required String username,
    this.avatarUrl = const Value.absent(),
    this.vibe1 = const Value.absent(),
    this.vibe2 = const Value.absent(),
    this.clickedAt = const Value.absent(),
  }) : userId = Value(userId),
       username = Value(username);
  static Insertable<UserSearchHistoryData> custom({
    Expression<int>? id,
    Expression<int>? userId,
    Expression<String>? username,
    Expression<String>? avatarUrl,
    Expression<String>? vibe1,
    Expression<String>? vibe2,
    Expression<DateTime>? clickedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (username != null) 'username': username,
      if (avatarUrl != null) 'avatar_url': avatarUrl,
      if (vibe1 != null) 'vibe1': vibe1,
      if (vibe2 != null) 'vibe2': vibe2,
      if (clickedAt != null) 'clicked_at': clickedAt,
    });
  }

  UserSearchHistoryCompanion copyWith({
    Value<int>? id,
    Value<int>? userId,
    Value<String>? username,
    Value<String?>? avatarUrl,
    Value<String?>? vibe1,
    Value<String?>? vibe2,
    Value<DateTime>? clickedAt,
  }) {
    return UserSearchHistoryCompanion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      username: username ?? this.username,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      vibe1: vibe1 ?? this.vibe1,
      vibe2: vibe2 ?? this.vibe2,
      clickedAt: clickedAt ?? this.clickedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<int>(userId.value);
    }
    if (username.present) {
      map['username'] = Variable<String>(username.value);
    }
    if (avatarUrl.present) {
      map['avatar_url'] = Variable<String>(avatarUrl.value);
    }
    if (vibe1.present) {
      map['vibe1'] = Variable<String>(vibe1.value);
    }
    if (vibe2.present) {
      map['vibe2'] = Variable<String>(vibe2.value);
    }
    if (clickedAt.present) {
      map['clicked_at'] = Variable<DateTime>(clickedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('UserSearchHistoryCompanion(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('username: $username, ')
          ..write('avatarUrl: $avatarUrl, ')
          ..write('vibe1: $vibe1, ')
          ..write('vibe2: $vibe2, ')
          ..write('clickedAt: $clickedAt')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $UserSearchHistoryTable userSearchHistory =
      $UserSearchHistoryTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [userSearchHistory];
}

typedef $$UserSearchHistoryTableCreateCompanionBuilder =
    UserSearchHistoryCompanion Function({
      Value<int> id,
      required int userId,
      required String username,
      Value<String?> avatarUrl,
      Value<String?> vibe1,
      Value<String?> vibe2,
      Value<DateTime> clickedAt,
    });
typedef $$UserSearchHistoryTableUpdateCompanionBuilder =
    UserSearchHistoryCompanion Function({
      Value<int> id,
      Value<int> userId,
      Value<String> username,
      Value<String?> avatarUrl,
      Value<String?> vibe1,
      Value<String?> vibe2,
      Value<DateTime> clickedAt,
    });

class $$UserSearchHistoryTableFilterComposer
    extends Composer<_$AppDatabase, $UserSearchHistoryTable> {
  $$UserSearchHistoryTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get username => $composableBuilder(
    column: $table.username,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get avatarUrl => $composableBuilder(
    column: $table.avatarUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get vibe1 => $composableBuilder(
    column: $table.vibe1,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get vibe2 => $composableBuilder(
    column: $table.vibe2,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get clickedAt => $composableBuilder(
    column: $table.clickedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$UserSearchHistoryTableOrderingComposer
    extends Composer<_$AppDatabase, $UserSearchHistoryTable> {
  $$UserSearchHistoryTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get username => $composableBuilder(
    column: $table.username,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get avatarUrl => $composableBuilder(
    column: $table.avatarUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get vibe1 => $composableBuilder(
    column: $table.vibe1,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get vibe2 => $composableBuilder(
    column: $table.vibe2,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get clickedAt => $composableBuilder(
    column: $table.clickedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$UserSearchHistoryTableAnnotationComposer
    extends Composer<_$AppDatabase, $UserSearchHistoryTable> {
  $$UserSearchHistoryTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get username =>
      $composableBuilder(column: $table.username, builder: (column) => column);

  GeneratedColumn<String> get avatarUrl =>
      $composableBuilder(column: $table.avatarUrl, builder: (column) => column);

  GeneratedColumn<String> get vibe1 =>
      $composableBuilder(column: $table.vibe1, builder: (column) => column);

  GeneratedColumn<String> get vibe2 =>
      $composableBuilder(column: $table.vibe2, builder: (column) => column);

  GeneratedColumn<DateTime> get clickedAt =>
      $composableBuilder(column: $table.clickedAt, builder: (column) => column);
}

class $$UserSearchHistoryTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $UserSearchHistoryTable,
          UserSearchHistoryData,
          $$UserSearchHistoryTableFilterComposer,
          $$UserSearchHistoryTableOrderingComposer,
          $$UserSearchHistoryTableAnnotationComposer,
          $$UserSearchHistoryTableCreateCompanionBuilder,
          $$UserSearchHistoryTableUpdateCompanionBuilder,
          (
            UserSearchHistoryData,
            BaseReferences<
              _$AppDatabase,
              $UserSearchHistoryTable,
              UserSearchHistoryData
            >,
          ),
          UserSearchHistoryData,
          PrefetchHooks Function()
        > {
  $$UserSearchHistoryTableTableManager(
    _$AppDatabase db,
    $UserSearchHistoryTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$UserSearchHistoryTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$UserSearchHistoryTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$UserSearchHistoryTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> userId = const Value.absent(),
                Value<String> username = const Value.absent(),
                Value<String?> avatarUrl = const Value.absent(),
                Value<String?> vibe1 = const Value.absent(),
                Value<String?> vibe2 = const Value.absent(),
                Value<DateTime> clickedAt = const Value.absent(),
              }) => UserSearchHistoryCompanion(
                id: id,
                userId: userId,
                username: username,
                avatarUrl: avatarUrl,
                vibe1: vibe1,
                vibe2: vibe2,
                clickedAt: clickedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int userId,
                required String username,
                Value<String?> avatarUrl = const Value.absent(),
                Value<String?> vibe1 = const Value.absent(),
                Value<String?> vibe2 = const Value.absent(),
                Value<DateTime> clickedAt = const Value.absent(),
              }) => UserSearchHistoryCompanion.insert(
                id: id,
                userId: userId,
                username: username,
                avatarUrl: avatarUrl,
                vibe1: vibe1,
                vibe2: vibe2,
                clickedAt: clickedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$UserSearchHistoryTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $UserSearchHistoryTable,
      UserSearchHistoryData,
      $$UserSearchHistoryTableFilterComposer,
      $$UserSearchHistoryTableOrderingComposer,
      $$UserSearchHistoryTableAnnotationComposer,
      $$UserSearchHistoryTableCreateCompanionBuilder,
      $$UserSearchHistoryTableUpdateCompanionBuilder,
      (
        UserSearchHistoryData,
        BaseReferences<
          _$AppDatabase,
          $UserSearchHistoryTable,
          UserSearchHistoryData
        >,
      ),
      UserSearchHistoryData,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$UserSearchHistoryTableTableManager get userSearchHistory =>
      $$UserSearchHistoryTableTableManager(_db, _db.userSearchHistory);
}

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

class $DmChatHistoryTable extends DmChatHistory
    with TableInfo<$DmChatHistoryTable, DmChatHistoryData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DmChatHistoryTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _senderIdMeta = const VerificationMeta(
    'senderId',
  );
  @override
  late final GeneratedColumn<int> senderId = GeneratedColumn<int>(
    'sender_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _recipientIdMeta = const VerificationMeta(
    'recipientId',
  );
  @override
  late final GeneratedColumn<int> recipientId = GeneratedColumn<int>(
    'recipient_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _messageMeta = const VerificationMeta(
    'message',
  );
  @override
  late final GeneratedColumn<String> message = GeneratedColumn<String>(
    'message',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    senderId,
    recipientId,
    message,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'dm_chat_history';
  @override
  VerificationContext validateIntegrity(
    Insertable<DmChatHistoryData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('sender_id')) {
      context.handle(
        _senderIdMeta,
        senderId.isAcceptableOrUnknown(data['sender_id']!, _senderIdMeta),
      );
    } else if (isInserting) {
      context.missing(_senderIdMeta);
    }
    if (data.containsKey('recipient_id')) {
      context.handle(
        _recipientIdMeta,
        recipientId.isAcceptableOrUnknown(
          data['recipient_id']!,
          _recipientIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_recipientIdMeta);
    }
    if (data.containsKey('message')) {
      context.handle(
        _messageMeta,
        message.isAcceptableOrUnknown(data['message']!, _messageMeta),
      );
    } else if (isInserting) {
      context.missing(_messageMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  DmChatHistoryData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DmChatHistoryData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      senderId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sender_id'],
      )!,
      recipientId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}recipient_id'],
      )!,
      message: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}message'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $DmChatHistoryTable createAlias(String alias) {
    return $DmChatHistoryTable(attachedDatabase, alias);
  }
}

class DmChatHistoryData extends DataClass
    implements Insertable<DmChatHistoryData> {
  final int id;
  final int senderId;
  final int recipientId;
  final String message;
  final DateTime createdAt;
  const DmChatHistoryData({
    required this.id,
    required this.senderId,
    required this.recipientId,
    required this.message,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['sender_id'] = Variable<int>(senderId);
    map['recipient_id'] = Variable<int>(recipientId);
    map['message'] = Variable<String>(message);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  DmChatHistoryCompanion toCompanion(bool nullToAbsent) {
    return DmChatHistoryCompanion(
      id: Value(id),
      senderId: Value(senderId),
      recipientId: Value(recipientId),
      message: Value(message),
      createdAt: Value(createdAt),
    );
  }

  factory DmChatHistoryData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DmChatHistoryData(
      id: serializer.fromJson<int>(json['id']),
      senderId: serializer.fromJson<int>(json['senderId']),
      recipientId: serializer.fromJson<int>(json['recipientId']),
      message: serializer.fromJson<String>(json['message']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'senderId': serializer.toJson<int>(senderId),
      'recipientId': serializer.toJson<int>(recipientId),
      'message': serializer.toJson<String>(message),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  DmChatHistoryData copyWith({
    int? id,
    int? senderId,
    int? recipientId,
    String? message,
    DateTime? createdAt,
  }) => DmChatHistoryData(
    id: id ?? this.id,
    senderId: senderId ?? this.senderId,
    recipientId: recipientId ?? this.recipientId,
    message: message ?? this.message,
    createdAt: createdAt ?? this.createdAt,
  );
  DmChatHistoryData copyWithCompanion(DmChatHistoryCompanion data) {
    return DmChatHistoryData(
      id: data.id.present ? data.id.value : this.id,
      senderId: data.senderId.present ? data.senderId.value : this.senderId,
      recipientId: data.recipientId.present
          ? data.recipientId.value
          : this.recipientId,
      message: data.message.present ? data.message.value : this.message,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DmChatHistoryData(')
          ..write('id: $id, ')
          ..write('senderId: $senderId, ')
          ..write('recipientId: $recipientId, ')
          ..write('message: $message, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, senderId, recipientId, message, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DmChatHistoryData &&
          other.id == this.id &&
          other.senderId == this.senderId &&
          other.recipientId == this.recipientId &&
          other.message == this.message &&
          other.createdAt == this.createdAt);
}

class DmChatHistoryCompanion extends UpdateCompanion<DmChatHistoryData> {
  final Value<int> id;
  final Value<int> senderId;
  final Value<int> recipientId;
  final Value<String> message;
  final Value<DateTime> createdAt;
  const DmChatHistoryCompanion({
    this.id = const Value.absent(),
    this.senderId = const Value.absent(),
    this.recipientId = const Value.absent(),
    this.message = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  DmChatHistoryCompanion.insert({
    this.id = const Value.absent(),
    required int senderId,
    required int recipientId,
    required String message,
    required DateTime createdAt,
  }) : senderId = Value(senderId),
       recipientId = Value(recipientId),
       message = Value(message),
       createdAt = Value(createdAt);
  static Insertable<DmChatHistoryData> custom({
    Expression<int>? id,
    Expression<int>? senderId,
    Expression<int>? recipientId,
    Expression<String>? message,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (senderId != null) 'sender_id': senderId,
      if (recipientId != null) 'recipient_id': recipientId,
      if (message != null) 'message': message,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  DmChatHistoryCompanion copyWith({
    Value<int>? id,
    Value<int>? senderId,
    Value<int>? recipientId,
    Value<String>? message,
    Value<DateTime>? createdAt,
  }) {
    return DmChatHistoryCompanion(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      recipientId: recipientId ?? this.recipientId,
      message: message ?? this.message,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (senderId.present) {
      map['sender_id'] = Variable<int>(senderId.value);
    }
    if (recipientId.present) {
      map['recipient_id'] = Variable<int>(recipientId.value);
    }
    if (message.present) {
      map['message'] = Variable<String>(message.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DmChatHistoryCompanion(')
          ..write('id: $id, ')
          ..write('senderId: $senderId, ')
          ..write('recipientId: $recipientId, ')
          ..write('message: $message, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $GroupChatHistoryTable extends GroupChatHistory
    with TableInfo<$GroupChatHistoryTable, GroupChatHistoryData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $GroupChatHistoryTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _senderIdMeta = const VerificationMeta(
    'senderId',
  );
  @override
  late final GeneratedColumn<int> senderId = GeneratedColumn<int>(
    'sender_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _groupChatIdMeta = const VerificationMeta(
    'groupChatId',
  );
  @override
  late final GeneratedColumn<int> groupChatId = GeneratedColumn<int>(
    'group_chat_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _messageMeta = const VerificationMeta(
    'message',
  );
  @override
  late final GeneratedColumn<String> message = GeneratedColumn<String>(
    'message',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    senderId,
    groupChatId,
    message,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'group_chat_history';
  @override
  VerificationContext validateIntegrity(
    Insertable<GroupChatHistoryData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('sender_id')) {
      context.handle(
        _senderIdMeta,
        senderId.isAcceptableOrUnknown(data['sender_id']!, _senderIdMeta),
      );
    } else if (isInserting) {
      context.missing(_senderIdMeta);
    }
    if (data.containsKey('group_chat_id')) {
      context.handle(
        _groupChatIdMeta,
        groupChatId.isAcceptableOrUnknown(
          data['group_chat_id']!,
          _groupChatIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_groupChatIdMeta);
    }
    if (data.containsKey('message')) {
      context.handle(
        _messageMeta,
        message.isAcceptableOrUnknown(data['message']!, _messageMeta),
      );
    } else if (isInserting) {
      context.missing(_messageMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  GroupChatHistoryData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return GroupChatHistoryData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      senderId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sender_id'],
      )!,
      groupChatId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}group_chat_id'],
      )!,
      message: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}message'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $GroupChatHistoryTable createAlias(String alias) {
    return $GroupChatHistoryTable(attachedDatabase, alias);
  }
}

class GroupChatHistoryData extends DataClass
    implements Insertable<GroupChatHistoryData> {
  final int id;
  final int senderId;
  final int groupChatId;
  final String message;
  final DateTime createdAt;
  const GroupChatHistoryData({
    required this.id,
    required this.senderId,
    required this.groupChatId,
    required this.message,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['sender_id'] = Variable<int>(senderId);
    map['group_chat_id'] = Variable<int>(groupChatId);
    map['message'] = Variable<String>(message);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  GroupChatHistoryCompanion toCompanion(bool nullToAbsent) {
    return GroupChatHistoryCompanion(
      id: Value(id),
      senderId: Value(senderId),
      groupChatId: Value(groupChatId),
      message: Value(message),
      createdAt: Value(createdAt),
    );
  }

  factory GroupChatHistoryData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return GroupChatHistoryData(
      id: serializer.fromJson<int>(json['id']),
      senderId: serializer.fromJson<int>(json['senderId']),
      groupChatId: serializer.fromJson<int>(json['groupChatId']),
      message: serializer.fromJson<String>(json['message']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'senderId': serializer.toJson<int>(senderId),
      'groupChatId': serializer.toJson<int>(groupChatId),
      'message': serializer.toJson<String>(message),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  GroupChatHistoryData copyWith({
    int? id,
    int? senderId,
    int? groupChatId,
    String? message,
    DateTime? createdAt,
  }) => GroupChatHistoryData(
    id: id ?? this.id,
    senderId: senderId ?? this.senderId,
    groupChatId: groupChatId ?? this.groupChatId,
    message: message ?? this.message,
    createdAt: createdAt ?? this.createdAt,
  );
  GroupChatHistoryData copyWithCompanion(GroupChatHistoryCompanion data) {
    return GroupChatHistoryData(
      id: data.id.present ? data.id.value : this.id,
      senderId: data.senderId.present ? data.senderId.value : this.senderId,
      groupChatId: data.groupChatId.present
          ? data.groupChatId.value
          : this.groupChatId,
      message: data.message.present ? data.message.value : this.message,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('GroupChatHistoryData(')
          ..write('id: $id, ')
          ..write('senderId: $senderId, ')
          ..write('groupChatId: $groupChatId, ')
          ..write('message: $message, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, senderId, groupChatId, message, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is GroupChatHistoryData &&
          other.id == this.id &&
          other.senderId == this.senderId &&
          other.groupChatId == this.groupChatId &&
          other.message == this.message &&
          other.createdAt == this.createdAt);
}

class GroupChatHistoryCompanion extends UpdateCompanion<GroupChatHistoryData> {
  final Value<int> id;
  final Value<int> senderId;
  final Value<int> groupChatId;
  final Value<String> message;
  final Value<DateTime> createdAt;
  const GroupChatHistoryCompanion({
    this.id = const Value.absent(),
    this.senderId = const Value.absent(),
    this.groupChatId = const Value.absent(),
    this.message = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  GroupChatHistoryCompanion.insert({
    this.id = const Value.absent(),
    required int senderId,
    required int groupChatId,
    required String message,
    required DateTime createdAt,
  }) : senderId = Value(senderId),
       groupChatId = Value(groupChatId),
       message = Value(message),
       createdAt = Value(createdAt);
  static Insertable<GroupChatHistoryData> custom({
    Expression<int>? id,
    Expression<int>? senderId,
    Expression<int>? groupChatId,
    Expression<String>? message,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (senderId != null) 'sender_id': senderId,
      if (groupChatId != null) 'group_chat_id': groupChatId,
      if (message != null) 'message': message,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  GroupChatHistoryCompanion copyWith({
    Value<int>? id,
    Value<int>? senderId,
    Value<int>? groupChatId,
    Value<String>? message,
    Value<DateTime>? createdAt,
  }) {
    return GroupChatHistoryCompanion(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      groupChatId: groupChatId ?? this.groupChatId,
      message: message ?? this.message,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (senderId.present) {
      map['sender_id'] = Variable<int>(senderId.value);
    }
    if (groupChatId.present) {
      map['group_chat_id'] = Variable<int>(groupChatId.value);
    }
    if (message.present) {
      map['message'] = Variable<String>(message.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('GroupChatHistoryCompanion(')
          ..write('id: $id, ')
          ..write('senderId: $senderId, ')
          ..write('groupChatId: $groupChatId, ')
          ..write('message: $message, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $OpenChatsTable extends OpenChats
    with TableInfo<$OpenChatsTable, OpenChat> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $OpenChatsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _localIdMeta = const VerificationMeta(
    'localId',
  );
  @override
  late final GeneratedColumn<int> localId = GeneratedColumn<int>(
    'local_id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _isGroupChatMeta = const VerificationMeta(
    'isGroupChat',
  );
  @override
  late final GeneratedColumn<bool> isGroupChat = GeneratedColumn<bool>(
    'is_group_chat',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_group_chat" IN (0, 1))',
    ),
  );
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
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
    requiredDuringInsert: false,
    defaultValue: const Constant('New'),
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
  @override
  List<GeneratedColumn> get $columns => [
    localId,
    isGroupChat,
    id,
    username,
    avatarUrl,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'open_chats';
  @override
  VerificationContext validateIntegrity(
    Insertable<OpenChat> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('local_id')) {
      context.handle(
        _localIdMeta,
        localId.isAcceptableOrUnknown(data['local_id']!, _localIdMeta),
      );
    }
    if (data.containsKey('is_group_chat')) {
      context.handle(
        _isGroupChatMeta,
        isGroupChat.isAcceptableOrUnknown(
          data['is_group_chat']!,
          _isGroupChatMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_isGroupChatMeta);
    }
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('username')) {
      context.handle(
        _usernameMeta,
        username.isAcceptableOrUnknown(data['username']!, _usernameMeta),
      );
    }
    if (data.containsKey('avatar_url')) {
      context.handle(
        _avatarUrlMeta,
        avatarUrl.isAcceptableOrUnknown(data['avatar_url']!, _avatarUrlMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {localId};
  @override
  OpenChat map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return OpenChat(
      localId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}local_id'],
      )!,
      isGroupChat: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_group_chat'],
      )!,
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      username: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}username'],
      )!,
      avatarUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}avatar_url'],
      ),
    );
  }

  @override
  $OpenChatsTable createAlias(String alias) {
    return $OpenChatsTable(attachedDatabase, alias);
  }
}

class OpenChat extends DataClass implements Insertable<OpenChat> {
  final int localId;
  final bool isGroupChat;
  final int id;
  final String username;
  final String? avatarUrl;
  const OpenChat({
    required this.localId,
    required this.isGroupChat,
    required this.id,
    required this.username,
    this.avatarUrl,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['local_id'] = Variable<int>(localId);
    map['is_group_chat'] = Variable<bool>(isGroupChat);
    map['id'] = Variable<int>(id);
    map['username'] = Variable<String>(username);
    if (!nullToAbsent || avatarUrl != null) {
      map['avatar_url'] = Variable<String>(avatarUrl);
    }
    return map;
  }

  OpenChatsCompanion toCompanion(bool nullToAbsent) {
    return OpenChatsCompanion(
      localId: Value(localId),
      isGroupChat: Value(isGroupChat),
      id: Value(id),
      username: Value(username),
      avatarUrl: avatarUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(avatarUrl),
    );
  }

  factory OpenChat.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return OpenChat(
      localId: serializer.fromJson<int>(json['localId']),
      isGroupChat: serializer.fromJson<bool>(json['isGroupChat']),
      id: serializer.fromJson<int>(json['id']),
      username: serializer.fromJson<String>(json['username']),
      avatarUrl: serializer.fromJson<String?>(json['avatarUrl']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'localId': serializer.toJson<int>(localId),
      'isGroupChat': serializer.toJson<bool>(isGroupChat),
      'id': serializer.toJson<int>(id),
      'username': serializer.toJson<String>(username),
      'avatarUrl': serializer.toJson<String?>(avatarUrl),
    };
  }

  OpenChat copyWith({
    int? localId,
    bool? isGroupChat,
    int? id,
    String? username,
    Value<String?> avatarUrl = const Value.absent(),
  }) => OpenChat(
    localId: localId ?? this.localId,
    isGroupChat: isGroupChat ?? this.isGroupChat,
    id: id ?? this.id,
    username: username ?? this.username,
    avatarUrl: avatarUrl.present ? avatarUrl.value : this.avatarUrl,
  );
  OpenChat copyWithCompanion(OpenChatsCompanion data) {
    return OpenChat(
      localId: data.localId.present ? data.localId.value : this.localId,
      isGroupChat: data.isGroupChat.present
          ? data.isGroupChat.value
          : this.isGroupChat,
      id: data.id.present ? data.id.value : this.id,
      username: data.username.present ? data.username.value : this.username,
      avatarUrl: data.avatarUrl.present ? data.avatarUrl.value : this.avatarUrl,
    );
  }

  @override
  String toString() {
    return (StringBuffer('OpenChat(')
          ..write('localId: $localId, ')
          ..write('isGroupChat: $isGroupChat, ')
          ..write('id: $id, ')
          ..write('username: $username, ')
          ..write('avatarUrl: $avatarUrl')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(localId, isGroupChat, id, username, avatarUrl);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is OpenChat &&
          other.localId == this.localId &&
          other.isGroupChat == this.isGroupChat &&
          other.id == this.id &&
          other.username == this.username &&
          other.avatarUrl == this.avatarUrl);
}

class OpenChatsCompanion extends UpdateCompanion<OpenChat> {
  final Value<int> localId;
  final Value<bool> isGroupChat;
  final Value<int> id;
  final Value<String> username;
  final Value<String?> avatarUrl;
  const OpenChatsCompanion({
    this.localId = const Value.absent(),
    this.isGroupChat = const Value.absent(),
    this.id = const Value.absent(),
    this.username = const Value.absent(),
    this.avatarUrl = const Value.absent(),
  });
  OpenChatsCompanion.insert({
    this.localId = const Value.absent(),
    required bool isGroupChat,
    required int id,
    this.username = const Value.absent(),
    this.avatarUrl = const Value.absent(),
  }) : isGroupChat = Value(isGroupChat),
       id = Value(id);
  static Insertable<OpenChat> custom({
    Expression<int>? localId,
    Expression<bool>? isGroupChat,
    Expression<int>? id,
    Expression<String>? username,
    Expression<String>? avatarUrl,
  }) {
    return RawValuesInsertable({
      if (localId != null) 'local_id': localId,
      if (isGroupChat != null) 'is_group_chat': isGroupChat,
      if (id != null) 'id': id,
      if (username != null) 'username': username,
      if (avatarUrl != null) 'avatar_url': avatarUrl,
    });
  }

  OpenChatsCompanion copyWith({
    Value<int>? localId,
    Value<bool>? isGroupChat,
    Value<int>? id,
    Value<String>? username,
    Value<String?>? avatarUrl,
  }) {
    return OpenChatsCompanion(
      localId: localId ?? this.localId,
      isGroupChat: isGroupChat ?? this.isGroupChat,
      id: id ?? this.id,
      username: username ?? this.username,
      avatarUrl: avatarUrl ?? this.avatarUrl,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (localId.present) {
      map['local_id'] = Variable<int>(localId.value);
    }
    if (isGroupChat.present) {
      map['is_group_chat'] = Variable<bool>(isGroupChat.value);
    }
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (username.present) {
      map['username'] = Variable<String>(username.value);
    }
    if (avatarUrl.present) {
      map['avatar_url'] = Variable<String>(avatarUrl.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('OpenChatsCompanion(')
          ..write('localId: $localId, ')
          ..write('isGroupChat: $isGroupChat, ')
          ..write('id: $id, ')
          ..write('username: $username, ')
          ..write('avatarUrl: $avatarUrl')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $UserSearchHistoryTable userSearchHistory =
      $UserSearchHistoryTable(this);
  late final $DmChatHistoryTable dmChatHistory = $DmChatHistoryTable(this);
  late final $GroupChatHistoryTable groupChatHistory = $GroupChatHistoryTable(
    this,
  );
  late final $OpenChatsTable openChats = $OpenChatsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    userSearchHistory,
    dmChatHistory,
    groupChatHistory,
    openChats,
  ];
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
typedef $$DmChatHistoryTableCreateCompanionBuilder =
    DmChatHistoryCompanion Function({
      Value<int> id,
      required int senderId,
      required int recipientId,
      required String message,
      required DateTime createdAt,
    });
typedef $$DmChatHistoryTableUpdateCompanionBuilder =
    DmChatHistoryCompanion Function({
      Value<int> id,
      Value<int> senderId,
      Value<int> recipientId,
      Value<String> message,
      Value<DateTime> createdAt,
    });

class $$DmChatHistoryTableFilterComposer
    extends Composer<_$AppDatabase, $DmChatHistoryTable> {
  $$DmChatHistoryTableFilterComposer({
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

  ColumnFilters<int> get senderId => $composableBuilder(
    column: $table.senderId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get recipientId => $composableBuilder(
    column: $table.recipientId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get message => $composableBuilder(
    column: $table.message,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$DmChatHistoryTableOrderingComposer
    extends Composer<_$AppDatabase, $DmChatHistoryTable> {
  $$DmChatHistoryTableOrderingComposer({
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

  ColumnOrderings<int> get senderId => $composableBuilder(
    column: $table.senderId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get recipientId => $composableBuilder(
    column: $table.recipientId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get message => $composableBuilder(
    column: $table.message,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$DmChatHistoryTableAnnotationComposer
    extends Composer<_$AppDatabase, $DmChatHistoryTable> {
  $$DmChatHistoryTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get senderId =>
      $composableBuilder(column: $table.senderId, builder: (column) => column);

  GeneratedColumn<int> get recipientId => $composableBuilder(
    column: $table.recipientId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get message =>
      $composableBuilder(column: $table.message, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$DmChatHistoryTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $DmChatHistoryTable,
          DmChatHistoryData,
          $$DmChatHistoryTableFilterComposer,
          $$DmChatHistoryTableOrderingComposer,
          $$DmChatHistoryTableAnnotationComposer,
          $$DmChatHistoryTableCreateCompanionBuilder,
          $$DmChatHistoryTableUpdateCompanionBuilder,
          (
            DmChatHistoryData,
            BaseReferences<
              _$AppDatabase,
              $DmChatHistoryTable,
              DmChatHistoryData
            >,
          ),
          DmChatHistoryData,
          PrefetchHooks Function()
        > {
  $$DmChatHistoryTableTableManager(_$AppDatabase db, $DmChatHistoryTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DmChatHistoryTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DmChatHistoryTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DmChatHistoryTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> senderId = const Value.absent(),
                Value<int> recipientId = const Value.absent(),
                Value<String> message = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => DmChatHistoryCompanion(
                id: id,
                senderId: senderId,
                recipientId: recipientId,
                message: message,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int senderId,
                required int recipientId,
                required String message,
                required DateTime createdAt,
              }) => DmChatHistoryCompanion.insert(
                id: id,
                senderId: senderId,
                recipientId: recipientId,
                message: message,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$DmChatHistoryTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $DmChatHistoryTable,
      DmChatHistoryData,
      $$DmChatHistoryTableFilterComposer,
      $$DmChatHistoryTableOrderingComposer,
      $$DmChatHistoryTableAnnotationComposer,
      $$DmChatHistoryTableCreateCompanionBuilder,
      $$DmChatHistoryTableUpdateCompanionBuilder,
      (
        DmChatHistoryData,
        BaseReferences<_$AppDatabase, $DmChatHistoryTable, DmChatHistoryData>,
      ),
      DmChatHistoryData,
      PrefetchHooks Function()
    >;
typedef $$GroupChatHistoryTableCreateCompanionBuilder =
    GroupChatHistoryCompanion Function({
      Value<int> id,
      required int senderId,
      required int groupChatId,
      required String message,
      required DateTime createdAt,
    });
typedef $$GroupChatHistoryTableUpdateCompanionBuilder =
    GroupChatHistoryCompanion Function({
      Value<int> id,
      Value<int> senderId,
      Value<int> groupChatId,
      Value<String> message,
      Value<DateTime> createdAt,
    });

class $$GroupChatHistoryTableFilterComposer
    extends Composer<_$AppDatabase, $GroupChatHistoryTable> {
  $$GroupChatHistoryTableFilterComposer({
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

  ColumnFilters<int> get senderId => $composableBuilder(
    column: $table.senderId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get groupChatId => $composableBuilder(
    column: $table.groupChatId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get message => $composableBuilder(
    column: $table.message,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$GroupChatHistoryTableOrderingComposer
    extends Composer<_$AppDatabase, $GroupChatHistoryTable> {
  $$GroupChatHistoryTableOrderingComposer({
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

  ColumnOrderings<int> get senderId => $composableBuilder(
    column: $table.senderId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get groupChatId => $composableBuilder(
    column: $table.groupChatId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get message => $composableBuilder(
    column: $table.message,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$GroupChatHistoryTableAnnotationComposer
    extends Composer<_$AppDatabase, $GroupChatHistoryTable> {
  $$GroupChatHistoryTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get senderId =>
      $composableBuilder(column: $table.senderId, builder: (column) => column);

  GeneratedColumn<int> get groupChatId => $composableBuilder(
    column: $table.groupChatId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get message =>
      $composableBuilder(column: $table.message, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$GroupChatHistoryTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $GroupChatHistoryTable,
          GroupChatHistoryData,
          $$GroupChatHistoryTableFilterComposer,
          $$GroupChatHistoryTableOrderingComposer,
          $$GroupChatHistoryTableAnnotationComposer,
          $$GroupChatHistoryTableCreateCompanionBuilder,
          $$GroupChatHistoryTableUpdateCompanionBuilder,
          (
            GroupChatHistoryData,
            BaseReferences<
              _$AppDatabase,
              $GroupChatHistoryTable,
              GroupChatHistoryData
            >,
          ),
          GroupChatHistoryData,
          PrefetchHooks Function()
        > {
  $$GroupChatHistoryTableTableManager(
    _$AppDatabase db,
    $GroupChatHistoryTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$GroupChatHistoryTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$GroupChatHistoryTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$GroupChatHistoryTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> senderId = const Value.absent(),
                Value<int> groupChatId = const Value.absent(),
                Value<String> message = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => GroupChatHistoryCompanion(
                id: id,
                senderId: senderId,
                groupChatId: groupChatId,
                message: message,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int senderId,
                required int groupChatId,
                required String message,
                required DateTime createdAt,
              }) => GroupChatHistoryCompanion.insert(
                id: id,
                senderId: senderId,
                groupChatId: groupChatId,
                message: message,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$GroupChatHistoryTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $GroupChatHistoryTable,
      GroupChatHistoryData,
      $$GroupChatHistoryTableFilterComposer,
      $$GroupChatHistoryTableOrderingComposer,
      $$GroupChatHistoryTableAnnotationComposer,
      $$GroupChatHistoryTableCreateCompanionBuilder,
      $$GroupChatHistoryTableUpdateCompanionBuilder,
      (
        GroupChatHistoryData,
        BaseReferences<
          _$AppDatabase,
          $GroupChatHistoryTable,
          GroupChatHistoryData
        >,
      ),
      GroupChatHistoryData,
      PrefetchHooks Function()
    >;
typedef $$OpenChatsTableCreateCompanionBuilder =
    OpenChatsCompanion Function({
      Value<int> localId,
      required bool isGroupChat,
      required int id,
      Value<String> username,
      Value<String?> avatarUrl,
    });
typedef $$OpenChatsTableUpdateCompanionBuilder =
    OpenChatsCompanion Function({
      Value<int> localId,
      Value<bool> isGroupChat,
      Value<int> id,
      Value<String> username,
      Value<String?> avatarUrl,
    });

class $$OpenChatsTableFilterComposer
    extends Composer<_$AppDatabase, $OpenChatsTable> {
  $$OpenChatsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get localId => $composableBuilder(
    column: $table.localId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isGroupChat => $composableBuilder(
    column: $table.isGroupChat,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
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
}

class $$OpenChatsTableOrderingComposer
    extends Composer<_$AppDatabase, $OpenChatsTable> {
  $$OpenChatsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get localId => $composableBuilder(
    column: $table.localId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isGroupChat => $composableBuilder(
    column: $table.isGroupChat,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
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
}

class $$OpenChatsTableAnnotationComposer
    extends Composer<_$AppDatabase, $OpenChatsTable> {
  $$OpenChatsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get localId =>
      $composableBuilder(column: $table.localId, builder: (column) => column);

  GeneratedColumn<bool> get isGroupChat => $composableBuilder(
    column: $table.isGroupChat,
    builder: (column) => column,
  );

  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get username =>
      $composableBuilder(column: $table.username, builder: (column) => column);

  GeneratedColumn<String> get avatarUrl =>
      $composableBuilder(column: $table.avatarUrl, builder: (column) => column);
}

class $$OpenChatsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $OpenChatsTable,
          OpenChat,
          $$OpenChatsTableFilterComposer,
          $$OpenChatsTableOrderingComposer,
          $$OpenChatsTableAnnotationComposer,
          $$OpenChatsTableCreateCompanionBuilder,
          $$OpenChatsTableUpdateCompanionBuilder,
          (OpenChat, BaseReferences<_$AppDatabase, $OpenChatsTable, OpenChat>),
          OpenChat,
          PrefetchHooks Function()
        > {
  $$OpenChatsTableTableManager(_$AppDatabase db, $OpenChatsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$OpenChatsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$OpenChatsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$OpenChatsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> localId = const Value.absent(),
                Value<bool> isGroupChat = const Value.absent(),
                Value<int> id = const Value.absent(),
                Value<String> username = const Value.absent(),
                Value<String?> avatarUrl = const Value.absent(),
              }) => OpenChatsCompanion(
                localId: localId,
                isGroupChat: isGroupChat,
                id: id,
                username: username,
                avatarUrl: avatarUrl,
              ),
          createCompanionCallback:
              ({
                Value<int> localId = const Value.absent(),
                required bool isGroupChat,
                required int id,
                Value<String> username = const Value.absent(),
                Value<String?> avatarUrl = const Value.absent(),
              }) => OpenChatsCompanion.insert(
                localId: localId,
                isGroupChat: isGroupChat,
                id: id,
                username: username,
                avatarUrl: avatarUrl,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$OpenChatsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $OpenChatsTable,
      OpenChat,
      $$OpenChatsTableFilterComposer,
      $$OpenChatsTableOrderingComposer,
      $$OpenChatsTableAnnotationComposer,
      $$OpenChatsTableCreateCompanionBuilder,
      $$OpenChatsTableUpdateCompanionBuilder,
      (OpenChat, BaseReferences<_$AppDatabase, $OpenChatsTable, OpenChat>),
      OpenChat,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$UserSearchHistoryTableTableManager get userSearchHistory =>
      $$UserSearchHistoryTableTableManager(_db, _db.userSearchHistory);
  $$DmChatHistoryTableTableManager get dmChatHistory =>
      $$DmChatHistoryTableTableManager(_db, _db.dmChatHistory);
  $$GroupChatHistoryTableTableManager get groupChatHistory =>
      $$GroupChatHistoryTableTableManager(_db, _db.groupChatHistory);
  $$OpenChatsTableTableManager get openChats =>
      $$OpenChatsTableTableManager(_db, _db.openChats);
}

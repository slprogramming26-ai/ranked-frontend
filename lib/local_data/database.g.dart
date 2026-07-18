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
  static const VerificationMeta _clientMsgIdMeta = const VerificationMeta(
    'clientMsgId',
  );
  @override
  late final GeneratedColumn<String> clientMsgId = GeneratedColumn<String>(
    'client_msg_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    senderId,
    recipientId,
    message,
    createdAt,
    clientMsgId,
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
    if (data.containsKey('client_msg_id')) {
      context.handle(
        _clientMsgIdMeta,
        clientMsgId.isAcceptableOrUnknown(
          data['client_msg_id']!,
          _clientMsgIdMeta,
        ),
      );
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
      clientMsgId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}client_msg_id'],
      ),
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
  final String? clientMsgId;
  const DmChatHistoryData({
    required this.id,
    required this.senderId,
    required this.recipientId,
    required this.message,
    required this.createdAt,
    this.clientMsgId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['sender_id'] = Variable<int>(senderId);
    map['recipient_id'] = Variable<int>(recipientId);
    map['message'] = Variable<String>(message);
    map['created_at'] = Variable<DateTime>(createdAt);
    if (!nullToAbsent || clientMsgId != null) {
      map['client_msg_id'] = Variable<String>(clientMsgId);
    }
    return map;
  }

  DmChatHistoryCompanion toCompanion(bool nullToAbsent) {
    return DmChatHistoryCompanion(
      id: Value(id),
      senderId: Value(senderId),
      recipientId: Value(recipientId),
      message: Value(message),
      createdAt: Value(createdAt),
      clientMsgId: clientMsgId == null && nullToAbsent
          ? const Value.absent()
          : Value(clientMsgId),
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
      clientMsgId: serializer.fromJson<String?>(json['clientMsgId']),
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
      'clientMsgId': serializer.toJson<String?>(clientMsgId),
    };
  }

  DmChatHistoryData copyWith({
    int? id,
    int? senderId,
    int? recipientId,
    String? message,
    DateTime? createdAt,
    Value<String?> clientMsgId = const Value.absent(),
  }) => DmChatHistoryData(
    id: id ?? this.id,
    senderId: senderId ?? this.senderId,
    recipientId: recipientId ?? this.recipientId,
    message: message ?? this.message,
    createdAt: createdAt ?? this.createdAt,
    clientMsgId: clientMsgId.present ? clientMsgId.value : this.clientMsgId,
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
      clientMsgId: data.clientMsgId.present
          ? data.clientMsgId.value
          : this.clientMsgId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DmChatHistoryData(')
          ..write('id: $id, ')
          ..write('senderId: $senderId, ')
          ..write('recipientId: $recipientId, ')
          ..write('message: $message, ')
          ..write('createdAt: $createdAt, ')
          ..write('clientMsgId: $clientMsgId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, senderId, recipientId, message, createdAt, clientMsgId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DmChatHistoryData &&
          other.id == this.id &&
          other.senderId == this.senderId &&
          other.recipientId == this.recipientId &&
          other.message == this.message &&
          other.createdAt == this.createdAt &&
          other.clientMsgId == this.clientMsgId);
}

class DmChatHistoryCompanion extends UpdateCompanion<DmChatHistoryData> {
  final Value<int> id;
  final Value<int> senderId;
  final Value<int> recipientId;
  final Value<String> message;
  final Value<DateTime> createdAt;
  final Value<String?> clientMsgId;
  const DmChatHistoryCompanion({
    this.id = const Value.absent(),
    this.senderId = const Value.absent(),
    this.recipientId = const Value.absent(),
    this.message = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.clientMsgId = const Value.absent(),
  });
  DmChatHistoryCompanion.insert({
    this.id = const Value.absent(),
    required int senderId,
    required int recipientId,
    required String message,
    required DateTime createdAt,
    this.clientMsgId = const Value.absent(),
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
    Expression<String>? clientMsgId,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (senderId != null) 'sender_id': senderId,
      if (recipientId != null) 'recipient_id': recipientId,
      if (message != null) 'message': message,
      if (createdAt != null) 'created_at': createdAt,
      if (clientMsgId != null) 'client_msg_id': clientMsgId,
    });
  }

  DmChatHistoryCompanion copyWith({
    Value<int>? id,
    Value<int>? senderId,
    Value<int>? recipientId,
    Value<String>? message,
    Value<DateTime>? createdAt,
    Value<String?>? clientMsgId,
  }) {
    return DmChatHistoryCompanion(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      recipientId: recipientId ?? this.recipientId,
      message: message ?? this.message,
      createdAt: createdAt ?? this.createdAt,
      clientMsgId: clientMsgId ?? this.clientMsgId,
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
    if (clientMsgId.present) {
      map['client_msg_id'] = Variable<String>(clientMsgId.value);
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
          ..write('createdAt: $createdAt, ')
          ..write('clientMsgId: $clientMsgId')
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
  static const VerificationMeta _clientMsgIdMeta = const VerificationMeta(
    'clientMsgId',
  );
  @override
  late final GeneratedColumn<String> clientMsgId = GeneratedColumn<String>(
    'client_msg_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    senderId,
    groupChatId,
    message,
    createdAt,
    clientMsgId,
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
    if (data.containsKey('client_msg_id')) {
      context.handle(
        _clientMsgIdMeta,
        clientMsgId.isAcceptableOrUnknown(
          data['client_msg_id']!,
          _clientMsgIdMeta,
        ),
      );
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
      clientMsgId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}client_msg_id'],
      ),
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
  final String? clientMsgId;
  const GroupChatHistoryData({
    required this.id,
    required this.senderId,
    required this.groupChatId,
    required this.message,
    required this.createdAt,
    this.clientMsgId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['sender_id'] = Variable<int>(senderId);
    map['group_chat_id'] = Variable<int>(groupChatId);
    map['message'] = Variable<String>(message);
    map['created_at'] = Variable<DateTime>(createdAt);
    if (!nullToAbsent || clientMsgId != null) {
      map['client_msg_id'] = Variable<String>(clientMsgId);
    }
    return map;
  }

  GroupChatHistoryCompanion toCompanion(bool nullToAbsent) {
    return GroupChatHistoryCompanion(
      id: Value(id),
      senderId: Value(senderId),
      groupChatId: Value(groupChatId),
      message: Value(message),
      createdAt: Value(createdAt),
      clientMsgId: clientMsgId == null && nullToAbsent
          ? const Value.absent()
          : Value(clientMsgId),
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
      clientMsgId: serializer.fromJson<String?>(json['clientMsgId']),
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
      'clientMsgId': serializer.toJson<String?>(clientMsgId),
    };
  }

  GroupChatHistoryData copyWith({
    int? id,
    int? senderId,
    int? groupChatId,
    String? message,
    DateTime? createdAt,
    Value<String?> clientMsgId = const Value.absent(),
  }) => GroupChatHistoryData(
    id: id ?? this.id,
    senderId: senderId ?? this.senderId,
    groupChatId: groupChatId ?? this.groupChatId,
    message: message ?? this.message,
    createdAt: createdAt ?? this.createdAt,
    clientMsgId: clientMsgId.present ? clientMsgId.value : this.clientMsgId,
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
      clientMsgId: data.clientMsgId.present
          ? data.clientMsgId.value
          : this.clientMsgId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('GroupChatHistoryData(')
          ..write('id: $id, ')
          ..write('senderId: $senderId, ')
          ..write('groupChatId: $groupChatId, ')
          ..write('message: $message, ')
          ..write('createdAt: $createdAt, ')
          ..write('clientMsgId: $clientMsgId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, senderId, groupChatId, message, createdAt, clientMsgId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is GroupChatHistoryData &&
          other.id == this.id &&
          other.senderId == this.senderId &&
          other.groupChatId == this.groupChatId &&
          other.message == this.message &&
          other.createdAt == this.createdAt &&
          other.clientMsgId == this.clientMsgId);
}

class GroupChatHistoryCompanion extends UpdateCompanion<GroupChatHistoryData> {
  final Value<int> id;
  final Value<int> senderId;
  final Value<int> groupChatId;
  final Value<String> message;
  final Value<DateTime> createdAt;
  final Value<String?> clientMsgId;
  const GroupChatHistoryCompanion({
    this.id = const Value.absent(),
    this.senderId = const Value.absent(),
    this.groupChatId = const Value.absent(),
    this.message = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.clientMsgId = const Value.absent(),
  });
  GroupChatHistoryCompanion.insert({
    this.id = const Value.absent(),
    required int senderId,
    required int groupChatId,
    required String message,
    required DateTime createdAt,
    this.clientMsgId = const Value.absent(),
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
    Expression<String>? clientMsgId,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (senderId != null) 'sender_id': senderId,
      if (groupChatId != null) 'group_chat_id': groupChatId,
      if (message != null) 'message': message,
      if (createdAt != null) 'created_at': createdAt,
      if (clientMsgId != null) 'client_msg_id': clientMsgId,
    });
  }

  GroupChatHistoryCompanion copyWith({
    Value<int>? id,
    Value<int>? senderId,
    Value<int>? groupChatId,
    Value<String>? message,
    Value<DateTime>? createdAt,
    Value<String?>? clientMsgId,
  }) {
    return GroupChatHistoryCompanion(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      groupChatId: groupChatId ?? this.groupChatId,
      message: message ?? this.message,
      createdAt: createdAt ?? this.createdAt,
      clientMsgId: clientMsgId ?? this.clientMsgId,
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
    if (clientMsgId.present) {
      map['client_msg_id'] = Variable<String>(clientMsgId.value);
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
          ..write('createdAt: $createdAt, ')
          ..write('clientMsgId: $clientMsgId')
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
  static const VerificationMeta _isPendingMeta = const VerificationMeta(
    'isPending',
  );
  @override
  late final GeneratedColumn<bool> isPending = GeneratedColumn<bool>(
    'is_pending',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_pending" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    localId,
    isGroupChat,
    id,
    username,
    avatarUrl,
    isPending,
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
    if (data.containsKey('is_pending')) {
      context.handle(
        _isPendingMeta,
        isPending.isAcceptableOrUnknown(data['is_pending']!, _isPendingMeta),
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
      isPending: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_pending'],
      )!,
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
  final bool isPending;
  const OpenChat({
    required this.localId,
    required this.isGroupChat,
    required this.id,
    required this.username,
    this.avatarUrl,
    required this.isPending,
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
    map['is_pending'] = Variable<bool>(isPending);
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
      isPending: Value(isPending),
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
      isPending: serializer.fromJson<bool>(json['isPending']),
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
      'isPending': serializer.toJson<bool>(isPending),
    };
  }

  OpenChat copyWith({
    int? localId,
    bool? isGroupChat,
    int? id,
    String? username,
    Value<String?> avatarUrl = const Value.absent(),
    bool? isPending,
  }) => OpenChat(
    localId: localId ?? this.localId,
    isGroupChat: isGroupChat ?? this.isGroupChat,
    id: id ?? this.id,
    username: username ?? this.username,
    avatarUrl: avatarUrl.present ? avatarUrl.value : this.avatarUrl,
    isPending: isPending ?? this.isPending,
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
      isPending: data.isPending.present ? data.isPending.value : this.isPending,
    );
  }

  @override
  String toString() {
    return (StringBuffer('OpenChat(')
          ..write('localId: $localId, ')
          ..write('isGroupChat: $isGroupChat, ')
          ..write('id: $id, ')
          ..write('username: $username, ')
          ..write('avatarUrl: $avatarUrl, ')
          ..write('isPending: $isPending')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(localId, isGroupChat, id, username, avatarUrl, isPending);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is OpenChat &&
          other.localId == this.localId &&
          other.isGroupChat == this.isGroupChat &&
          other.id == this.id &&
          other.username == this.username &&
          other.avatarUrl == this.avatarUrl &&
          other.isPending == this.isPending);
}

class OpenChatsCompanion extends UpdateCompanion<OpenChat> {
  final Value<int> localId;
  final Value<bool> isGroupChat;
  final Value<int> id;
  final Value<String> username;
  final Value<String?> avatarUrl;
  final Value<bool> isPending;
  const OpenChatsCompanion({
    this.localId = const Value.absent(),
    this.isGroupChat = const Value.absent(),
    this.id = const Value.absent(),
    this.username = const Value.absent(),
    this.avatarUrl = const Value.absent(),
    this.isPending = const Value.absent(),
  });
  OpenChatsCompanion.insert({
    this.localId = const Value.absent(),
    required bool isGroupChat,
    required int id,
    this.username = const Value.absent(),
    this.avatarUrl = const Value.absent(),
    this.isPending = const Value.absent(),
  }) : isGroupChat = Value(isGroupChat),
       id = Value(id);
  static Insertable<OpenChat> custom({
    Expression<int>? localId,
    Expression<bool>? isGroupChat,
    Expression<int>? id,
    Expression<String>? username,
    Expression<String>? avatarUrl,
    Expression<bool>? isPending,
  }) {
    return RawValuesInsertable({
      if (localId != null) 'local_id': localId,
      if (isGroupChat != null) 'is_group_chat': isGroupChat,
      if (id != null) 'id': id,
      if (username != null) 'username': username,
      if (avatarUrl != null) 'avatar_url': avatarUrl,
      if (isPending != null) 'is_pending': isPending,
    });
  }

  OpenChatsCompanion copyWith({
    Value<int>? localId,
    Value<bool>? isGroupChat,
    Value<int>? id,
    Value<String>? username,
    Value<String?>? avatarUrl,
    Value<bool>? isPending,
  }) {
    return OpenChatsCompanion(
      localId: localId ?? this.localId,
      isGroupChat: isGroupChat ?? this.isGroupChat,
      id: id ?? this.id,
      username: username ?? this.username,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      isPending: isPending ?? this.isPending,
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
    if (isPending.present) {
      map['is_pending'] = Variable<bool>(isPending.value);
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
          ..write('avatarUrl: $avatarUrl, ')
          ..write('isPending: $isPending')
          ..write(')'))
        .toString();
  }
}

class $SyncMarkersTable extends SyncMarkers
    with TableInfo<$SyncMarkersTable, SyncMarker> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncMarkersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lastSyncedAtMeta = const VerificationMeta(
    'lastSyncedAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastSyncedAt = GeneratedColumn<DateTime>(
    'last_synced_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [key, lastSyncedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_markers';
  @override
  VerificationContext validateIntegrity(
    Insertable<SyncMarker> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('last_synced_at')) {
      context.handle(
        _lastSyncedAtMeta,
        lastSyncedAt.isAcceptableOrUnknown(
          data['last_synced_at']!,
          _lastSyncedAtMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  SyncMarker map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncMarker(
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      lastSyncedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_synced_at'],
      ),
    );
  }

  @override
  $SyncMarkersTable createAlias(String alias) {
    return $SyncMarkersTable(attachedDatabase, alias);
  }
}

class SyncMarker extends DataClass implements Insertable<SyncMarker> {
  final String key;
  final DateTime? lastSyncedAt;
  const SyncMarker({required this.key, this.lastSyncedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    if (!nullToAbsent || lastSyncedAt != null) {
      map['last_synced_at'] = Variable<DateTime>(lastSyncedAt);
    }
    return map;
  }

  SyncMarkersCompanion toCompanion(bool nullToAbsent) {
    return SyncMarkersCompanion(
      key: Value(key),
      lastSyncedAt: lastSyncedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastSyncedAt),
    );
  }

  factory SyncMarker.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncMarker(
      key: serializer.fromJson<String>(json['key']),
      lastSyncedAt: serializer.fromJson<DateTime?>(json['lastSyncedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'lastSyncedAt': serializer.toJson<DateTime?>(lastSyncedAt),
    };
  }

  SyncMarker copyWith({
    String? key,
    Value<DateTime?> lastSyncedAt = const Value.absent(),
  }) => SyncMarker(
    key: key ?? this.key,
    lastSyncedAt: lastSyncedAt.present ? lastSyncedAt.value : this.lastSyncedAt,
  );
  SyncMarker copyWithCompanion(SyncMarkersCompanion data) {
    return SyncMarker(
      key: data.key.present ? data.key.value : this.key,
      lastSyncedAt: data.lastSyncedAt.present
          ? data.lastSyncedAt.value
          : this.lastSyncedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncMarker(')
          ..write('key: $key, ')
          ..write('lastSyncedAt: $lastSyncedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, lastSyncedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncMarker &&
          other.key == this.key &&
          other.lastSyncedAt == this.lastSyncedAt);
}

class SyncMarkersCompanion extends UpdateCompanion<SyncMarker> {
  final Value<String> key;
  final Value<DateTime?> lastSyncedAt;
  final Value<int> rowid;
  const SyncMarkersCompanion({
    this.key = const Value.absent(),
    this.lastSyncedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SyncMarkersCompanion.insert({
    required String key,
    this.lastSyncedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : key = Value(key);
  static Insertable<SyncMarker> custom({
    Expression<String>? key,
    Expression<DateTime>? lastSyncedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (lastSyncedAt != null) 'last_synced_at': lastSyncedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SyncMarkersCompanion copyWith({
    Value<String>? key,
    Value<DateTime?>? lastSyncedAt,
    Value<int>? rowid,
  }) {
    return SyncMarkersCompanion(
      key: key ?? this.key,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (lastSyncedAt.present) {
      map['last_synced_at'] = Variable<DateTime>(lastSyncedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncMarkersCompanion(')
          ..write('key: $key, ')
          ..write('lastSyncedAt: $lastSyncedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PostDraftsTable extends PostDrafts
    with TableInfo<$PostDraftsTable, PostDraft> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PostDraftsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _draftTypeMeta = const VerificationMeta(
    'draftType',
  );
  @override
  late final GeneratedColumn<String> draftType = GeneratedColumn<String>(
    'draft_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('post'),
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _contentMeta = const VerificationMeta(
    'content',
  );
  @override
  late final GeneratedColumn<String> content = GeneratedColumn<String>(
    'content',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _tagMeta = const VerificationMeta('tag');
  @override
  late final GeneratedColumn<String> tag = GeneratedColumn<String>(
    'tag',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isPublicMeta = const VerificationMeta(
    'isPublic',
  );
  @override
  late final GeneratedColumn<bool> isPublic = GeneratedColumn<bool>(
    'is_public',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_public" IN (0, 1))',
    ),
  );
  static const VerificationMeta _imagePathMeta = const VerificationMeta(
    'imagePath',
  );
  @override
  late final GeneratedColumn<String> imagePath = GeneratedColumn<String>(
    'image_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _savedAtMeta = const VerificationMeta(
    'savedAt',
  );
  @override
  late final GeneratedColumn<DateTime> savedAt = GeneratedColumn<DateTime>(
    'saved_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    draftType,
    title,
    content,
    tag,
    isPublic,
    imagePath,
    savedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'post_drafts';
  @override
  VerificationContext validateIntegrity(
    Insertable<PostDraft> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('draft_type')) {
      context.handle(
        _draftTypeMeta,
        draftType.isAcceptableOrUnknown(data['draft_type']!, _draftTypeMeta),
      );
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('content')) {
      context.handle(
        _contentMeta,
        content.isAcceptableOrUnknown(data['content']!, _contentMeta),
      );
    } else if (isInserting) {
      context.missing(_contentMeta);
    }
    if (data.containsKey('tag')) {
      context.handle(
        _tagMeta,
        tag.isAcceptableOrUnknown(data['tag']!, _tagMeta),
      );
    }
    if (data.containsKey('is_public')) {
      context.handle(
        _isPublicMeta,
        isPublic.isAcceptableOrUnknown(data['is_public']!, _isPublicMeta),
      );
    } else if (isInserting) {
      context.missing(_isPublicMeta);
    }
    if (data.containsKey('image_path')) {
      context.handle(
        _imagePathMeta,
        imagePath.isAcceptableOrUnknown(data['image_path']!, _imagePathMeta),
      );
    }
    if (data.containsKey('saved_at')) {
      context.handle(
        _savedAtMeta,
        savedAt.isAcceptableOrUnknown(data['saved_at']!, _savedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_savedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PostDraft map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PostDraft(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      draftType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}draft_type'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      content: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}content'],
      )!,
      tag: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tag'],
      ),
      isPublic: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_public'],
      )!,
      imagePath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}image_path'],
      ),
      savedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}saved_at'],
      )!,
    );
  }

  @override
  $PostDraftsTable createAlias(String alias) {
    return $PostDraftsTable(attachedDatabase, alias);
  }
}

class PostDraft extends DataClass implements Insertable<PostDraft> {
  final int id;
  final String draftType;
  final String title;
  final String content;
  final String? tag;
  final bool isPublic;
  final String? imagePath;
  final DateTime savedAt;
  const PostDraft({
    required this.id,
    required this.draftType,
    required this.title,
    required this.content,
    this.tag,
    required this.isPublic,
    this.imagePath,
    required this.savedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['draft_type'] = Variable<String>(draftType);
    map['title'] = Variable<String>(title);
    map['content'] = Variable<String>(content);
    if (!nullToAbsent || tag != null) {
      map['tag'] = Variable<String>(tag);
    }
    map['is_public'] = Variable<bool>(isPublic);
    if (!nullToAbsent || imagePath != null) {
      map['image_path'] = Variable<String>(imagePath);
    }
    map['saved_at'] = Variable<DateTime>(savedAt);
    return map;
  }

  PostDraftsCompanion toCompanion(bool nullToAbsent) {
    return PostDraftsCompanion(
      id: Value(id),
      draftType: Value(draftType),
      title: Value(title),
      content: Value(content),
      tag: tag == null && nullToAbsent ? const Value.absent() : Value(tag),
      isPublic: Value(isPublic),
      imagePath: imagePath == null && nullToAbsent
          ? const Value.absent()
          : Value(imagePath),
      savedAt: Value(savedAt),
    );
  }

  factory PostDraft.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PostDraft(
      id: serializer.fromJson<int>(json['id']),
      draftType: serializer.fromJson<String>(json['draftType']),
      title: serializer.fromJson<String>(json['title']),
      content: serializer.fromJson<String>(json['content']),
      tag: serializer.fromJson<String?>(json['tag']),
      isPublic: serializer.fromJson<bool>(json['isPublic']),
      imagePath: serializer.fromJson<String?>(json['imagePath']),
      savedAt: serializer.fromJson<DateTime>(json['savedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'draftType': serializer.toJson<String>(draftType),
      'title': serializer.toJson<String>(title),
      'content': serializer.toJson<String>(content),
      'tag': serializer.toJson<String?>(tag),
      'isPublic': serializer.toJson<bool>(isPublic),
      'imagePath': serializer.toJson<String?>(imagePath),
      'savedAt': serializer.toJson<DateTime>(savedAt),
    };
  }

  PostDraft copyWith({
    int? id,
    String? draftType,
    String? title,
    String? content,
    Value<String?> tag = const Value.absent(),
    bool? isPublic,
    Value<String?> imagePath = const Value.absent(),
    DateTime? savedAt,
  }) => PostDraft(
    id: id ?? this.id,
    draftType: draftType ?? this.draftType,
    title: title ?? this.title,
    content: content ?? this.content,
    tag: tag.present ? tag.value : this.tag,
    isPublic: isPublic ?? this.isPublic,
    imagePath: imagePath.present ? imagePath.value : this.imagePath,
    savedAt: savedAt ?? this.savedAt,
  );
  PostDraft copyWithCompanion(PostDraftsCompanion data) {
    return PostDraft(
      id: data.id.present ? data.id.value : this.id,
      draftType: data.draftType.present ? data.draftType.value : this.draftType,
      title: data.title.present ? data.title.value : this.title,
      content: data.content.present ? data.content.value : this.content,
      tag: data.tag.present ? data.tag.value : this.tag,
      isPublic: data.isPublic.present ? data.isPublic.value : this.isPublic,
      imagePath: data.imagePath.present ? data.imagePath.value : this.imagePath,
      savedAt: data.savedAt.present ? data.savedAt.value : this.savedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PostDraft(')
          ..write('id: $id, ')
          ..write('draftType: $draftType, ')
          ..write('title: $title, ')
          ..write('content: $content, ')
          ..write('tag: $tag, ')
          ..write('isPublic: $isPublic, ')
          ..write('imagePath: $imagePath, ')
          ..write('savedAt: $savedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    draftType,
    title,
    content,
    tag,
    isPublic,
    imagePath,
    savedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PostDraft &&
          other.id == this.id &&
          other.draftType == this.draftType &&
          other.title == this.title &&
          other.content == this.content &&
          other.tag == this.tag &&
          other.isPublic == this.isPublic &&
          other.imagePath == this.imagePath &&
          other.savedAt == this.savedAt);
}

class PostDraftsCompanion extends UpdateCompanion<PostDraft> {
  final Value<int> id;
  final Value<String> draftType;
  final Value<String> title;
  final Value<String> content;
  final Value<String?> tag;
  final Value<bool> isPublic;
  final Value<String?> imagePath;
  final Value<DateTime> savedAt;
  const PostDraftsCompanion({
    this.id = const Value.absent(),
    this.draftType = const Value.absent(),
    this.title = const Value.absent(),
    this.content = const Value.absent(),
    this.tag = const Value.absent(),
    this.isPublic = const Value.absent(),
    this.imagePath = const Value.absent(),
    this.savedAt = const Value.absent(),
  });
  PostDraftsCompanion.insert({
    this.id = const Value.absent(),
    this.draftType = const Value.absent(),
    required String title,
    required String content,
    this.tag = const Value.absent(),
    required bool isPublic,
    this.imagePath = const Value.absent(),
    required DateTime savedAt,
  }) : title = Value(title),
       content = Value(content),
       isPublic = Value(isPublic),
       savedAt = Value(savedAt);
  static Insertable<PostDraft> custom({
    Expression<int>? id,
    Expression<String>? draftType,
    Expression<String>? title,
    Expression<String>? content,
    Expression<String>? tag,
    Expression<bool>? isPublic,
    Expression<String>? imagePath,
    Expression<DateTime>? savedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (draftType != null) 'draft_type': draftType,
      if (title != null) 'title': title,
      if (content != null) 'content': content,
      if (tag != null) 'tag': tag,
      if (isPublic != null) 'is_public': isPublic,
      if (imagePath != null) 'image_path': imagePath,
      if (savedAt != null) 'saved_at': savedAt,
    });
  }

  PostDraftsCompanion copyWith({
    Value<int>? id,
    Value<String>? draftType,
    Value<String>? title,
    Value<String>? content,
    Value<String?>? tag,
    Value<bool>? isPublic,
    Value<String?>? imagePath,
    Value<DateTime>? savedAt,
  }) {
    return PostDraftsCompanion(
      id: id ?? this.id,
      draftType: draftType ?? this.draftType,
      title: title ?? this.title,
      content: content ?? this.content,
      tag: tag ?? this.tag,
      isPublic: isPublic ?? this.isPublic,
      imagePath: imagePath ?? this.imagePath,
      savedAt: savedAt ?? this.savedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (draftType.present) {
      map['draft_type'] = Variable<String>(draftType.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (content.present) {
      map['content'] = Variable<String>(content.value);
    }
    if (tag.present) {
      map['tag'] = Variable<String>(tag.value);
    }
    if (isPublic.present) {
      map['is_public'] = Variable<bool>(isPublic.value);
    }
    if (imagePath.present) {
      map['image_path'] = Variable<String>(imagePath.value);
    }
    if (savedAt.present) {
      map['saved_at'] = Variable<DateTime>(savedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PostDraftsCompanion(')
          ..write('id: $id, ')
          ..write('draftType: $draftType, ')
          ..write('title: $title, ')
          ..write('content: $content, ')
          ..write('tag: $tag, ')
          ..write('isPublic: $isPublic, ')
          ..write('imagePath: $imagePath, ')
          ..write('savedAt: $savedAt')
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
  late final $SyncMarkersTable syncMarkers = $SyncMarkersTable(this);
  late final $PostDraftsTable postDrafts = $PostDraftsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    userSearchHistory,
    dmChatHistory,
    groupChatHistory,
    openChats,
    syncMarkers,
    postDrafts,
  ];
  @override
  DriftDatabaseOptions get options =>
      const DriftDatabaseOptions(storeDateTimeAsText: true);
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
      Value<String?> clientMsgId,
    });
typedef $$DmChatHistoryTableUpdateCompanionBuilder =
    DmChatHistoryCompanion Function({
      Value<int> id,
      Value<int> senderId,
      Value<int> recipientId,
      Value<String> message,
      Value<DateTime> createdAt,
      Value<String?> clientMsgId,
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

  ColumnFilters<String> get clientMsgId => $composableBuilder(
    column: $table.clientMsgId,
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

  ColumnOrderings<String> get clientMsgId => $composableBuilder(
    column: $table.clientMsgId,
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

  GeneratedColumn<String> get clientMsgId => $composableBuilder(
    column: $table.clientMsgId,
    builder: (column) => column,
  );
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
                Value<String?> clientMsgId = const Value.absent(),
              }) => DmChatHistoryCompanion(
                id: id,
                senderId: senderId,
                recipientId: recipientId,
                message: message,
                createdAt: createdAt,
                clientMsgId: clientMsgId,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int senderId,
                required int recipientId,
                required String message,
                required DateTime createdAt,
                Value<String?> clientMsgId = const Value.absent(),
              }) => DmChatHistoryCompanion.insert(
                id: id,
                senderId: senderId,
                recipientId: recipientId,
                message: message,
                createdAt: createdAt,
                clientMsgId: clientMsgId,
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
      Value<String?> clientMsgId,
    });
typedef $$GroupChatHistoryTableUpdateCompanionBuilder =
    GroupChatHistoryCompanion Function({
      Value<int> id,
      Value<int> senderId,
      Value<int> groupChatId,
      Value<String> message,
      Value<DateTime> createdAt,
      Value<String?> clientMsgId,
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

  ColumnFilters<String> get clientMsgId => $composableBuilder(
    column: $table.clientMsgId,
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

  ColumnOrderings<String> get clientMsgId => $composableBuilder(
    column: $table.clientMsgId,
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

  GeneratedColumn<String> get clientMsgId => $composableBuilder(
    column: $table.clientMsgId,
    builder: (column) => column,
  );
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
                Value<String?> clientMsgId = const Value.absent(),
              }) => GroupChatHistoryCompanion(
                id: id,
                senderId: senderId,
                groupChatId: groupChatId,
                message: message,
                createdAt: createdAt,
                clientMsgId: clientMsgId,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int senderId,
                required int groupChatId,
                required String message,
                required DateTime createdAt,
                Value<String?> clientMsgId = const Value.absent(),
              }) => GroupChatHistoryCompanion.insert(
                id: id,
                senderId: senderId,
                groupChatId: groupChatId,
                message: message,
                createdAt: createdAt,
                clientMsgId: clientMsgId,
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
      Value<bool> isPending,
    });
typedef $$OpenChatsTableUpdateCompanionBuilder =
    OpenChatsCompanion Function({
      Value<int> localId,
      Value<bool> isGroupChat,
      Value<int> id,
      Value<String> username,
      Value<String?> avatarUrl,
      Value<bool> isPending,
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

  ColumnFilters<bool> get isPending => $composableBuilder(
    column: $table.isPending,
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

  ColumnOrderings<bool> get isPending => $composableBuilder(
    column: $table.isPending,
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

  GeneratedColumn<bool> get isPending =>
      $composableBuilder(column: $table.isPending, builder: (column) => column);
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
                Value<bool> isPending = const Value.absent(),
              }) => OpenChatsCompanion(
                localId: localId,
                isGroupChat: isGroupChat,
                id: id,
                username: username,
                avatarUrl: avatarUrl,
                isPending: isPending,
              ),
          createCompanionCallback:
              ({
                Value<int> localId = const Value.absent(),
                required bool isGroupChat,
                required int id,
                Value<String> username = const Value.absent(),
                Value<String?> avatarUrl = const Value.absent(),
                Value<bool> isPending = const Value.absent(),
              }) => OpenChatsCompanion.insert(
                localId: localId,
                isGroupChat: isGroupChat,
                id: id,
                username: username,
                avatarUrl: avatarUrl,
                isPending: isPending,
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
typedef $$SyncMarkersTableCreateCompanionBuilder =
    SyncMarkersCompanion Function({
      required String key,
      Value<DateTime?> lastSyncedAt,
      Value<int> rowid,
    });
typedef $$SyncMarkersTableUpdateCompanionBuilder =
    SyncMarkersCompanion Function({
      Value<String> key,
      Value<DateTime?> lastSyncedAt,
      Value<int> rowid,
    });

class $$SyncMarkersTableFilterComposer
    extends Composer<_$AppDatabase, $SyncMarkersTable> {
  $$SyncMarkersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastSyncedAt => $composableBuilder(
    column: $table.lastSyncedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SyncMarkersTableOrderingComposer
    extends Composer<_$AppDatabase, $SyncMarkersTable> {
  $$SyncMarkersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastSyncedAt => $composableBuilder(
    column: $table.lastSyncedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SyncMarkersTableAnnotationComposer
    extends Composer<_$AppDatabase, $SyncMarkersTable> {
  $$SyncMarkersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<DateTime> get lastSyncedAt => $composableBuilder(
    column: $table.lastSyncedAt,
    builder: (column) => column,
  );
}

class $$SyncMarkersTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SyncMarkersTable,
          SyncMarker,
          $$SyncMarkersTableFilterComposer,
          $$SyncMarkersTableOrderingComposer,
          $$SyncMarkersTableAnnotationComposer,
          $$SyncMarkersTableCreateCompanionBuilder,
          $$SyncMarkersTableUpdateCompanionBuilder,
          (
            SyncMarker,
            BaseReferences<_$AppDatabase, $SyncMarkersTable, SyncMarker>,
          ),
          SyncMarker,
          PrefetchHooks Function()
        > {
  $$SyncMarkersTableTableManager(_$AppDatabase db, $SyncMarkersTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SyncMarkersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SyncMarkersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SyncMarkersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> key = const Value.absent(),
                Value<DateTime?> lastSyncedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SyncMarkersCompanion(
                key: key,
                lastSyncedAt: lastSyncedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String key,
                Value<DateTime?> lastSyncedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SyncMarkersCompanion.insert(
                key: key,
                lastSyncedAt: lastSyncedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SyncMarkersTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SyncMarkersTable,
      SyncMarker,
      $$SyncMarkersTableFilterComposer,
      $$SyncMarkersTableOrderingComposer,
      $$SyncMarkersTableAnnotationComposer,
      $$SyncMarkersTableCreateCompanionBuilder,
      $$SyncMarkersTableUpdateCompanionBuilder,
      (
        SyncMarker,
        BaseReferences<_$AppDatabase, $SyncMarkersTable, SyncMarker>,
      ),
      SyncMarker,
      PrefetchHooks Function()
    >;
typedef $$PostDraftsTableCreateCompanionBuilder =
    PostDraftsCompanion Function({
      Value<int> id,
      Value<String> draftType,
      required String title,
      required String content,
      Value<String?> tag,
      required bool isPublic,
      Value<String?> imagePath,
      required DateTime savedAt,
    });
typedef $$PostDraftsTableUpdateCompanionBuilder =
    PostDraftsCompanion Function({
      Value<int> id,
      Value<String> draftType,
      Value<String> title,
      Value<String> content,
      Value<String?> tag,
      Value<bool> isPublic,
      Value<String?> imagePath,
      Value<DateTime> savedAt,
    });

class $$PostDraftsTableFilterComposer
    extends Composer<_$AppDatabase, $PostDraftsTable> {
  $$PostDraftsTableFilterComposer({
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

  ColumnFilters<String> get draftType => $composableBuilder(
    column: $table.draftType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tag => $composableBuilder(
    column: $table.tag,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isPublic => $composableBuilder(
    column: $table.isPublic,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get imagePath => $composableBuilder(
    column: $table.imagePath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get savedAt => $composableBuilder(
    column: $table.savedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PostDraftsTableOrderingComposer
    extends Composer<_$AppDatabase, $PostDraftsTable> {
  $$PostDraftsTableOrderingComposer({
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

  ColumnOrderings<String> get draftType => $composableBuilder(
    column: $table.draftType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tag => $composableBuilder(
    column: $table.tag,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isPublic => $composableBuilder(
    column: $table.isPublic,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get imagePath => $composableBuilder(
    column: $table.imagePath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get savedAt => $composableBuilder(
    column: $table.savedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PostDraftsTableAnnotationComposer
    extends Composer<_$AppDatabase, $PostDraftsTable> {
  $$PostDraftsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get draftType =>
      $composableBuilder(column: $table.draftType, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get content =>
      $composableBuilder(column: $table.content, builder: (column) => column);

  GeneratedColumn<String> get tag =>
      $composableBuilder(column: $table.tag, builder: (column) => column);

  GeneratedColumn<bool> get isPublic =>
      $composableBuilder(column: $table.isPublic, builder: (column) => column);

  GeneratedColumn<String> get imagePath =>
      $composableBuilder(column: $table.imagePath, builder: (column) => column);

  GeneratedColumn<DateTime> get savedAt =>
      $composableBuilder(column: $table.savedAt, builder: (column) => column);
}

class $$PostDraftsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PostDraftsTable,
          PostDraft,
          $$PostDraftsTableFilterComposer,
          $$PostDraftsTableOrderingComposer,
          $$PostDraftsTableAnnotationComposer,
          $$PostDraftsTableCreateCompanionBuilder,
          $$PostDraftsTableUpdateCompanionBuilder,
          (
            PostDraft,
            BaseReferences<_$AppDatabase, $PostDraftsTable, PostDraft>,
          ),
          PostDraft,
          PrefetchHooks Function()
        > {
  $$PostDraftsTableTableManager(_$AppDatabase db, $PostDraftsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PostDraftsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PostDraftsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PostDraftsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> draftType = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> content = const Value.absent(),
                Value<String?> tag = const Value.absent(),
                Value<bool> isPublic = const Value.absent(),
                Value<String?> imagePath = const Value.absent(),
                Value<DateTime> savedAt = const Value.absent(),
              }) => PostDraftsCompanion(
                id: id,
                draftType: draftType,
                title: title,
                content: content,
                tag: tag,
                isPublic: isPublic,
                imagePath: imagePath,
                savedAt: savedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> draftType = const Value.absent(),
                required String title,
                required String content,
                Value<String?> tag = const Value.absent(),
                required bool isPublic,
                Value<String?> imagePath = const Value.absent(),
                required DateTime savedAt,
              }) => PostDraftsCompanion.insert(
                id: id,
                draftType: draftType,
                title: title,
                content: content,
                tag: tag,
                isPublic: isPublic,
                imagePath: imagePath,
                savedAt: savedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PostDraftsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PostDraftsTable,
      PostDraft,
      $$PostDraftsTableFilterComposer,
      $$PostDraftsTableOrderingComposer,
      $$PostDraftsTableAnnotationComposer,
      $$PostDraftsTableCreateCompanionBuilder,
      $$PostDraftsTableUpdateCompanionBuilder,
      (PostDraft, BaseReferences<_$AppDatabase, $PostDraftsTable, PostDraft>),
      PostDraft,
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
  $$SyncMarkersTableTableManager get syncMarkers =>
      $$SyncMarkersTableTableManager(_db, _db.syncMarkers);
  $$PostDraftsTableTableManager get postDrafts =>
      $$PostDraftsTableTableManager(_db, _db.postDrafts);
}

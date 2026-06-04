import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../token_storage.dart';
import 'package:http/http.dart' as http;
import '../local_data/database.dart';
import '../user_api_service.dart';
import 'dart:async';
import 'package:drift/drift.dart' hide Column;

// Drei Sorten Nachrichten, die der Server uns schicken kann.
sealed class ChatEvent {
  const ChatEvent();
}

class IncomingDm extends ChatEvent {
  final int senderId;
  final String message;
  final DateTime createdAt;
  const IncomingDm({
    required this.senderId,

    required this.message,
    required this.createdAt,
  });
}

class InComingGroupChat extends ChatEvent {
  final int senderId;
  final int groupChatId;
  final String message;
  final DateTime createdAt;
  const InComingGroupChat({
    required this.senderId,
    required this.groupChatId,
    required this.message,
    required this.createdAt,
  });
}

class MessageAck extends ChatEvent {
  final int to;
  final int deliveredLive;
  const MessageAck({required this.to, required this.deliveredLive});
}

class ChatErrorEvent extends ChatEvent {
  final String detail;
  const ChatErrorEvent(this.detail);
}

class MessengerApiService {
  static const String _baseWsUrl = 'wss://web-production-1bb6f.up.railway.app';
  static const String baseUrl = 'https://web-production-1bb6f.up.railway.app';

  final AppDatabase _db;
  final int _myUserId;

  MessengerApiService(this._db, this._myUserId);

  WebSocketChannel? _channel;
  Stream<ChatEvent>? _incoming;
  StreamSubscription<ChatEvent>? _subscription;

  bool get isConnected => _channel != null;

  Future<void> connect() async {
    if (_channel != null)
      return; // wenn schon connected dann kein erneut connecten

    final token = await TokenStorage.getToken();
    final uri = Uri.parse('$_baseWsUrl/ws/chat?token=$token');
    _channel = WebSocketChannel.connect(uri); // mein channel connected einmal

    _incoming = _channel!
        .stream // wird einmal aufgerufe
        .map((raw) => jsonDecode(raw as String) as Map<String, dynamic>)
        .map(_parseEvent) //welche art ist es?
        .where((e) => e != null)
        .cast<ChatEvent>()
        .asBroadcastStream(); // mehere listener

    _subscription = _incoming!.listen(_persistIncoming);
  }

  Stream<ChatEvent>? get incoming =>
      _incoming; //referiert zu der funktion oben: nicht mehr als ein einziger aufruf

  ChatEvent? _parseEvent(Map<String, dynamic> json) {
    switch (json["kind"]) {
      case "error":
        return ChatErrorEvent(json['detail'].toString());

      case "ack":
        return MessageAck(
          to: json['to'] as int,
          deliveredLive: json['delivered_live'] as int,
        );
      case "dm":
        return IncomingDm(
          senderId: json['sender_id'] as int,
          message: json['message'] as String,
          createdAt: DateTime.parse(json['created_at'] as String),
        );
      case "group":
        return InComingGroupChat(
          senderId: json['sender_id'] as int,
          groupChatId: json['group_chat_id'] as int,
          message: json['message'] as String,
          createdAt: DateTime.parse(json['created_at'] as String),
        );
      default:
        return null;
    }
  }

  Future<void> _persistIncoming(ChatEvent event) async {
    switch (event) {
      case IncomingDm dm:
        await _ensureDmOpenChat(dm.senderId);
        await _db.saveDm(
          senderId: dm.senderId,
          recipientId: _myUserId,
          message: dm.message,
          createdAt: dm.createdAt,
        );
      case InComingGroupChat g:
        await _ensureGroupOpenChat(g.groupChatId);
        await _db.saveGroupMessage(
          senderId: g.senderId,
          groupChatId: g.groupChatId,
          message: g.message,
          createdAt: g.createdAt,
        );
      case MessageAck _:
      case ChatErrorEvent _:
        // Acks und Errors gehen nicht in die DB — die sind nur Feedback
        // für den Sender / die UI im Moment
        break;
    }
  }

  // Legt einen OpenChat-Eintrag für einen DM-Partner an, falls noch keiner existiert.
  // Holt Username/Avatar per API; bei Fehler bleibt der Fallback "User $id".
  Future<void> _ensureDmOpenChat(int peerId) async {
    final existing = await (_db.select(_db.openChats)
          ..where((t) => t.id.equals(peerId) & t.isGroupChat.equals(false)))
        .getSingleOrNull();
    if (existing != null) return;

    String username = 'User $peerId';
    String? avatarUrl;
    try {
      final user = await UserApiService.getUser(peerId);
      if (user['username'] is String) username = user['username'] as String;
      if (user['profile_picture_url'] is String) {
        avatarUrl = user['profile_picture_url'] as String;
      }
    } catch (_) {
      // Fallback bleibt
    }

    await _db.into(_db.openChats).insert(
          OpenChatsCompanion.insert(
            id: peerId,
            isGroupChat: false,
            username: Value(username),
            avatarUrl: Value(avatarUrl),
          ),
        );
  }

  Future<void> _ensureGroupOpenChat(int groupChatId) async {
    final existing = await (_db.select(_db.openChats)
          ..where((t) => t.id.equals(groupChatId) & t.isGroupChat.equals(true)))
        .getSingleOrNull();
    if (existing != null) return;

    await _db.into(_db.openChats).insert(
          OpenChatsCompanion.insert(
            id: groupChatId,
            isGroupChat: true,
            username: Value('Gruppe $groupChatId'),
          ),
        );
  }

  void sendDirectMessage(int recipientId, String message) async {
    _channel?.sink.add(
      jsonEncode({'kind': 'dm', 'to': recipientId, 'message': message}),
    );
    await _db.saveDm(
      senderId: _myUserId,
      recipientId: recipientId,
      message: message,
      createdAt: DateTime.now().toUtc(),
    );
  }

  void sendGroupMessage(int groupChatId, String message) async {
    _channel?.sink.add(
      jsonEncode({'kind': 'group', 'to': groupChatId, 'message': message}),
    );
    await _db.saveGroupMessage(
      senderId: _myUserId,
      groupChatId: groupChatId,
      message: message,
      createdAt: DateTime.now().toUtc(),
    );
  }

  void disconnect() {
    _subscription?.cancel();
    _subscription = null;
    _channel?.sink.close();
    _channel = null;
    _incoming = null;
  }

  static Future<bool> deleteGroup(int groupChatId) async {
    final token = await TokenStorage.getToken();
    final response = await http.delete(
      Uri.parse("$baseUrl/group_chat/$groupChatId"),
      headers: {'Authorization': 'Bearer $token'},
    );
    return response.statusCode == 200;
  }

  static Future<bool> leaveGroup(int groupChatId) async {
    final token = await TokenStorage.getToken();
    final response = await http.delete(
      Uri.parse("$baseUrl/group_chat/leave/$groupChatId"),
      headers: {'Authorization': 'Bearer $token'},
    );
    return response.statusCode == 200;
  }

  static Future<int?> createGroup() async {
    final token = await TokenStorage.getToken();
    final response = await http.post(
      Uri.parse("$baseUrl/group_chat/create"),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode != 201) return null;
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    return body['group_chat_id'] as int;
  }

  static Future<bool> joinGroup(int groupChatId) async {
    final token = await TokenStorage.getToken();
    final response = await http.post(
      Uri.parse("$baseUrl/group_chat/join/$groupChatId"),
      headers: {'Authorization': 'Bearer $token'},
    );
    return response.statusCode == 201;
  }
}

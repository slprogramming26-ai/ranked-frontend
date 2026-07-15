import '../local_data/database.dart';
import 'messenger_api_service.dart';

class ChatMessage {
  final int senderId;
  final String message;
  final DateTime createdAt;

  const ChatMessage({
    required this.senderId,
    required this.message,
    required this.createdAt,
  });
}

abstract class Conversation {
  String get title;
  String? get avatarUrl;
  int get myUserId;
  Stream<List<ChatMessage>> watch();
  void send(String text);
}

class DmConversation implements Conversation {
  final int peerId;
  @override
  final int myUserId;
  final AppDatabase db;
  final MessengerApiService service;

  // Anzeige-Daten aus der OpenChats-Zeile (Chatliste). Nullable, weil ein
  // Chat theoretisch auch ohne bekannten Namen geoeffnet werden kann —
  // dann greift der Fallback in `title`.
  final String? displayName;
  @override
  final String? avatarUrl;

  DmConversation({
    required this.peerId,
    required this.myUserId,
    required this.db,
    required this.service,
    this.displayName,
    this.avatarUrl,
  });

  @override
  String get title => displayName ?? 'User $peerId';


@override
void send(String text) {
  if (text.trim().isEmpty) return;
  service.sendDirectMessage(peerId, text);
}

  @override
  Stream<List<ChatMessage>> watch() {
    // Die DB liefert absteigend (neueste zuerst, wegen des LIMIT-Fensters).
    // Die UI-Logik (Datums-Trenner, Gruppierung) denkt chronologisch —
    // deshalb hier einmal umdrehen.
    return db
        .watchDmConversation(myUserId: myUserId, otherUserId: peerId)
        .map((rows) => rows.reversed
        .map((r) => ChatMessage(
      senderId: r.senderId,
      message: r.message,
      createdAt: r.createdAt,
    ))
        .toList());
  }
}

class GroupConversation implements Conversation{
  final int groupChatId;
  @override
  final int myUserId;
  final AppDatabase db;
  final MessengerApiService service;

  final String? displayName;
  @override
  final String? avatarUrl;

  GroupConversation({
    required this.groupChatId,
    required this.myUserId,
    required this.db,
    required this.service,
    this.displayName,
    this.avatarUrl,
  });

  @override
  Stream<List<ChatMessage>> watch() {
    // Wie im DM: DB liefert absteigend (LIMIT-Fenster), UI will chronologisch.
    return db.watchGroupConversation(groupChatId: groupChatId)
    .map((rows) => rows.reversed.map((r) => ChatMessage(senderId: r.senderId, message: r.message, createdAt: r.createdAt)).toList());

  }

  @override
  void send(String text) {
    if (text.trim().isEmpty) return;
    service.sendGroupMessage(groupChatId, text);

  }

  @override
  String get title => displayName ?? 'Gruppe $groupChatId';
}
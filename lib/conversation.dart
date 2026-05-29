import 'local_data/database.dart';
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

  DmConversation({
    required this.peerId,
    required this.myUserId,
    required this.db,
    required this.service,
  });

@override
// TODO: implement title
  String get title => 'Chat mit User $peerId';


@override
void send(String text) {
  if (text.trim().isEmpty) return;
  service.sendDirectMessage(peerId, text);
}

  @override
  Stream<List<ChatMessage>> watch() {
    return db
        .watchDmConversation(myUserId: myUserId, otherUserId: peerId)
        .map((rows) => rows
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

  GroupConversation({
    required this.groupChatId,
    required this.myUserId,
    required this.db,
    required this.service,
  });

  @override
  Stream<List<ChatMessage>> watch() {
    return db.watchGroupConversation(groupChatId: groupChatId)
    .map((rows) => rows.map((r) => ChatMessage(senderId: r.senderId, message: r.message, createdAt: r.createdAt)).toList());

  }

  @override
  void send(String text) {
    if (text.trim().isEmpty) return;
    service.sendGroupMessage(groupChatId, text);

  }

  @override
  // TODO: implement title
  String get title => "Group $groupChatId";
}
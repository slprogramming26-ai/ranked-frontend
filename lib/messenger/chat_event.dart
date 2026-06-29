// Das "Vokabular" zwischen Server und App: Welche Sorten Nachrichten kann uns
// der WebSocket schicken? Jede Sorte ist eine eigene Klasse, alle erben von
// [ChatEvent]. Dadurch koennen wir mit switch/case typsicher darauf reagieren.
//
// Diese Datei ist bewusst eigenstaendig (kein Bezug auf den Service), damit das
// reine Protokoll-Wissen an einem Ort liegt.

sealed class ChatEvent {
  const ChatEvent();
}

/// Eingehende Direktnachricht (1:1).
class IncomingDm extends ChatEvent {
  final int senderId;
  final String message;
  final DateTime createdAt;
  final String?
  clientMsgId; // null, solange das Backend den Key noch nicht zurueckgibt
  const IncomingDm({
    required this.senderId,
    required this.message,
    required this.createdAt,
    this.clientMsgId,
  });
}

/// Eingehende Gruppennachricht.
class InComingGroupChat extends ChatEvent {
  final int senderId;
  final int groupChatId;
  final String message;
  final DateTime createdAt;
  final String? clientMsgId;
  // null bei Alt-Nachrichten aus der Klartext-Zeit -> unverschluesselt behandeln.
  final int? keyVersion;
  const InComingGroupChat({
    required this.senderId,
    required this.groupChatId,
    required this.message,
    required this.createdAt,
    this.clientMsgId,
    this.keyVersion,
  });
}

/// Bestaetigung des Servers, dass unsere gesendete Nachricht angekommen ist.
class MessageAck extends ChatEvent {
  final int to;
  final int deliveredLive;
  const MessageAck({required this.to, required this.deliveredLive});
}

// Antwort auf einen Gruppen-Send: der Schlüssel muss erst NEU erzeugt werden
// (Gruppe ist "dirty" oder hat noch keine Epoche). -> Rekey-Flow, dann erneut senden.
class GroupRekeyRequired extends ChatEvent {
  final int groupChatId;
  const GroupRekeyRequired(this.groupChatId);
}

// Antwort auf einen Gruppen-Send: wir sind hinterher, der aktuelle Schlüssel
// existiert schon. -> abholen, dann erneut senden.
class GroupKeyOutdated extends ChatEvent {
  final int groupChatId;
  final int currentVersion;
  const GroupKeyOutdated({
    required this.groupChatId,
    required this.currentVersion,
  });
}

/// Server meldet einen Fehler (z.B. ungueltiges Ziel).
class ChatErrorEvent extends ChatEvent {
  final String detail;
  const ChatErrorEvent(this.detail);
}

/// Uebersetzt ein rohes JSON-Objekt vom Server in das passende [ChatEvent].
/// Gibt `null` zurueck, wenn der "kind" unbekannt ist (dann ignorieren wir es).
ChatEvent? parseChatEvent(Map<String, dynamic> json) {
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
        clientMsgId: json['client_msg_id'] as String?,
      );
    case "group":
      return InComingGroupChat(
        senderId: json['sender_id'] as int,
        groupChatId: json['group_chat_id'] as int,
        message: json['message'] as String,
        createdAt: DateTime.parse(json['created_at'] as String),
        clientMsgId: json['client_msg_id'] as String?,
        keyVersion: json['key_version'] as int?,
      );
    case "rekey_required":
      return GroupRekeyRequired(json['group_chat_id'] as int);
    case "key_outdated":
      return GroupKeyOutdated(
        groupChatId: json['group_chat_id'] as int,
        currentVersion: json['current_version'] as int,
      );
    default:
      return null;
  }
}

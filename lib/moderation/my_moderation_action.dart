import 'report_reason.dart';

/// Was gegen mich unternommen wurde. apiValue = Feld "action" von
/// GET /users/moderation (unban/resolve/role_change liefert das Backend
/// dort bewusst nicht, die betreffen den User nicht direkt).
enum MyActionKind {
  ban("ban"),
  deletePost("delete_post"),
  deleteComment("delete_comment"),
  deleteStory("delete_story"),
  deleteProfilePicture("delete_profile_picture");

  const MyActionKind(this.apiValue);
  final String apiValue;

  static MyActionKind? fromApi(Object? raw) {
    for (final t in values) {
      if (t.apiValue == raw) return t;
    }
    return null;
  }
}

/// Ein Eintrag im Screen "Kontostatus" (DSA Art. 17: Begruendung an die
/// betroffene Person). Bewusst ohne Moderator, den liefert das Backend nicht.
class MyModerationAction {
  final int id;
  final MyActionKind kind;

  /// Roh vom Backend. Bei delete_* eine Kategorie ("spam" ...), bei ban
  /// Freitext des Mods. Zum Anzeigen [reasonCategory] bzw. [reason] nehmen.
  final String? reason;

  /// Optionale Begruendung des Mods beim Entfernen.
  final String? details;

  /// Nur bei ban: Dauer in Tagen, null = dauerhaft.
  final int? banDays;

  /// Text-Kopie des Inhalts. null bei Story/Profilbild oder nach Ablauf der Frist.
  final String? contentSnapshot;

  final DateTime createdAt; // lokal
  final DateTime appealUntil; // lokal, vorerst nicht angezeigt (Widerspruch kommt spaeter)

  /// Ein Admin hat den Inhalt wiederhergestellt.
  final bool restored;

  /// Nur bei ban: Sperre vorzeitig aufgehoben (lokal). null = nicht
  /// aufgehoben oder Eintrag von vor der Backend-Aenderung.
  final DateTime? liftedAt;

  const MyModerationAction({
    required this.id,
    required this.kind,
    this.reason,
    this.details,
    this.banDays,
    this.contentSnapshot,
    this.liftedAt,
    required this.createdAt,
    required this.appealUntil,
    required this.restored,
  });

  bool get isBan => kind == MyActionKind.ban;

  /// ban ohne Tage = dauerhaft. Bei delete_* immer false.
  bool get isPermanent => isBan && banDays == null;

  /// Grund als Kategorie (nur bei delete_*). null bei ban (dort ist reason
  /// Freitext) oder bei unbekannter Kategorie -> dann Rohtext anzeigen.
  ReportReason? get reasonCategory =>
      isBan ? null : ReportReason.fromApi(reason);

  /// Gibt null zurueck, wenn "action" unbekannt ist (Eintrag ueberspringen,
  /// getMyActions filtert per nonNulls, wie bei der Queue).
  static MyModerationAction? fromJson(Map<String, dynamic> json) {
    // Nach dem Null-Check ist kind promoted (MyActionKind statt MyActionKind?).
    final kind = MyActionKind.fromApi(json['action']);
    if (kind == null) return null;

    final rawLifted = json['lifted_at'] as String?;

    return MyModerationAction(
      id: json['id'] as int,
      kind: kind,
      reason: json['reason'] as String?,
      details: json['details'] as String?,
      banDays: json['ban_days'] as int?,
      contentSnapshot: json['content_snapshot'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String).toLocal(),
      appealUntil: DateTime.parse(json['appeal_until'] as String).toLocal(),
      // == true statt "as bool": fehlt das Feld, ist es false statt Crash.
      restored: json['restored'] == true,
      liftedAt: rawLifted == null ? null : DateTime.parse(rawLifted).toLocal(),
    );
  }
}

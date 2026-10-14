import 'report_queue_item.dart';

/// Alle Aktionstypen im Audit-Log (Feld "action" von ModerationActionOut).
/// apiValue bewusst nicht .name (resolve_reports vs. resolve usw.).
enum ModerationActionType {
  ban("ban"),
  unban('unban'),
  resolve('resolve_reports'),
  roleChange("role_change"),
  // Achtung: im Log heisst es restore_content, die ACTIVITY dazu content_restored.
  restoreContent("restore_content"),
  deletePost("delete_post"),
  deleteComment("delete_comment"),
  deleteStory("delete_story"),
  deleteProfilePicture("delete_profile_picture");

  const ModerationActionType(this.apiValue);
  final String apiValue;

  /// Die 4 Entfernen-Typen. Nur die kann ein Admin wiederherstellen.
  bool get isRemoval => switch (this) {
    deletePost || deleteComment || deleteStory || deleteProfilePicture => true,
    _ => false,
  };

  static ModerationActionType? fromApi(Object? raw) {
    for (final t in values) {
      if (t.apiValue == raw) return t;
    }
    return null;
  }
}

/// Eine Zeile Audit-Log (GET /admin/users/{id} -> recent_actions, spaeter
/// auch GET /admin/actions). Anders als in der Queue wird ein unbekannter
/// Typ NICHT uebersprungen: im Log soll nichts still fehlen, die UI zeigt
/// dann "Unbekannte Aktion".
class ModerationLogEntry {
  final int id;

  /// null = Typ kennt die App noch nicht (neuer Typ im Backend).
  final ModerationActionType? type;

  final DateTime createdAt; // lokal

  /// null, wenn der Account inzwischen geloescht ist (SET NULL im Backend).
  /// Gleiche Form wie der gemeldete User in der Queue -> ReportedUser.
  final ReportedUser? moderator;
  final ReportedUser? targetUser;

  /// ID des betroffenen Inhalts (Post/Kommentar/Story), sonst null.
  final int? targetId;

  /// Bei delete_* eine Kategorie ("spam" ...), bei ban Freitext, sonst oft null.
  final String? reason;

  /// Text-Kopie des entfernten Inhalts. null = nie gesetzt oder Frist um.
  final String? contentSnapshot;

  /// Je nach Typ andere Schluessel (Stand Backend admin.py):
  /// ban: days (null = dauerhaft) | unban: was_banned_until, ban_reason |
  /// delete_*: reports, details? | resolve_reports: target_type, status, reports |
  /// role_change: old_role, new_role | restore_content: restored_action_id, location_dropped?
  /// Bewusst roh, die UI pickt sich raus, was sie braucht.
  final Map<String, dynamic> extra;

  /// Liegt der Inhalt noch im Archiv (nicht wiederhergestellt, Frist nicht
  /// um)? Kommt vom Backend, nur in GET /admin/actions verlaesslich.
  final bool restorable;

  const ModerationLogEntry({
    required this.id,
    required this.type,
    required this.createdAt,
    this.moderator,
    this.targetUser,
    this.targetId,
    this.reason,
    this.contentSnapshot,
    this.extra = const {},
    this.restorable = false,
  });

  /// Nach erfolgreichem Restore: gleiche Zeile, nur nicht mehr wiederherstellbar.
  ModerationLogEntry markRestored() => ModerationLogEntry(
    id: id,
    type: type,
    createdAt: createdAt,
    moderator: moderator,
    targetUser: targetUser,
    targetId: targetId,
    reason: reason,
    contentSnapshot: contentSnapshot,
    extra: extra,
    restorable: false,
  );

  factory ModerationLogEntry.fromJson(Map<String, dynamic> json) {
    final rawModerator = json['moderator'] as Map<String, dynamic>?;
    final rawTarget = json['target_user'] as Map<String, dynamic>?;
    final type = ModerationActionType.fromApi(json['action']);

    return ModerationLogEntry(
      id: json['id'] as int,
      type: type,
      createdAt: DateTime.parse(json['created_at'] as String).toLocal(),
      moderator: rawModerator == null ? null : ReportedUser.fromJson(rawModerator),
      targetUser: rawTarget == null ? null : ReportedUser.fromJson(rawTarget),
      targetId: json['target_id'] as int?,
      reason: json['reason'] as String?,
      contentSnapshot: json['content_snapshot'] as String?,
      // extra ist im Backend Optional -> null wird zur leeren Map,
      // dann muss die UI nicht ueberall auf null pruefen.
      extra: (json['extra'] as Map<String, dynamic>?) ?? const {},
      // Fehlt das Feld (Backend noch alt), lieber den Button zeigen und
      // 404/409 als Snackbar melden, als ihn still zu verstecken.
      restorable: json['restorable'] as bool? ?? (type?.isRemoval ?? false),
    );
  }
}

import 'report_reason.dart';
import 'report_target.dart';
import 'user_role.dart';

/// Der gemeldete User, so wie `GET /admin/reports` ihn mitschickt.
class ReportedUser {
  final int id;
  final String username;
  final UserRole role;
  final String? avatarUrl;
  final DateTime? bannedUntil; // null = nicht gesperrt

  const ReportedUser({
    required this.id,
    required this.username,
    required this.role,
    this.avatarUrl,
    this.bannedUntil,
  });

  factory ReportedUser.fromJson(Map<String, dynamic> json) {
    final until = json['banned_until'] as String?;
    return ReportedUser(
      id: json['id'] as int,
      username: json['username'] as String,
      role: UserRole.fromApi(json['role']),
      avatarUrl: json['profile_picture_url'] as String?,
      bannedUntil: until == null ? null : DateTime.parse(until).toLocal(),
    );
  }

  bool get isBanned =>
      bannedUntil != null && bannedUntil!.isAfter(DateTime.now());

  /// Wie Suspension.isPermanent: per Jahr, nicht per String.
  bool get isPermanentlyBanned => bannedUntil != null && bannedUntil!.year >= 9999;
}

/// Was der Mod vom gemeldeten Inhalt sieht. Je nach Ziel sind nur manche
/// Felder gesetzt: Post = title/content/imageUrl, Kommentar = content,
/// Story = imageUrl, User = content (Bio) + imageUrl (Profilbild).
/// Ist der Inhalt geloescht, steht nur content drin (Text-Kopie vom Melden).
class ReportPreview {
  final String? title;
  final String? content;
  final String? imageUrl;

  const ReportPreview({this.title, this.content, this.imageUrl});

  factory ReportPreview.fromJson(Map<String, dynamic> json) => ReportPreview(
        title: json['title'] as String?,
        content: json['content'] as String?,
        imageUrl: json['image_url'] as String?,
      );
}

/// EIN Eintrag pro gemeldetem Ziel, egal wie viele Meldungen dranhaengen.
class ReportQueueItem {
  final ReportTarget target;

  /// Bei target == user ist das die User-ID (so erwartet es auch resolve).
  final int targetId;
  final ReportedUser user;
  final int count;
  final Map<ReportReason, int> reasons;
  final List<String> details;
  final DateTime firstReportedAt;
  final DateTime lastReportedAt;
  final ReportPreview? preview;
  final bool contentDeleted;

  const ReportQueueItem({
    required this.target,
    required this.targetId,
    required this.user,
    required this.count,
    required this.reasons,
    required this.details,
    required this.firstReportedAt,
    required this.lastReportedAt,
    required this.preview,
    required this.contentDeleted,
  });

  /// Eindeutig pro Ziel: fuer Dedupe beim Nachladen und als ValueKey.
  String get key => '${target.apiValue}:$targetId';

  /// Gibt null zurueck, wenn target_type unbekannt ist (Eintrag ueberspringen).
  static ReportQueueItem? fromJson(Map<String, dynamic> json) {
    // Unbekannter Typ -> Eintrag ueberspringen (getReports filtert per nonNulls).
    final target = ReportTarget.fromApi(json['target_type']);
    if (target == null) return null;

    // json['reasons'] ist Map<String, dynamic>, NICHT Map<String, int>:
    // ein direkter Cast wuerde zur Laufzeit werfen. Deshalb Eintrag fuer Eintrag.
    final Map<ReportReason, int> reportReasons = {};
    final rawReasons = json['reasons'] as Map<String, dynamic>;
    for (final rawKey in rawReasons.keys) {
      final key = ReportReason.fromApi(rawKey);
      if (key == null) continue; // neuer Grund im Backend -> nur dieser Chip fehlt
      reportReasons[key] = rawReasons[rawKey] as int;
    }

    // List<dynamic> -> List<String>. List.from kopiert und prueft jeden
    // Eintrag sofort (cast() wuerde erst beim spaeteren Zugriff werfen).
    final details = List<String>.from(json['details'] as List<dynamic>);

    final rawPreview = json['preview'] as Map<String, dynamic>?;

    return ReportQueueItem(
      target: target,
      targetId: json['target_id'] as int,
      user: ReportedUser.fromJson(json['reported_user'] as Map<String, dynamic>),
      count: json['report_count'] as int,
      reasons: reportReasons,
      details: details,
      firstReportedAt:
          DateTime.parse(json['first_reported_at'] as String).toLocal(),
      lastReportedAt:
          DateTime.parse(json['last_reported_at'] as String).toLocal(),
      preview: rawPreview == null ? null : ReportPreview.fromJson(rawPreview),
      contentDeleted: json['content_deleted'] == true,
    );
  }
}

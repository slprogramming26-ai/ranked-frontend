import 'moderation_log_entry.dart';
import 'user_role.dart';

/// Alles, was ein Mod fuer eine Entscheidung ueber einen User braucht
/// (GET /admin/users/{id}, Backend-Schema AdminUserDetail).
class AdminUserDetail {
  final int id;
  final String username;
  final UserRole role;
  final DateTime createdAt; // lokal, "Mitglied seit"
  final String? biography;
  final String? avatarUrl;

  /// null = nicht gesperrt. Kann auch in der Vergangenheit liegen
  /// (abgelaufen) -> fuer die Anzeige [isBanned] nehmen.
  final DateTime? bannedUntil;
  final String? banReason;

  /// Offene Meldungen gegen den User (inkl. seiner Inhalte).
  final int reportsPending;

  /// Alle Meldungen jemals, auch erledigte.
  final int reportsTotal;

  /// Die letzten (max. 10) Massnahmen gegen den User, neueste zuerst.
  final List<ModerationLogEntry> recentActions;

  const AdminUserDetail({
    required this.id,
    required this.username,
    required this.role,
    required this.createdAt,
    this.biography,
    this.avatarUrl,
    this.bannedUntil,
    this.banReason,
    required this.reportsPending,
    required this.reportsTotal,
    required this.recentActions,
  });

  /// Gleiche Regel wie ReportedUser.isBanned.
  bool get isBanned =>
      bannedUntil != null && bannedUntil!.isAfter(DateTime.now());

  /// Wie ReportedUser.isPermanentlyBanned: per Jahr, nicht per String.
  bool get isPermanentlyBanned =>
      bannedUntil != null && bannedUntil!.year >= 9999;

  factory AdminUserDetail.fromJson(Map<String, dynamic> json) {
    final rawBannedUntil = json['banned_until'] as String?;

    // JSON-Listen kommen als List<dynamic> an -> pro Element casten.
    // ModerationLogEntry.fromJson gibt nie null zurueck, also kein nonNulls.
    final List<ModerationLogEntry> recentActions = [];
    final rawRecentActions = json['recent_actions'] as List<dynamic>;
    for (final entry in rawRecentActions) {
      recentActions.add(
        ModerationLogEntry.fromJson(entry as Map<String, dynamic>),
      );
    }

    return AdminUserDetail(
      id: json['id'] as int,
      username: json['username'] as String,
      role: UserRole.fromApi(json['role']),
      createdAt: DateTime.parse(json['created_at'] as String).toLocal(),
      biography: json['biography'] as String?,
      avatarUrl: json['profile_picture_url'] as String?,
      bannedUntil: rawBannedUntil == null
          ? null
          : DateTime.parse(rawBannedUntil).toLocal(),
      banReason: json['ban_reason'] as String?,
      reportsPending: json['reports_pending'] as int,
      reportsTotal: json['reports_total'] as int,
      recentActions: recentActions,
    );
  }
}

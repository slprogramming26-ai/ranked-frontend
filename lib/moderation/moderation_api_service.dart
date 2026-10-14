import 'dart:convert';

import '../api_client.dart';
import '../user_api_service.dart';
import 'admin_user_detail.dart';
import 'moderation_log_entry.dart';
import 'my_moderation_action.dart';
import 'report_queue_item.dart';
import 'report_reason.dart';
import 'report_target.dart';
import 'user_role.dart';

/// Status einer Meldung. apiValue = Query-Parameter `status` bzw. der Wert
/// beim Resolve. Bewusst nicht .name (action_taken vs. actionTaken).
enum ReportStatus {
  pending('pending'),
  dismissed('dismissed'),
  actionTaken('action_taken');

  const ReportStatus(this.apiValue);
  final String apiValue;
}

/// Ergebnis einer Mod-Aktion. forbidden = 403 (Rangregel / Mod-Limit), damit
/// die UI etwas anderes zeigen kann als ein generisches "fehlgeschlagen".
enum ModerationResult { ok, forbidden, failed }

/// Ergebnis von [ModerationApiService.getUserDetail]. sealed statt Enum,
/// weil nur der Ok-Fall Daten mitbringt. Ein switch darueber ist exhaustive:
/// kommt ein Fall dazu, meckert der Compiler an jeder Stelle.
sealed class UserDetailResult {
  const UserDetailResult();
}

final class UserDetailOk extends UserDetailResult {
  final AdminUserDetail detail;
  const UserDetailOk(this.detail);
}

/// 403 (Rang gleich/hoeher) oder 400 (man selbst). Fuer die UI dasselbe:
/// "Diesen User darfst du nicht moderieren".
final class UserDetailForbidden extends UserDetailResult {
  const UserDetailForbidden();
}

/// 404: Account gibt es nicht (mehr).
final class UserDetailNotFound extends UserDetailResult {
  const UserDetailNotFound();
}

/// Netz weg, 5xx, kaputtes JSON -> "Erneut versuchen".
final class UserDetailFailed extends UserDetailResult {
  const UserDetailFailed();
}

/// Filter-Chips im Protokoll. Ein Chip kann mehrere Typen abdecken
/// ("Entfernt" = alle 4 delete_*); leer = kein Filter.
enum AuditFilter {
  all([]),
  bans([ModerationActionType.ban, ModerationActionType.unban]),
  removals([
    ModerationActionType.deletePost,
    ModerationActionType.deleteComment,
    ModerationActionType.deleteStory,
    ModerationActionType.deleteProfilePicture,
  ]),
  resolved([ModerationActionType.resolve]),
  roles([ModerationActionType.roleChange]),
  restored([ModerationActionType.restoreContent]);

  const AuditFilter(this.types);
  final List<ModerationActionType> types;
}

/// Ergebnis von [ModerationApiService.restoreContent].
sealed class RestoreResult {
  const RestoreResult();
}

/// 200: der NEUE Log-Eintrag (restore_content) kommt mit.
final class RestoreOk extends RestoreResult {
  final ModerationLogEntry entry;
  const RestoreOk(this.entry);
}

/// 404: nichts (mehr) im Archiv: schon wiederhergestellt oder Frist um.
final class RestoreGone extends RestoreResult {
  const RestoreGone();
}

/// 409: Archiv da, aber Wiederherstellen geht nicht (z.B. Post weg).
final class RestoreConflict extends RestoreResult {
  const RestoreConflict();
}

/// 403: Rangregel (Besitzer ist inzwischen gleich-/hoeherrangig).
final class RestoreForbidden extends RestoreResult {
  const RestoreForbidden();
}

final class RestoreFailed extends RestoreResult {
  const RestoreFailed();
}

/// Alles unter /admin/... . Die Rechte prueft das Backend (403), die App
/// blendet den Einstieg nur aus.
class ModerationApiService {
  static String get _baseUrl => UserApiService.baseUrl;

  /// Die Queue, sortiert vom Backend (meiste Meldungen zuerst).
  /// null = Fehler (Netz, 403, kaputtes JSON), [] = wirklich leer.
  static Future<List<ReportQueueItem>?> getReports({
    ReportStatus status = ReportStatus.pending,
    int skip = 0,
    int limit = 20,
  }) async {
    try {
      final response = await ApiClient.get(
        Uri.parse(
          '$_baseUrl/admin/reports'
          '?status=${status.apiValue}&skip=$skip&limit=$limit',
        ),
      );
      if (response.statusCode == 200) {
        final data =
            jsonDecode(utf8.decode(response.bodyBytes)) as List<dynamic>;
        // fromJson liefert null bei unbekanntem Typ -> nonNulls filtert die raus.
        return data
            .map((e) => ReportQueueItem.fromJson(e as Map<String, dynamic>))
            .nonNulls
            .toList();
      }
    } catch (_) {
      // kein Netz / kaputtes JSON -> unten null
    }
    return null;
  }

  /// Massnahmen gegen MICH (GET /users/moderation), neueste zuerst. Liegt
  /// unter /users, gehoert inhaltlich aber hierher. Ohne Paginierung: 50
  /// reichen fuer jeden normalen Account.
  /// null = Fehler, [] = keine Massnahmen.
  static Future<List<MyModerationAction>?> getMyActions() async {
    try {
      final response = await ApiClient.get(
        Uri.parse('$_baseUrl/users/moderation?limit=50'),
      );
      if (response.statusCode == 200) {
        final data =
            jsonDecode(utf8.decode(response.bodyBytes)) as List<dynamic>;
        return data
            .map((e) => MyModerationAction.fromJson(e as Map<String, dynamic>))
            .nonNulls
            .toList();
      }
    } catch (_) {
      // kein Netz / kaputtes JSON -> unten null
    }
    return null;
  }

  /// Detailansicht eines Users fuer Mods (GET /admin/users/{id}): Profil,
  /// Sperrstatus, Meldezahlen und die letzten 10 Massnahmen.
  static Future<UserDetailResult> getUserDetail(int userId) async {
    try {
      final response = await ApiClient.get(
        Uri.parse('$_baseUrl/admin/users/$userId'),
      );
      switch (response.statusCode) {
        case 200:
          final data =
              jsonDecode(utf8.decode(response.bodyBytes))
                  as Map<String, dynamic>;
          return UserDetailOk(AdminUserDetail.fromJson(data));
        case 400:
        case 403:
          return const UserDetailForbidden();
        case 404:
          return const UserDetailNotFound();
      }
    } catch (_) {
      // kein Netz / kaputtes JSON -> unten Failed
    }
    return const UserDetailFailed();
  }

  /// Audit-Log (nur Admin), neueste zuerst. Alle Filter kombinierbar.
  /// null = Fehler, [] = Seite leer (= Ende erreicht).
  static Future<List<ModerationLogEntry>?> getActions({
    AuditFilter filter = AuditFilter.all,
    int? moderatorId,
    int? targetUserId,
    int skip = 0,
    int limit = 30,
  }) async {
    // Uri.replace statt String-Bauen: ein Listen-Wert wird zu mehrfachem
    // ?action=delete_post&action=delete_comment..., und Uri kodiert sauber.
    final uri = Uri.parse('$_baseUrl/admin/actions').replace(
      queryParameters: <String, dynamic>{
        if (filter.types.isNotEmpty)
          'action': [for (final t in filter.types) t.apiValue],
        if (moderatorId != null) 'moderator_id': '$moderatorId',
        if (targetUserId != null) 'target_user_id': '$targetUserId',
        'skip': '$skip',
        'limit': '$limit',
      },
    );
    try {
      final response = await ApiClient.get(uri);
      if (response.statusCode == 200) {
        final data =
            jsonDecode(utf8.decode(response.bodyBytes)) as List<dynamic>;
        return data
            .map((e) => ModerationLogEntry.fromJson(e as Map<String, dynamic>))
            .toList();
      }
    } catch (_) {
      // kein Netz / kaputtes JSON -> unten null
    }
    return null;
  }

  /// Nur Admin. Holt einen entfernten Inhalt aus dem Archiv zurueck.
  static Future<RestoreResult> restoreContent(int actionId) async {
    try {
      final response = await ApiClient.post(
        Uri.parse('$_baseUrl/admin/actions/$actionId/restore'),
      );
      switch (response.statusCode) {
        case 200:
          final data =
              jsonDecode(utf8.decode(response.bodyBytes))
                  as Map<String, dynamic>;
          return RestoreOk(ModerationLogEntry.fromJson(data));
        case 404:
          return const RestoreGone();
        case 409:
          return const RestoreConflict();
        case 403:
          return const RestoreForbidden();
      }
    } catch (_) {
      // kein Netz / kaputtes JSON -> unten Failed
    }
    return const RestoreFailed();
  }

  /// Erledigt ALLE offenen Meldungen zu einem Ziel.
  /// 404 = "keine offenen Meldungen mehr" (z.B. hat ein anderer Mod schneller
  /// geklickt) -> Ziel trotzdem erreicht, also auch true.
  static Future<bool> resolve(ReportQueueItem item, ReportStatus status) async {
    assert(
      status != ReportStatus.pending,
      'resolve nur mit dismissed/actionTaken',
    );
    try {
      final response = await ApiClient.post(
        Uri.parse('$_baseUrl/admin/reports/resolve'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'target_type': item.target.apiValue,
          'target_id': item.targetId,
          'status': status.apiValue,
        }),
      );
      return response.statusCode == 200 || response.statusCode == 404;
    } catch (_) {
      return false;
    }
  }

  /// Sperrt einen User. days == null = dauerhaft (nur Admin, sonst 403).
  /// reason ist hier FREITEXT (1-500), keine Kategorie wie beim Entfernen.
  static Future<ModerationResult> banUser(
    int userId, {
    int? days,
    required String reason,
  }) async {
    try {
      final response = await ApiClient.post(
        Uri.parse('$_baseUrl/admin/users/$userId/ban'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'days': days, // null wird als JSON null geschickt -> dauerhaft
          'reason': reason.trim(),
        }),
      );
      return _toResult(response.statusCode, ok: const {200});
    } catch (_) {
      return ModerationResult.failed;
    }
  }

  /// 400 = "user is not banned" -> Ziel erreicht, also ok.
  static Future<ModerationResult> unbanUser(int userId) async {
    try {
      final response = await ApiClient.delete(
        Uri.parse('$_baseUrl/admin/users/$userId/ban'),
      );
      return _toResult(response.statusCode, ok: const {200, 400});
    } catch (_) {
      return ModerationResult.failed;
    }
  }

  /// Entfernt den gemeldeten Inhalt. Bei Post/Kommentar/Story setzt das
  /// Backend die offenen Meldungen selbst auf action_taken. Beim Profilbild
  /// NICHT, dort muss der Aufrufer danach selbst resolve aufrufen.
  /// 404 = schon weg (anderer Mod war schneller) -> ok.
  static Future<ModerationResult> removeContent(
    ReportQueueItem item,
    ReportReason reason, {
    String? details,
  }) async {
    // Eigener switch statt '${apiValue}s': die Pfade sind plural, und beim
    // User geht es ums Profilbild. Exhaustive -> neues Ziel = Compile-Fehler.
    final path = switch (item.target) {
      ReportTarget.post => 'posts/${item.targetId}',
      ReportTarget.comment => 'comments/${item.targetId}',
      ReportTarget.story => 'stories/${item.targetId}',
      ReportTarget.user => 'users/${item.targetId}/profile-picture',
    };
    final trimmed = details?.trim();
    try {
      final response = await ApiClient.delete(
        Uri.parse('$_baseUrl/admin/$path'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'reason': reason.apiValue,
          // leer weglassen, sonst 422 (min_length=1)
          if (trimmed != null && trimmed.isNotEmpty) 'details': trimmed,
        }),
      );
      // Profilbild: 400 heisst "kein Bild" ODER "nicht dich selbst" ->
      // bewusst NICHT als ok werten, damit nichts still verschluckt wird.
      return _toResult(response.statusCode, ok: const {204, 404});
    } catch (_) {
      return ModerationResult.failed;
    }
  }

  /// Nur Admin. Rolle per .name: die Enum-Namen sind genau die API-Werte.
  /// reason ist optional; leer -> Schluessel weglassen ("" waere ein 422).
  /// 400 (hat die Rolle schon / gesperrt befoerdern) -> failed, die UI
  /// verhindert beides vorher.
  static Future<ModerationResult> changeRole(
    int userId,
    UserRole role, {
    String? reason,
  }) async {
    final trimmed = reason?.trim();
    try {
      final response = await ApiClient.patch(
        Uri.parse('$_baseUrl/admin/users/$userId/role'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'role': role.name,
          if (trimmed != null && trimmed.isNotEmpty) 'reason': trimmed,
        }),
      );
      return _toResult(response.statusCode, ok: const {200});
    } catch (_) {
      return ModerationResult.failed;
    }
  }

  /// 403 = Rangregel (nur niedrigere Rollen) bzw. Mod-Limit -> eigene Meldung.
  static ModerationResult _toResult(int code, {required Set<int> ok}) {
    if (ok.contains(code)) return ModerationResult.ok;
    if (code == 403) return ModerationResult.forbidden;
    return ModerationResult.failed;
  }
}

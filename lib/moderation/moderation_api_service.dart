import 'dart:convert';

import '../api_client.dart';
import '../user_api_service.dart';
import 'report_queue_item.dart';

/// Status einer Meldung. apiValue = Query-Parameter `status` bzw. der Wert
/// beim Resolve. Bewusst nicht .name (action_taken vs. actionTaken).
enum ReportStatus {
  pending('pending'),
  dismissed('dismissed'),
  actionTaken('action_taken');

  const ReportStatus(this.apiValue);
  final String apiValue;
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
      final response = await ApiClient.get(Uri.parse(
        '$_baseUrl/admin/reports'
        '?status=${status.apiValue}&skip=$skip&limit=$limit',
      ));
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

  /// Erledigt ALLE offenen Meldungen zu einem Ziel.
  /// 404 = "keine offenen Meldungen mehr" (z.B. hat ein anderer Mod schneller
  /// geklickt) -> Ziel trotzdem erreicht, also auch true.
  static Future<bool> resolve(
    ReportQueueItem item,
    ReportStatus status,
  ) async {
    assert(status != ReportStatus.pending, 'resolve nur mit dismissed/actionTaken');
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
}

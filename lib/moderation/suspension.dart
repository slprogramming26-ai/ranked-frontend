import 'dart:convert';

import 'package:http/http.dart' as http;

/// Eine Account-Sperre, so wie sie aus einer 403-Antwort kommt.
///
/// Das Backend schickt sie (heute oder spaeter) in einer von zwei Formen:
///   (a) String:  {"detail": "account suspended until 2026-10-13T12:00:00+00:00"}
///   (b) Map:     {"detail": {"code": "account_suspended",
///                            "banned_until": "2026-10-13T12:00:00+00:00",
///                            "ban_reason": "Spam"}}
/// Wir verstehen beide, damit das Backend umstellen kann, ohne dass die App
/// bricht. Dauerhaft = 9999-12-31T00:00:00+00:00.
class Suspension {
  final DateTime until; // schon in Ortszeit
  final String? reason; // nur bei Form (b), sonst null

  const Suspension({required this.until, this.reason});

  /// Dauerhaft gesperrt? Per Jahr pruefen, nicht per String-Vergleich:
  /// nach .toLocal() kann aus 9999-12-31 00:00 UTC z.B. 9999-12-30 19:00
  /// werden, das Jahr bleibt aber 9999.
  bool get isPermanent => until.year >= 9999;

  // Fuer Form (a). Die Klammer (.+) faengt alles nach "until " ein.
  static final _untilPattern = RegExp(r'^account suspended until (.+)$');

  /// Liefert eine [Suspension], wenn [response] eine Sperre meldet,
  /// sonst null (z.B. ein ganz normales 403 wie spaeter bei der Rangregel).
  ///
  /// Darf NIE werfen: Diese Methode laeuft spaeter in ApiClient._send fuer
  /// jedes 403, und ein Crash dort wuerde den eigentlichen Request kaputt
  /// machen.
  static Suspension? fromResponse(http.Response response) {
    if (response.statusCode != 403) return null;

    // Body lesen. bodyBytes + utf8 statt response.body, sonst gehen Umlaute
    // im Grund kaputt. Kein/kaputtes JSON -> keine Sperre.
    final Object? body;
    try {
      body = jsonDecode(utf8.decode(response.bodyBytes));
    } catch (_) {
      return null;
    }
    if (body is! Map) return null;
    final detail = body['detail'];

    // Je nach Form von detail den Datums-String (+ Grund) herausholen.
    // `is` statt `as`: ein falscher Typ fuehrt zu null statt zu einem Crash.
    String? untilRaw;
    String? reason;
    if (detail is String) {
      // Form (a)
      untilRaw = _untilPattern.firstMatch(detail)?.group(1);
    } else if (detail is Map && detail['code'] == 'account_suspended') {
      // Form (b)
      final rawUntil = detail['banned_until'];
      final rawReason = detail['ban_reason'];
      if (rawUntil is String) untilRaw = rawUntil;
      if (rawReason is String && rawReason.trim().isNotEmpty) {
        reason = rawReason.trim();
      }
    }
    if (untilRaw == null) return null;

    final until = DateTime.tryParse(untilRaw.trim());
    if (until == null) return null;

    return Suspension(until: until.toLocal(), reason: reason);
  }
}

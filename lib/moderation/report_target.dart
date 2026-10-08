// Was gemeldet wird. apiValue ist das URL-Segment: /report/{apiValue}/{id}.
// Wie bei ReportReason bewusst nicht .name: der API-Vertrag soll nicht still
// an einem Dart-Bezeichner haengen.
enum ReportTarget {
  post('post'),
  story('story'),
  comment('comment'),
  user('user');

  const ReportTarget(this.apiValue);
  final String apiValue;

  /// Fuer die Queue. Unbekannter Typ -> null (Eintrag wird uebersprungen),
  /// bewusst KEIN Default: lieber nichts zeigen als den falschen Typ.
  static ReportTarget? fromApi(Object? raw) {
    for (final t in values) {
      if (t.apiValue == raw) return t;
    }
    return null;
  }
}

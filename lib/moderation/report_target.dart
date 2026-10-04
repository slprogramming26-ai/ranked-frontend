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
}

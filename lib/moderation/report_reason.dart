import 'package:ranked/l10n/app_localizations.dart';

// Die Melde-Gruende, die das Backend akzeptiert. apiValue muss EXAKT dem
// Backend-Enum entsprechen, sonst 422. Bewusst nicht .name: sonst wuerde ein
// Umbenennen des Dart-Bezeichners still den API-Vertrag aendern.
// Anzeige-Texte stehen NICHT hier, sondern in den ARBs (siehe label()).
enum ReportReason {
  spam('spam'),
  harassment('harassment'),
  inappropriate('inappropriate'),
  misinformation('misinformation'),
  other('other');

  const ReportReason(this.apiValue);
  final String apiValue;

  /// Fuer die Queue. Unbekannter Grund (z.B. ein neuer im Backend) -> null,
  /// dann faellt nur dieser eine Chip weg statt der ganzen Liste.
  static ReportReason? fromApi(Object? raw) {
    for (final r in values) {
      if (r.apiValue == raw) return r;
    }
    return null;
  }
}

// Uebersetzung erst im Widget: Services haben keinen context.
// Kein default im switch: ein neuer Grund ohne Label ist ein Compile-Fehler.
extension ReportReasonLabel on ReportReason {
  String label(AppLocalizations l10n) => switch (this) {
    ReportReason.spam => l10n.reportReasonSpam,
    ReportReason.harassment => l10n.reportReasonHarassment,
    ReportReason.inappropriate => l10n.reportReasonInappropriate,
    ReportReason.misinformation => l10n.reportReasonMisinformation,
    ReportReason.other => l10n.reportReasonOther,
  };
}

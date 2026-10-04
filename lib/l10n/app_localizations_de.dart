// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get appTitle => 'ranked';

  @override
  String get reportReasonSpam => 'Spam';

  @override
  String get reportReasonHarassment => 'Belästigung oder Mobbing';

  @override
  String get reportReasonInappropriate => 'Unangemessener Inhalt';

  @override
  String get reportReasonMisinformation => 'Falschinformation';

  @override
  String get reportReasonOther => 'Sonstiges';

  @override
  String get reportTitlePost => 'Post melden';

  @override
  String get reportTitleStory => 'Story melden';

  @override
  String get reportTitleComment => 'Kommentar melden';

  @override
  String get reportTitleUser => 'Profil melden';

  @override
  String get reportSuccessPost =>
      'Danke! Der Post wird dir nicht mehr angezeigt.';

  @override
  String get reportSuccessStory =>
      'Danke! Die Story wird dir nicht mehr angezeigt.';

  @override
  String get reportSuccessComment =>
      'Danke! Der Kommentar wird dir nicht mehr angezeigt.';

  @override
  String get reportSuccessUser => 'Danke! Wir schauen uns das an.';

  @override
  String get reportAlreadyPost => 'Du hast diesen Post bereits gemeldet.';

  @override
  String get reportAlreadyStory => 'Du hast diese Story bereits gemeldet.';

  @override
  String get reportAlreadyComment =>
      'Du hast diesen Kommentar bereits gemeldet.';

  @override
  String get reportAlreadyUser => 'Du hast dieses Profil bereits gemeldet.';

  @override
  String get reportDetailsHint => 'Was ist passiert? (optional)';

  @override
  String get reportSend => 'Senden';

  @override
  String get reportFailed => 'Melden fehlgeschlagen. Versuch es später erneut.';

  @override
  String get postDeleteFailed =>
      'Löschen fehlgeschlagen. Versuch es später erneut.';
}

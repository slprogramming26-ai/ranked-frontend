// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'ranked';

  @override
  String get reportReasonSpam => 'Spam';

  @override
  String get reportReasonHarassment => 'Harassment or bullying';

  @override
  String get reportReasonInappropriate => 'Inappropriate content';

  @override
  String get reportReasonMisinformation => 'Misinformation';

  @override
  String get reportReasonOther => 'Other';

  @override
  String get reportTitlePost => 'Report post';

  @override
  String get reportTitleStory => 'Report story';

  @override
  String get reportTitleComment => 'Report comment';

  @override
  String get reportTitleUser => 'Report profile';

  @override
  String get reportSuccessPost => 'Thanks! You won\'t see this post anymore.';

  @override
  String get reportSuccessStory => 'Thanks! You won\'t see this story anymore.';

  @override
  String get reportSuccessComment =>
      'Thanks! You won\'t see this comment anymore.';

  @override
  String get reportSuccessUser => 'Thanks! We\'ll look into it.';

  @override
  String get reportAlreadyPost => 'You already reported this post.';

  @override
  String get reportAlreadyStory => 'You already reported this story.';

  @override
  String get reportAlreadyComment => 'You already reported this comment.';

  @override
  String get reportAlreadyUser => 'You already reported this profile.';

  @override
  String get reportDetailsHint => 'What happened? (optional)';

  @override
  String get reportSend => 'Send';

  @override
  String get reportFailed => 'Report failed. Please try again later.';

  @override
  String get postDeleteFailed =>
      'Couldn\'t delete the post. Please try again later.';
}

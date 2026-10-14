import 'package:flutter/widgets.dart';
import 'package:ranked/l10n/app_localizations.dart';

export 'package:ranked/l10n/time_format.dart';

// Kurzform im Widget: context.l10n.appTitle
// statt AppLocalizations.of(context).appTitle.
extension L10nX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}

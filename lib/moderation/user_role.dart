import 'package:ranked/l10n/app_localizations.dart';

/// Rolle eines Users, so wie `GET /users/` sie liefert.
/// Die Reihenfolge ist der Rang (user < moderator < admin), [canModerate]
/// baut darauf auf.
enum UserRole {
  user,
  moderator,
  admin;

  static UserRole fromApi(Object? raw) {
    return UserRole.values.firstWhere(
          (e) => e.name == raw,
      orElse: () => UserRole.user, // Standardwert bei unbekanntem Typ
    );
  }

  /// Moderator oder hoeher.
  bool get canModerate => index >= UserRole.moderator.index;

  bool get isAdmin => this == UserRole.admin;
}

// Uebersetzung erst im Widget (wie ReportReasonLabel). Kein default im
// switch: eine neue Rolle ohne Label ist ein Compile-Fehler.
extension UserRoleLabel on UserRole {
  String label(AppLocalizations l10n) => switch (this) {
    UserRole.user => l10n.userDetailRoleUser,
    UserRole.moderator => l10n.userDetailRoleModerator,
    UserRole.admin => l10n.userDetailRoleAdmin,
  };
}

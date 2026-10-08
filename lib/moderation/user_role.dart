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

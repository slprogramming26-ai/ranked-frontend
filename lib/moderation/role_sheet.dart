import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../app_colors.dart';
import '../l10n/l10n.dart';
import 'moderation_sheet_parts.dart';
import 'user_role.dart';

/// Ergebnis des Rollen-Sheets. reason ist schon getrimmt, "" = keine
/// Begruendung (changeRole laesst den Schluessel dann weg).
class RoleSelection {
  const RoleSelection({required this.role, required this.reason});

  final UserRole role;
  final String reason;
}

/// Oeffnet das Rollen-Sheet (nur Admin). Rein darstellend wie Ban-/
/// Entfernen-Sheet: gibt Rolle + Begruendung zurueck (null = abgebrochen),
/// den Request macht der Aufrufer.
/// Admin steht bewusst NICHT zur Auswahl: einen Admin kann in der App
/// niemand mehr herabstufen (Rangregel), das geht nur per Skript.
/// [isBanned] -> befoerdern gesperrt (Backend: 400 "cannot promote").
Future<RoleSelection?> showRoleSheet(
  BuildContext context, {
  required String username,
  required UserRole current,
  required bool isBanned,
}) {
  return showModalBottomSheet<RoleSelection>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.3),
    builder: (_) => _RoleSheet(
      username: username,
      current: current,
      isBanned: isBanned,
    ),
  );
}

class _RoleSheet extends StatefulWidget {
  const _RoleSheet({
    required this.username,
    required this.current,
    required this.isBanned,
  });

  final String username;
  final UserRole current;
  final bool isBanned;

  @override
  State<_RoleSheet> createState() => _RoleSheetState();
}

class _RoleSheetState extends State<_RoleSheet> {
  // Backend: reason optional, sonst 1-500 Zeichen (Code-Points -> runes).
  static const _maxReason = 500;
  static const _choices = [UserRole.user, UserRole.moderator];

  late UserRole? _selected = _initial();
  final _reason = TextEditingController();

  @override
  void initState() {
    super.initState();
    _reason.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  /// Aktuelle Rolle oder (gesperrt) Befoerderung -> nicht waehlbar.
  bool _enabled(UserRole role) {
    if (role == widget.current) return false;
    if (widget.isBanned && role.index > widget.current.index) return false;
    return true;
  }

  /// Gibt es genau eine waehlbare Rolle (Normalfall bei 2 Optionen),
  /// ist sie vorausgewaehlt -> ein Tipp weniger.
  UserRole? _initial() {
    final open = _choices.where(_enabled).toList();
    return open.length == 1 ? open.first : null;
  }

  bool get _canSubmit =>
      _selected != null &&
      _enabled(_selected!) &&
      _reason.text.trim().runes.length <= _maxReason;

  void _submit() => Navigator.pop(
    context,
    RoleSelection(role: _selected!, reason: _reason.text.trim()),
  );

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    // Nur relevant, wenn die Sperre wirklich etwas ausgegraut hat.
    final showBannedHint =
        widget.isBanned &&
        _choices.any((r) => r.index > widget.current.index);

    return ModerationSheetFrame(
      title: l10n.roleSheetTitle(widget.username),
      children: [
        for (final role in _choices) ...[
          _RoleOption(
            role: role,
            hint: switch (role) {
              UserRole.user => l10n.roleSheetUserHint,
              UserRole.moderator => l10n.roleSheetModeratorHint,
              UserRole.admin => '', // nie in _choices
            },
            isCurrent: role == widget.current,
            selected: role == _selected,
            onTap: _enabled(role)
                ? () => setState(() => _selected = role)
                : null,
          ),
          const SizedBox(height: 10),
        ],
        if (showBannedHint) ...[
          ModerationInfoRow(l10n.roleSheetBannedHint),
          const SizedBox(height: 10),
        ],
        const SizedBox(height: 10),
        ModerationSectionLabel(l10n.roleSheetReasonLabel),
        const SizedBox(height: 10),
        TextField(
          controller: _reason,
          maxLength: _maxReason,
          minLines: 1,
          maxLines: 4,
          textCapitalization: TextCapitalization.sentences,
          style: TextStyle(color: AppColors.onSurface, fontSize: 15),
          decoration: moderationFieldDecoration(l10n.roleSheetReasonHint),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: FilledButton.icon(
            onPressed: _canSubmit ? _submit : null,
            icon: const Icon(Icons.manage_accounts_outlined, size: 20),
            label: Text(
              l10n.userDetailChangeRole,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              disabledBackgroundColor: AppColors.primary.withValues(
                alpha: 0.35,
              ),
              disabledForegroundColor: Colors.white.withValues(alpha: 0.8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Eine waehlbare Zeile: Icon, Rollenname (+ "Aktuell"), Erklaertext,
/// rechts ein Radio-Kreis. onTap null = ausgegraut.
class _RoleOption extends StatelessWidget {
  const _RoleOption({
    required this.role,
    required this.hint,
    required this.isCurrent,
    required this.selected,
    required this.onTap,
  });

  final UserRole role;
  final String hint;
  final bool isCurrent;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final primary = AppColors.primary;
    final icon = switch (role) {
      UserRole.user => Icons.person_outline_rounded,
      UserRole.moderator => Icons.shield_outlined,
      UserRole.admin => Icons.admin_panel_settings_outlined,
    };

    return Opacity(
      // Aktuelle Rolle bleibt gut lesbar, nur "gesperrt" wird blass.
      opacity: onTap == null && !isCurrent ? 0.45 : 1,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOut,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: selected
                ? primary.withValues(alpha: 0.08)
                : AppColors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected
                  ? primary.withValues(alpha: 0.5)
                  : primary.withValues(alpha: 0.07),
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: primary.withValues(alpha: 0.12),
                ),
                child: Icon(icon, size: 20, color: primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          role.label(l10n),
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.onSurface,
                          ),
                        ),
                        if (isCurrent)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              l10n.roleSheetCurrent,
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppColors.onSurfaceVariant,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      hint,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                selected
                    ? Icons.radio_button_checked_rounded
                    : Icons.radio_button_unchecked_rounded,
                size: 22,
                color: selected ? primary : AppColors.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

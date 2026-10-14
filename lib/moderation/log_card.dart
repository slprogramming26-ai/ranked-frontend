import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../app_colors.dart';
import '../l10n/app_localizations.dart';
import '../l10n/l10n.dart';
import 'moderation_log_entry.dart';
import 'report_queue_item.dart';
import 'report_reason.dart';
import 'user_role.dart';

/// Eine Zeile Audit-Log: was, wann, von wem, warum (+ Inhalt, falls noch da).
/// Unbekannter Typ -> "Unbekannte Aktion" statt wegfiltern.
///
/// Genutzt im User-Detail (letzte Massnahmen) und im Protokoll. Dort steht
/// zusaetzlich, GEGEN wen die Aktion ging ([showTarget]), und die Namen
/// sind antippbar (Filter).
class LogCard extends StatelessWidget {
  final ModerationLogEntry entry;

  /// "gegen @x" anzeigen. Im User-Detail ueberfluessig (man steht im Profil).
  final bool showTarget;

  /// null = Name nicht antippbar.
  final ValueChanged<ReportedUser>? onModeratorTap;
  final ValueChanged<ReportedUser>? onTargetTap;

  /// Unten in der Karte, z.B. der Restore-Button oder ein Badge.
  final Widget? footer;

  const LogCard({
    super.key,
    required this.entry,
    this.showTarget = false,
    this.onModeratorTap,
    this.onTargetTap,
    this.footer,
  });

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final e = entry;
    final red = Colors.red.shade700;

    final (IconData icon, Color color, String title) = switch (e.type) {
      ModerationActionType.ban => (Icons.block_rounded, red, _banTitle(l, e)),
      ModerationActionType.unban => (
        Icons.lock_open_rounded,
        _green,
        l.userDetailLogUnban,
      ),
      ModerationActionType.resolve =>
        e.extra['status'] == 'dismissed'
            ? (
                Icons.do_not_disturb_alt_rounded,
                AppColors.primary,
                l.userDetailLogDismissed,
              )
            : (
                Icons.task_alt_rounded,
                AppColors.primary,
                l.userDetailLogResolved,
              ),
      ModerationActionType.roleChange => (
        Icons.manage_accounts_outlined,
        AppColors.primary,
        l.userDetailLogRoleChange(
          UserRole.fromApi(e.extra['old_role']).label(l),
          UserRole.fromApi(e.extra['new_role']).label(l),
        ),
      ),
      ModerationActionType.restoreContent => (
        Icons.restore_rounded,
        _green,
        l.userDetailLogRestored,
      ),
      ModerationActionType.deletePost => (
        Icons.article_outlined,
        red,
        l.accountStatusRemovedPost,
      ),
      ModerationActionType.deleteComment => (
        Icons.chat_bubble_outline_rounded,
        red,
        l.accountStatusRemovedComment,
      ),
      ModerationActionType.deleteStory => (
        Icons.amp_stories_outlined,
        red,
        l.accountStatusRemovedStory,
      ),
      ModerationActionType.deleteProfilePicture => (
        Icons.hide_image_outlined,
        red,
        l.accountStatusRemovedPicture,
      ),
      null => (
        Icons.help_outline_rounded,
        AppColors.onSurfaceVariant,
        l.userDetailLogUnknown,
      ),
    };

    final date = DateFormat.yMMMd(l.localeName).add_jm().format(e.createdAt);
    final mod = e.moderator;
    final target = e.targetUser;

    // Grund: bei delete_* eine Kategorie -> Chip, sonst (Ban) Freitext.
    final reason = _nonEmpty(e.reason);
    final category = ReportReason.fromApi(e.reason);
    final details = _nonEmpty(e.extra['details'] as String?);
    final snapshot = _nonEmpty(e.contentSnapshot);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.07)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withValues(alpha: 0.12),
                ),
                child: Icon(icon, size: 20, color: color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    // Wrap statt Row: lange Namen brechen um statt zu ueberlaufen.
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        _Meta('$date · '),
                        _Meta(
                          mod == null
                              ? l.userDetailLogDeletedModerator
                              : l.userDetailLogBy(mod.username),
                          onTap: mod == null || onModeratorTap == null
                              ? null
                              : () => onModeratorTap!(mod),
                        ),
                      ],
                    ),
                    if (showTarget) ...[
                      const SizedBox(height: 2),
                      _Meta(
                        target == null
                            ? l.auditLogDeletedTarget
                            : l.auditLogAgainst(target.username),
                        onTap: target == null || onTargetTap == null
                            ? null
                            : () => onTargetTap!(target),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          if (category != null) ...[
            const SizedBox(height: 14),
            _Label(l.accountStatusReasonLabel),
            const SizedBox(height: 6),
            _Badge(category.label(l), color: AppColors.primary),
          ] else if (reason != null) ...[
            const SizedBox(height: 14),
            _Label(l.accountStatusReasonLabel),
            const SizedBox(height: 6),
            _TextBox(reason),
          ],
          if (details != null) ...[
            const SizedBox(height: 14),
            _Label(l.accountStatusNoteLabel),
            const SizedBox(height: 6),
            _TextBox(details),
          ],
          if (snapshot != null) ...[
            const SizedBox(height: 14),
            _Label(l.userDetailLogSnapshotLabel),
            const SizedBox(height: 6),
            _TextBox(snapshot, maxLines: 4),
          ],
          if (footer != null) ...[const SizedBox(height: 14), footer!],
        ],
      ),
    );
  }

  /// "Konto fuer 7 Tage gesperrt" / "dauerhaft". Fehlt `days` ganz (alte
  /// Eintraege), neutral "Konto gesperrt" statt faelschlich "dauerhaft".
  static String _banTitle(AppLocalizations l, ModerationLogEntry e) {
    if (!e.extra.containsKey('days')) return l.userDetailLogBan;
    final days = (e.extra['days'] as num?)?.toInt();
    return days == null
        ? l.accountStatusBannedPermanent
        : l.accountStatusBanned(days);
  }
}

// Gleiches Gruen wie im Kontostatus. AppColors hat keine Erfolgsfarbe.
final _green = Colors.green.shade700;

String? _nonEmpty(String? s) => (s == null || s.trim().isEmpty) ? null : s;

/// Kleine graue Meta-Zeile. Mit onTap in Primaerfarbe = antippbar.
class _Meta extends StatelessWidget {
  final String text;
  final VoidCallback? onTap;
  const _Meta(this.text, {this.onTap});

  @override
  Widget build(BuildContext context) {
    final label = Text(
      text,
      style: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: onTap == null ? FontWeight.w400 : FontWeight.w600,
        color: onTap == null ? AppColors.onSurfaceVariant : AppColors.primary,
      ),
    );
    if (onTap == null) return label;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      // etwas Luft nach oben/unten -> groessere Trefferflaeche
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: label,
      ),
    );
  }
}

// ── Kleinteile (gleicher Look wie in MyModerationScreen / User-Detail) ────

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: GoogleFonts.inter(
      fontSize: 12,
      fontWeight: FontWeight.w700,
      color: AppColors.onSurfaceVariant,
    ),
  );
}

class _Badge extends StatelessWidget {
  final String text;
  final Color color;
  const _Badge(this.text, {required this.color});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Text(
      text,
      style: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: color,
      ),
    ),
  );
}

class _TextBox extends StatelessWidget {
  final String text;
  final int? maxLines;
  const _TextBox(this.text, {this.maxLines});

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: AppColors.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(14),
    ),
    child: Text(
      text,
      maxLines: maxLines,
      overflow: maxLines == null ? null : TextOverflow.ellipsis,
      style: GoogleFonts.inter(
        fontSize: 14,
        height: 1.4,
        color: AppColors.onSurface,
      ),
    ),
  );
}

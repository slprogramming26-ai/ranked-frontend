import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../app_colors.dart';
import '../l10n/l10n.dart';
import 'moderation_sheet_parts.dart';
import 'report_target.dart';

/// Was der Mod nach "Massnahme ergreifen" waehlen kann.
enum ModerationAction { remove, ban, unban, markDone }

/// Stufe 2 der Karten-Aktionen: Liste der Massnahmen, je mit kurzer
/// Erklaerung (fuer neue Mods). Rein darstellend: gibt nur die Wahl zurueck,
/// null = abgebrochen. Was danach passiert, macht die Queue.
///
/// [available] = was angeboten wird (Reihenfolge legt das Sheet fest).
/// [restricted] = Person hat gleichen/hoeheren Rang -> Hinweis oben.
Future<ModerationAction?> showActionSheet(
  BuildContext context, {
  required ReportTarget target,
  required String username,
  required Set<ModerationAction> available,
  bool restricted = false,
}) {
  return showModalBottomSheet<ModerationAction>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.3),
    builder: (sheetContext) {
      final l = sheetContext.l10n;
      final isPicture = target == ReportTarget.user;

      // Eine Zeile pro Massnahme, nur wenn sie angeboten wird.
      Widget? option(
        ModerationAction action,
        IconData icon,
        String title,
        String hint, {
        bool danger = false,
      }) {
        if (!available.contains(action)) return null;
        return _ActionOption(
          icon: icon,
          title: title,
          hint: hint,
          danger: danger,
          onTap: () => Navigator.pop(sheetContext, action),
        );
      }

      final options = [
        option(
          ModerationAction.remove,
          isPicture ? Icons.hide_image_outlined : Icons.delete_outline_rounded,
          switch (target) {
            ReportTarget.post => l.moderationRemoveTitlePost,
            ReportTarget.comment => l.moderationRemoveTitleComment,
            ReportTarget.story => l.moderationRemoveTitleStory,
            ReportTarget.user => l.moderationRemoveTitleProfilePicture,
          },
          isPicture
              ? l.moderationActionRemovePictureHint
              : l.moderationActionRemoveHint,
          danger: true,
        ),
        option(
          ModerationAction.ban,
          Icons.block_rounded,
          l.moderationBanTitle(username),
          l.moderationActionBanHint,
          danger: true,
        ),
        option(
          ModerationAction.unban,
          Icons.lock_open_rounded,
          l.moderationUnban,
          l.moderationUnbanMessage,
        ),
        option(
          ModerationAction.markDone,
          Icons.check_circle_outline_rounded,
          l.moderationMarkDone,
          l.moderationActionMarkDoneHint,
        ),
      ].nonNulls;

      return ModerationSheetFrame(
        title: l.moderationActionSheetTitle,
        children: [
          if (restricted) ...[
            ModerationInfoRow(l.moderationActionRestricted),
            const SizedBox(height: 14),
          ],
          for (final o in options) ...[o, const SizedBox(height: 10)],
        ],
      );
    },
  );
}

/// Eine antippbare Zeile: Icon im Kreis, Titel, darunter die Erklaerung.
/// danger = rot getoent wie die Entfernen/Sperren-Buttons.
class _ActionOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String hint;
  final bool danger;
  final VoidCallback onTap;

  const _ActionOption({
    required this.icon,
    required this.title,
    required this.hint,
    required this.danger,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = danger ? Colors.red.shade700 : AppColors.primary;
    return Material(
      color: AppColors.surfaceContainerLow,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
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
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: danger ? color : AppColors.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      hint,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        height: 1.35,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Icon(
                Icons.chevron_right_rounded,
                color: AppColors.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

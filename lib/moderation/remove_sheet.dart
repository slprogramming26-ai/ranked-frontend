import 'package:flutter/material.dart';

import '../app_colors.dart';
import '../l10n/app_localizations.dart';
import '../l10n/l10n.dart';
import 'moderation_sheet_parts.dart';
import 'report_reason.dart';
import 'report_sheet.dart';
import 'report_target.dart';

/// Oeffnet das Entfernen-Sheet fuer einen gemeldeten Inhalt.
///
/// Rein darstellend: gibt Grund + Notiz zurueck (null = abgebrochen). Den
/// Request macht der Aufrufer, die Queue zeigt dafuer den Spinner in der Karte.
/// [initialReason] = vorausgewaehlter Grund (z.B. der meistgemeldete).
Future<ReportSelection?> showRemoveSheet(
  BuildContext context, {
  required ReportTarget target,
  ReportReason? initialReason,
}) {
  return showModalBottomSheet<ReportSelection>(
    context: context,
    // Ohne das schiebt sich das Sheet nicht ueber die Tastatur.
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.3),
    builder: (_) => _RemoveSheet(target: target, initialReason: initialReason),
  );
}

// Ohne default: ein neues ReportTarget ohne Titel ist ein Compile-Fehler.
// Beim User wird nur das Profilbild entfernt, nicht der Account.
String _title(AppLocalizations l10n, ReportTarget target) => switch (target) {
  ReportTarget.post => l10n.moderationRemoveTitlePost,
  ReportTarget.comment => l10n.moderationRemoveTitleComment,
  ReportTarget.story => l10n.moderationRemoveTitleStory,
  ReportTarget.user => l10n.moderationRemoveTitleProfilePicture,
};

class _RemoveSheet extends StatefulWidget {
  const _RemoveSheet({required this.target, this.initialReason});

  final ReportTarget target;
  final ReportReason? initialReason;

  @override
  State<_RemoveSheet> createState() => _RemoveSheetState();
}

class _RemoveSheetState extends State<_RemoveSheet> {
  // Gleiches Limit + gleiche runes-Pruefung wie im Melde-Sheet.
  static const _maxDetails = 500;

  late ReportReason? _reason = widget.initialReason;
  final _details = TextEditingController();

  @override
  void initState() {
    super.initState();
    _details.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _details.dispose();
    super.dispose();
  }

  bool get _tooLong => _details.text.trim().runes.length > _maxDetails;
  bool get _canSubmit => _reason != null && !_tooLong;

  void _submit() =>
      Navigator.pop(context, ReportSelection(_reason!, _details.text));

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return ModerationSheetFrame(
      title: _title(l10n, widget.target),
      children: [
        ModerationSectionLabel(l10n.moderationRemoveReasonLabel),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final r in ReportReason.values)
              ModerationChip(
                label: r.label(l10n),
                selected: r == _reason,
                onTap: () => setState(() => _reason = r),
              ),
          ],
        ),
        const SizedBox(height: 20),
        TextField(
          controller: _details,
          maxLength: _maxDetails,
          minLines: 2,
          maxLines: 5,
          textCapitalization: TextCapitalization.sentences,
          style: TextStyle(color: AppColors.onSurface, fontSize: 15),
          decoration: moderationFieldDecoration(l10n.moderationRemoveDetailsHint),
        ),
        const SizedBox(height: 4),
        ModerationInfoRow(l10n.moderationRemoveHint),
        const SizedBox(height: 16),
        ModerationDangerButton(
          label: l10n.moderationRemoveConfirm,
          icon: Icons.delete_outline_rounded,
          onPressed: _canSubmit ? _submit : null,
        ),
      ],
    );
  }
}

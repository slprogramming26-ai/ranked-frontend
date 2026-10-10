import 'package:flutter/material.dart';

import '../app_colors.dart';
import '../l10n/l10n.dart';
import 'moderation_sheet_parts.dart';

/// Ergebnis des Ban-Sheets. days == null = dauerhaft.
/// Eigene Klasse, weil ein nacktes `int?` "dauerhaft" und "abgebrochen"
/// nicht unterscheiden koennte.
class BanSelection {
  const BanSelection({required this.days, required this.reason});

  final int? days;
  final String reason;
}

/// Oeffnet das Ban-Sheet. Rein darstellend wie das Entfernen-Sheet: gibt
/// Dauer + Begruendung zurueck (null = abgebrochen), den Request macht der
/// Aufrufer. [isAdmin] schaltet 365 Tage + dauerhaft frei (Mods max. 30,
/// sonst 403). [isBanned] -> Hinweis, dass die laufende Sperre ersetzt wird.
Future<BanSelection?> showBanSheet(
  BuildContext context, {
  required String username,
  required bool isAdmin,
  required bool isBanned,
}) {
  return showModalBottomSheet<BanSelection>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.3),
    builder: (_) => _BanSheet(
      username: username,
      isAdmin: isAdmin,
      isBanned: isBanned,
    ),
  );
}

class _BanSheet extends StatefulWidget {
  const _BanSheet({
    required this.username,
    required this.isAdmin,
    required this.isBanned,
  });

  final String username;
  final bool isAdmin;
  final bool isBanned;

  @override
  State<_BanSheet> createState() => _BanSheetState();
}

class _BanSheetState extends State<_BanSheet> {
  // Backend: reason 1-500 Zeichen (Python zaehlt Code-Points -> runes).
  static const _maxReason = 500;

  // 0 steht intern fuer "dauerhaft". Das Backend nimmt nur days >= 1,
  // die 0 kann also nie mit einer echten Dauer verwechselt werden.
  static const _permanent = 0;
  static const _modDays = [1, 3, 7, 30];
  static const _adminExtra = [365, _permanent];

  // null = noch nichts gewaehlt (bewusst keine Vorauswahl).
  int? _selected;
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

  List<int> get _options =>
      widget.isAdmin ? [..._modDays, ..._adminExtra] : _modDays;

  int get _reasonLength => _reason.text.trim().runes.length;
  bool get _canSubmit =>
      _selected != null && _reasonLength > 0 && _reasonLength <= _maxReason;

  void _submit() => Navigator.pop(
    context,
    BanSelection(
      days: _selected == _permanent ? null : _selected,
      reason: _reason.text.trim(),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return ModerationSheetFrame(
      title: l10n.moderationBanTitle(widget.username),
      children: [
        ModerationSectionLabel(l10n.moderationBanDurationLabel),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final d in _options)
              ModerationChip(
                label: d == _permanent
                    ? l10n.moderationBanPermanent
                    : l10n.moderationBanDays(d),
                selected: d == _selected,
                onTap: () => setState(() => _selected = d),
              ),
          ],
        ),
        const SizedBox(height: 20),
        ModerationSectionLabel(l10n.moderationBanReasonLabel),
        const SizedBox(height: 10),
        TextField(
          controller: _reason,
          maxLength: _maxReason,
          minLines: 2,
          maxLines: 5,
          textCapitalization: TextCapitalization.sentences,
          style: TextStyle(color: AppColors.onSurface, fontSize: 15),
          decoration: moderationFieldDecoration(l10n.moderationBanReasonHint),
        ),
        const SizedBox(height: 4),
        ModerationInfoRow(
          widget.isBanned
              ? l10n.moderationBanHintReplace
              : l10n.moderationBanHintNew,
        ),
        const SizedBox(height: 16),
        ModerationDangerButton(
          label: l10n.moderationBanConfirm,
          icon: Icons.block_rounded,
          onPressed: _canSubmit ? _submit : null,
        ),
      ],
    );
  }
}

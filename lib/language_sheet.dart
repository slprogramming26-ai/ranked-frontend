import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';
import 'l10n/app_localizations.dart';
import 'l10n/l10n.dart';
import 'locale_provider.dart';

/// Anzeigename einer Sprachwahl. Deutsch/English stehen bewusst NICHT in
/// der ARB: Sprachnamen zeigt man immer in ihrer eigenen Sprache, damit man
/// "seine" Sprache auch findet, wenn die App gerade in der falschen steht.
String appLanguageLabel(AppLanguage language, AppLocalizations l) =>
    switch (language) {
      AppLanguage.system => l.settingsLanguageSystem,
      AppLanguage.de => 'Deutsch',
      AppLanguage.en => 'English',
    };

/// Auswahl-Sheet. Gibt die angetippte Sprache zurueck, null = weggewischt.
/// Speichern macht der Aufrufer (LocaleProvider.setLanguage).
Future<AppLanguage?> showLanguageSheet(
  BuildContext context, {
  required AppLanguage current,
}) {
  return showModalBottomSheet<AppLanguage>(
    context: context,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.3),
    builder: (_) => _LanguageSheet(current: current),
  );
}

class _LanguageSheet extends StatelessWidget {
  final AppLanguage current;
  const _LanguageSheet({required this.current});

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
              child: Text(
                l.settingsLanguage,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppColors.onSurface,
                ),
              ),
            ),
            for (final language in AppLanguage.values)
              _LanguageRow(
                label: appLanguageLabel(language, l),
                hint: language == AppLanguage.system
                    ? l.settingsLanguageSystemHint
                    : null,
                selected: language == current,
                onTap: () => Navigator.of(context).pop(language),
              ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _LanguageRow extends StatelessWidget {
  final String label;
  final String? hint;
  final bool selected;
  final VoidCallback onTap;

  const _LanguageRow({
    required this.label,
    required this.hint,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Material(
        color: selected
            ? AppColors.primary.withValues(alpha: 0.10)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: selected
                              ? AppColors.primary
                              : AppColors.onSurface,
                        ),
                      ),
                      if (hint != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          hint!,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                // Platz immer reservieren, damit die Zeilen gleich hoch/breit sind.
                Icon(
                  Icons.check_rounded,
                  size: 20,
                  color: selected ? AppColors.primary : Colors.transparent,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

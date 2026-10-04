import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../app_colors.dart';
import '../l10n/app_localizations.dart';
import '../l10n/l10n.dart';
import '../user_api_service.dart';
import 'report_reason.dart';
import 'report_target.dart';

// Was der User im Sheet ausgewaehlt hat. Das Sheet gibt das per
// Navigator.pop zurueck, beim Wegwischen kommt null.
class ReportSelection {
  const ReportSelection(this.reason, this.details);
  final ReportReason reason;
  final String details;
}

/// Oeffnet das Melde-Sheet fuer [target] mit der [id].
///
/// Gibt `true` zurueck, sobald der User auf "Senden" getippt hat, und zwar
/// direkt nach dem Schliessen, NICHT erst nach der Server-Antwort. So kann der
/// Aufrufer sofort reagieren (Story weiterlaufen lassen, Post ausblenden).
/// Gesendet wird im Hintergrund, die Snackbar kommt, wenn der Server antwortet.
Future<bool> showReportSheet(
  BuildContext context, {
  required ReportTarget target,
  required int id,
}) async {
  // VOR dem await greifen: danach kann der context weg sein
  // (Kommentar-Sheet zu, Story-Viewer geschlossen ...).
  final messenger = ScaffoldMessenger.of(context);
  final l10n = context.l10n;

  final selection = await showModalBottomSheet<ReportSelection>(
    context: context,
    // Ohne das schiebt sich das Sheet nicht ueber die Tastatur.
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.3),
    builder: (_) => _ReportSheet(title: _title(l10n, target)),
  );
  if (selection == null) return false; // weggewischt / abgebrochen

  // Absichtlich nicht abwarten: der Aufrufer soll nicht auf das Netz warten.
  unawaited(_send(messenger, l10n, target, id, selection));
  return true;
}

Future<void> _send(
  ScaffoldMessengerState messenger,
  AppLocalizations l10n,
  ReportTarget target,
  int id,
  ReportSelection selection,
) async {
  int status;
  try {
    status = await UserApiService.report(
      target,
      id,
      selection.reason,
      details: selection.details,
    );
  } catch (_) {
    status = -1; // kein Netz o.ae. -> wie jeder andere Fehler behandeln
  }

  final message = switch (status) {
    201 => _success(l10n, target),
    409 => _already(l10n, target),
    _ => l10n.reportFailed,
  };
  messenger.showSnackBar(SnackBar(content: Text(message)));
}

// Je ein switch pro Textart, ohne default: ein neues ReportTarget ohne Texte
// ist ein Compile-Fehler.
String _title(AppLocalizations l10n, ReportTarget target) => switch (target) {
  ReportTarget.post => l10n.reportTitlePost,
  ReportTarget.story => l10n.reportTitleStory,
  ReportTarget.comment => l10n.reportTitleComment,
  ReportTarget.user => l10n.reportTitleUser,
};

String _success(AppLocalizations l10n, ReportTarget target) => switch (target) {
  ReportTarget.post => l10n.reportSuccessPost,
  ReportTarget.story => l10n.reportSuccessStory,
  ReportTarget.comment => l10n.reportSuccessComment,
  ReportTarget.user => l10n.reportSuccessUser,
};

String _already(AppLocalizations l10n, ReportTarget target) => switch (target) {
  ReportTarget.post => l10n.reportAlreadyPost,
  ReportTarget.story => l10n.reportAlreadyStory,
  ReportTarget.comment => l10n.reportAlreadyComment,
  ReportTarget.user => l10n.reportAlreadyUser,
};

// Zwei Stufen in EINEM Sheet: erst die Grund-Liste, nach dem Tippen auf einen
// Grund die Details-Ansicht. _selected entscheidet, welche zu sehen ist.
class _ReportSheet extends StatefulWidget {
  const _ReportSheet({required this.title});

  final String title;

  @override
  State<_ReportSheet> createState() => _ReportSheetState();
}

class _ReportSheetState extends State<_ReportSheet> {
  // Backend-Limit fuer details. Python zaehlt Code-Points (runes), das
  // TextField zaehlt sichtbare Zeichen: siehe _tooLong.
  static const _maxDetails = 500;

  ReportReason? _selected;
  final _details = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Fuer den Senden-Button (an/aus bei _tooLong).
    _details.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _details.dispose();
    super.dispose();
  }

  // maxLength am TextField zaehlt Grapheme: 👨‍👩‍👧 ist 1 Zeichen, fuer Python
  // aber 5. 500 Grapheme koennen also > 500 Code-Points sein -> 422.
  bool get _tooLong => _details.text.trim().runes.length > _maxDetails;

  void _submit() {
    Navigator.pop(context, ReportSelection(_selected!, _details.text));
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      // Tastatur-Hoehe: schiebt das Sheet nach oben, wenn die Tastatur aufgeht.
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: SafeArea(
          top: false,
          child: AnimatedSize(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            alignment: Alignment.topCenter,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _handle(),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 180),
                  child: _selected == null
                      ? _reasonList(context)
                      : _detailsView(context),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _handle() => Container(
    margin: const EdgeInsets.only(top: 12),
    width: 40,
    height: 4,
    decoration: BoxDecoration(
      color: AppColors.primary.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(10),
    ),
  );

  Widget _header({required String text, VoidCallback? onBack}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 12, 8, 8),
      child: SizedBox(
        height: 48,
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (onBack != null)
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  icon: Icon(Icons.arrow_back_rounded,
                      color: AppColors.onSurface),
                  onPressed: onBack,
                ),
              ),
            Text(
              text,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Stufe 1: die 5 Gruende.
  Widget _reasonList(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      key: const ValueKey('reasons'),
      mainAxisSize: MainAxisSize.min,
      children: [
        _header(text: widget.title),
        for (final reason in ReportReason.values)
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => setState(() => _selected = reason),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        reason.label(l10n),
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.onSurface,
                        ),
                      ),
                    ),
                    Icon(Icons.chevron_right,
                        color: AppColors.onSurfaceVariant),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  // Stufe 2: optionale Details + Senden.
  Widget _detailsView(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      key: const ValueKey('details'),
      mainAxisSize: MainAxisSize.min,
      children: [
        _header(
          text: _selected!.label(l10n),
          onBack: () => setState(() => _selected = null),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: TextField(
            controller: _details,
            maxLength: _maxDetails,
            minLines: 3,
            maxLines: 6,
            textCapitalization: TextCapitalization.sentences,
            style: TextStyle(color: AppColors.onSurface, fontSize: 15),
            decoration: InputDecoration(
              hintText: l10n.reportDetailsHint,
              hintStyle: TextStyle(color: AppColors.onSurfaceVariant),
              filled: true,
              fillColor: AppColors.surfaceContainerHighest,
              counterStyle: TextStyle(color: AppColors.onSurfaceVariant),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton(
              onPressed: _tooLong ? null : _submit,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Text(
                l10n.reportSend,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

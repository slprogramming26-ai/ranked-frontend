import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../app_colors.dart';
import '../l10n/l10n.dart';
import 'report_queue_view.dart';
import 'user_role.dart';

/// Settings -> Moderation. Nur fuer Moderatoren und Admins erreichbar
/// (die Kachel ist sonst unsichtbar; die echte Pruefung macht das Backend).
///
/// Zwei Bereiche: "Meldungen" (alle Mods) und "Protokoll" (nur Admin).
/// Ein normaler Mod sieht keinen Umschalter, nur die Meldungen.
/// "Protokoll" ist vorerst ein Platzhalter (Phase 6).
class ModerationHome extends StatefulWidget {
  final UserRole role;
  const ModerationHome({super.key, required this.role});

  @override
  State<ModerationHome> createState() => _ModerationHomeState();
}

enum _ModTab { reports, audit }

class _ModerationHomeState extends State<ModerationHome> {
  _ModTab _tab = _ModTab.reports;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final isAdmin = widget.role.isAdmin;

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header (wie BlockedAccountsScreen) ──────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    behavior: HitTestBehavior.opaque,
                    child: Icon(
                      Icons.arrow_back,
                      color: AppColors.primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    l.moderationTitle,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: AppColors.onSurface,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ── Umschalter, nur fuer Admins ─────────────────────────────────
            if (isAdmin) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: _SegmentedPill(
                  labels: [l.moderationTabReports, l.moderationTabAudit],
                  selected: _tab.index,
                  onChanged: (i) => setState(() => _tab = _ModTab.values[i]),
                ),
              ),
              const SizedBox(height: 16),
            ],

            Expanded(
              // Ein Mod landet immer bei den Meldungen, egal was in _tab steht.
              child: (!isAdmin || _tab == _ModTab.reports)
                  ? ReportQueueView(role: widget.role)
                  : _Placeholder(
                      icon: Icons.history_rounded,
                      text: l.moderationAuditPlaceholder,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Zwei (oder mehr) gleich breite Segmente in einer Pille. Das aktive
/// Segment gleitet als helle Fläche unter den Text.
class _SegmentedPill extends StatelessWidget {
  final List<String> labels;
  final int selected;
  final ValueChanged<int> onChanged;

  const _SegmentedPill({
    required this.labels,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 42,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(21),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.07)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final segWidth = constraints.maxWidth / labels.length;
          return Stack(
            children: [
              AnimatedPositioned(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                left: segWidth * selected,
                top: 0,
                bottom: 0,
                width: segWidth,
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(17),
                  ),
                ),
              ),
              Row(
                children: [
                  for (var i = 0; i < labels.length; i++)
                    Expanded(
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => onChanged(i),
                        child: Center(
                          child: AnimatedDefaultTextStyle(
                            duration: const Duration(milliseconds: 180),
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: i == selected
                                  ? AppColors.primary
                                  : AppColors.onSurfaceVariant,
                            ),
                            child: Text(labels[i]),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Icon + Text mittig, bis die echten Listen kommen.
class _Placeholder extends StatelessWidget {
  final IconData icon;
  final String text;

  const _Placeholder({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 40, color: AppColors.onSurfaceVariant),
              const SizedBox(height: 12),
              Text(
                text,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: AppColors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      );
}

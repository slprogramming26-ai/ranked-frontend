import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ranked/l10n/l10n.dart';

import '../ui/app_colors.dart';
import 'optin_stages.dart' show OptinVotingStage;
import 'ranking_widgets.dart' show PrimaryButton;

/// Öffnet das Erklär-Sheet fürs Voting (Profil-Ranking).
Future<void> showVotingExplainerSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    // Erlaubt mehr als die halbe Höhe -> auf kleinen Displays scrollbar
    // statt abgeschnitten.
    isScrollControlled: true,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (_) => const VotingExplainerSheet(),
  );
}

/// Das ⓘ neben allem, was "Voting" heißt (Profil-Tab, Schalter beim Posten,
/// Hinweis im Ranking-Opt-in). Klein, aber mit 32er-Tippfläche.
class VotingInfoButton extends StatelessWidget {
  const VotingInfoButton({super.key, this.size = 18});

  final double size;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: () => showVotingExplainerSheet(context),
      tooltip: context.l10n.votingInfoTooltip,
      icon: Icon(Icons.info_outline_rounded, size: size),
      color: AppColors.onSurfaceVariant,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints.tightFor(width: 32, height: 32),
      visualDensity: VisualDensity.compact,
    );
  }
}

///   ━━━━
///   VOTING · 7 TAGE
///   So funktioniert Voting
///   [ Voting-Bühne ]
///   ① Post ins Voting  ② Follower halten  ③ 7 Tage
///   ┌ Anders als das Ranking ┐
///   [ Verstanden ]
class VotingExplainerSheet extends StatelessWidget {
  const VotingExplainerSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              l10n.onboardingWelcomeVotingLabel,
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w900,
                fontStyle: FontStyle.italic,
                letterSpacing: 1,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              l10n.votingExplainerTitle,
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: AppColors.onSurface,
              ),
            ),
            const SizedBox(height: 18),
            // Das Sheet ist offen = sichtbar -> Bühne läuft immer. Beim
            // Schließen wird sie disposed, der Ticker ist dann weg.
            const SizedBox(
              height: 180,
              child: OptinVotingStage(onScreen: true),
            ),
            const SizedBox(height: 20),
            _StepRow(
              icon: Icons.add_photo_alternate_outlined,
              text: l10n.votingExplainerStep1,
            ),
            _StepRow(
              icon: Icons.touch_app_outlined,
              text: l10n.votingExplainerStep2,
            ),
            _StepRow(
              icon: Icons.schedule_rounded,
              text: l10n.votingExplainerStep3,
            ),
            const SizedBox(height: 8),
            _DiffBox(
              title: l10n.votingExplainerDiffTitle,
              text: l10n.votingExplainerDiffText,
            ),
            const SizedBox(height: 20),
            PrimaryButton(
              label: l10n.votingExplainerOk,
              isLoading: false,
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }
}

class _StepRow extends StatelessWidget {
  const _StepRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 18, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.inter(
                fontSize: 15,
                color: AppColors.onSurface,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Die Abgrenzung zum Tagesranking - darf auf keinen Fall fehlen.
class _DiffBox extends StatelessWidget {
  const _DiffBox({required this.title, required this.text});

  final String title;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.leaderboard_rounded,
            size: 20,
            color: AppColors.onSurfaceVariant,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  text,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: AppColors.onSurfaceVariant,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

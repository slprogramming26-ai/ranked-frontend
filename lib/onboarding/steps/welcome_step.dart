import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ranked/l10n/l10n.dart';

import '../../ranking/optin_stages.dart'
    show OptinFeedStage, OptinRateStage, OptinClimbStage, OptinVotingStage;
import '../../ranking/ranking_optin.dart' show StepSection;
import '../../ui/app_colors.dart';
import '../../ui/on_screen_builder.dart';

/// Onboarding Seite 1/5: eine Scroll-Seite im Stil des Ranking-Opt-ins.
///
///   ┌──────────────────────────┐
///   │  Willkommen im Pulse     │  Hero: Social-Media-App,
///   │  [ Feed-Bühne ]          │  "auch ganz ohne Ranking/Voting"
///   │  (i) freiwillig ...      │
///   ├──────────────────────────┤
///   │  RANKING · TÄGLICH       │  Block 1: Bewerten + Aufstieg
///   │  [ Bühne 01 ] [ 03 ]     │
///   ├──────────────────────────┤
///   │  VOTING · 7 TAGE         │  Block 2: Follower voten deine Posts
///   │  [ Voting-Bühne ]        │
///   ├──────────────────────────┤
///   │  Ranking ≠ Voting        │  Abgrenzungs-Karte
///   └──────────────────────────┘
///            ⌄                    wippt, bis man unten war
///
/// Der Scroll-Controller gehört dem Flow: der merkt daran, wann der User
/// unten angekommen ist (Scroll-Gating), und schaltet dann [showScrollHint]
/// aus.
class WelcomeStep extends StatefulWidget {
  const WelcomeStep({
    super.key,
    required this.scrollController,
    required this.showScrollHint,
  });

  final ScrollController scrollController;

  /// true, solange der User noch nicht unten war -> Pfeil wippt.
  final bool showScrollHint;

  @override
  State<WelcomeStep> createState() => _WelcomeStepState();
}

class _WelcomeStepState extends State<WelcomeStep>
    with SingleTickerProviderStateMixin {
  /// Wie weit der Ranking-Block unter dem Hero hervorschaut.
  static const double _peek = 72;

  late final AnimationController _bounce = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat(reverse: true);

  @override
  void didUpdateWidget(WelcomeStep old) {
    super.didUpdateWidget(old);
    // Pfeil ausgeblendet -> nicht unsichtbar weiterwippen (Ticker = Akku).
    if (!widget.showScrollHint) _bounce.stop();
  }

  @override
  void dispose() {
    _bounce.dispose();
    super.dispose();
  }

  /// Tap auf den Pfeil: ein gutes Stück (70 % der Höhe) weiter nach unten.
  void _scrollDown() {
    final c = widget.scrollController;
    if (!c.hasClients) return;
    final pos = c.position;
    c.animateTo(
      math.min(pos.pixels + pos.viewportDimension * 0.7, pos.maxScrollExtent),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeInOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return LayoutBuilder(
      builder: (context, constraints) => Stack(
        children: [
          SingleChildScrollView(
            controller: widget.scrollController,
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
            child: Column(
              children: [
                // Mindestens fast so hoch wie die Seite, damit der Ranking-
                // Block nur unten rausschaut. Auf kleinen Displays darf der
                // Hero auch höher werden (minHeight, nicht height).
                ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: math.max(0, constraints.maxHeight - _peek),
                  ),
                  child: const _Hero(),
                ),
                _BlockHeader(
                  icon: Icons.leaderboard_rounded,
                  label: l10n.onboardingWelcomeRankingLabel,
                  intro: l10n.onboardingWelcomeRankingIntro,
                ),
                StepSection(
                  title: l10n.rankingOptinStep1Title,
                  text: l10n.rankingOptinStep1Text,
                  stage: (onScreen) => OptinRateStage(onScreen: onScreen),
                ),
                StepSection(
                  title: l10n.rankingOptinStep3Title,
                  text: l10n.rankingOptinStep3Text,
                  stage: (onScreen) => OptinClimbStage(onScreen: onScreen),
                ),
                const SizedBox(height: 24),
                _BlockHeader(
                  icon: Icons.favorite_rounded,
                  label: l10n.onboardingWelcomeVotingLabel,
                  intro: l10n.onboardingWelcomeVotingIntro,
                ),
                StepSection(
                  title: l10n.onboardingWelcomeVotingTitle,
                  text: l10n.onboardingWelcomeVotingText,
                  stage: (onScreen) => OptinVotingStage(onScreen: onScreen),
                ),
                const SizedBox(height: 8),
                const _CompareCard(),
              ],
            ),
          ),
          // Wippender Pfeil, solange der User noch nicht unten war.
          Positioned(
            left: 0,
            right: 0,
            bottom: 8,
            child: IgnorePointer(
              ignoring: !widget.showScrollHint,
              child: AnimatedOpacity(
                opacity: widget.showScrollHint ? 1 : 0,
                duration: const Duration(milliseconds: 300),
                child: Center(
                  child: _scrollHintButton(l10n.onboardingWelcomeScrollHint),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _scrollHintButton(String semanticLabel) {
    return AnimatedBuilder(
      animation: _bounce,
      builder: (context, child) => Transform.translate(
        offset: Offset(0, 6 * Curves.easeInOut.transform(_bounce.value)),
        child: child,
      ),
      child: Semantics(
        button: true,
        label: semanticLabel,
        child: Material(
          color: AppColors.surfaceContainerLow,
          shape: const CircleBorder(),
          elevation: 3,
          shadowColor: Colors.black26,
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: _scrollDown,
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Icon(
                Icons.keyboard_arrow_down_rounded,
                size: 28,
                color: AppColors.primary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Hero ────────────────────────────────────────────────────────────────────

/// Ganz oben: Pulse ist eine Social-Media-App - Ranking/Voting sind Extras.
class _Hero extends StatelessWidget {
  const _Hero();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      // In der ConstrainedBox (minHeight) mittig verteilen - ohne Spacer,
      // die bräuchten eine feste Höhe.
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(height: 16),
        Text(
          l10n.onboardingWelcomeTitle,
          textAlign: TextAlign.center,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 44,
            fontWeight: FontWeight.w900,
            height: 1,
            color: AppColors.onSurface,
          ),
        ),
        const SizedBox(height: 14),
        Text(
          l10n.onboardingWelcomeSubtitle,
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: AppColors.onSurfaceVariant,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 24),
        // Die Feed-Bühne pausiert, sobald der Hero aus dem Bild scrollt.
        OnScreenBuilder(
          builder: (context, onScreen, _) =>
              SizedBox(height: 200, child: OptinFeedStage(onScreen: onScreen)),
        ),
        const SizedBox(height: 18),
        _OptionalHint(text: l10n.onboardingWelcomeOptional),
        const SizedBox(height: 16),
      ],
    );
  }
}

/// "Ranking und Voting sind freiwillig ..." als dezente Pille.
class _OptionalHint extends StatelessWidget {
  const _OptionalHint({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_circle_rounded, size: 18, color: AppColors.primary),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              text,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w500,
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

// ─── Block-Überschrift ───────────────────────────────────────────────────────

/// Pille ("RANKING · TÄGLICH") + eine Zeile, worum es geht.
class _BlockHeader extends StatelessWidget {
  const _BlockHeader({
    required this.icon,
    required this.label,
    required this.intro,
  });

  final IconData icon;
  final String label;
  final String intro;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 16, color: Colors.white),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    fontStyle: FontStyle.italic,
                    letterSpacing: 0.8,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Text(
            intro,
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.onSurface,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Abgrenzung ganz unten ───────────────────────────────────────────────────

/// Die zwei Sätze, die man mitnehmen soll: wer bewertet wen.
class _CompareCard extends StatelessWidget {
  const _CompareCard();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _row(Icons.leaderboard_rounded, l10n.onboardingWelcomeCompareRanking),
          const SizedBox(height: 12),
          _row(Icons.favorite_rounded, l10n.onboardingWelcomeCompareVoting),
        ],
      ),
    );
  }

  Widget _row(IconData icon, String text) {
    return Row(
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
              fontWeight: FontWeight.w600,
              color: AppColors.onSurface,
            ),
          ),
        ),
      ],
    );
  }
}

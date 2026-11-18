import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:ranked/l10n/l10n.dart';

import '../core/user_api_service.dart';
import '../profile/profile.dart';
import '../ui/app_colors.dart';
import '../ui/on_screen_builder.dart';
import 'optin_stages.dart';
import 'ranking_widgets.dart';
import 'voting_explainer_sheet.dart';

/// Opt-in-Screen fürs Tagesranking (ranking_enabled != true).
///
/// Eine Scroll-Seite statt alles auf einen Blick - pro Punkt ein eigener
/// Abschnitt mit Platz für eine kleine Animation:
///
///   ┌──────────────────────────┐
///   │        (Badge)           │  Hero: fast ganze Höhe,
///   │   MACH MIT BEIM RANKING  │  Abschnitt 01 schaut unten raus
///   │ Bewerten. Bewertet ...   │  -> "hier geht's weiter"
///   │           ⌄              │
///   ├──────────────────────────┤
///   │   [ Animation 01 ]       │  Abschnitte blenden ein, sobald
///   │ 01 Bewerte täglich ...   │  sie ins Bild scrollen
///   │   [ Animation 02 ]  ...  │
///   ╞══════════════════════════╡
///   │      [ AKTIVIEREN ]      │  fest unten, immer erreichbar
///   │   Hinweis Profil-Ranking │
///   └──────────────────────────┘
class RankingOptinView extends StatefulWidget {
  const RankingOptinView({super.key});

  @override
  State<RankingOptinView> createState() => _RankingOptinViewState();
}

class _RankingOptinViewState extends State<RankingOptinView> {
  bool _isLoading = false;

  /// Wie weit Abschnitt 01 unter dem Hero hervorschaut.
  static const double _peek = 96;

  // Unverändert aus ranking_home.dart übernommen.
  Future<void> _activate() async {
    final profile = context.read<ProfileProvider>();
    setState(() => _isLoading = true);
    await UserApiService.setRankingEnabled(true);
    // forceRefresh: ohne den waere hier ein No-Op, da ProfileProvider schon
    // laengst _hasFetched=true hat -> ranking_enabled bliebe faelschlich false.
    await profile.fetchUser(forceRefresh: true);
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) => ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  children: [
                    SizedBox(
                      height: constraints.maxHeight - _peek,
                      child: const _Hero(),
                    ),
                    StepSection(
                      index: 1,
                      title: l10n.rankingOptinStep1Title,
                      text: l10n.rankingOptinStep1Text,
                      stage: (onScreen) => OptinRateStage(onScreen: onScreen),
                    ),
                    StepSection(
                      index: 2,
                      title: l10n.rankingOptinStep2Title,
                      text: l10n.rankingOptinStep2Text,
                      stage: (onScreen) => OptinRatedStage(onScreen: onScreen),
                    ),
                    StepSection(
                      index: 3,
                      title: l10n.rankingOptinStep3Title,
                      text: l10n.rankingOptinStep3Text,
                      stage: (onScreen) => OptinClimbStage(onScreen: onScreen),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
            _BottomBar(isLoading: _isLoading, onActivate: _activate),
          ],
        ),
      ),
    );
  }
}

// ─── Hero ────────────────────────────────────────────────────────────────────

class _Hero extends StatefulWidget {
  const _Hero();

  @override
  State<_Hero> createState() => _HeroState();
}

class _HeroState extends State<_Hero> with SingleTickerProviderStateMixin {
  /// Der Pfeil unten wippt -> "scroll mal".
  late final AnimationController _bounce = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _bounce.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      children: [
        const Spacer(flex: 3),
        Container(
          width: 88,
          height: 88,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.primary, AppColors.primaryContainer],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.3),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: const Icon(
            Icons.leaderboard_rounded,
            color: Colors.white,
            size: 44,
          ),
        ),
        const SizedBox(height: 28),
        Text(
          l10n.rankingOptinTitle,
          textAlign: TextAlign.center,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 42,
            fontWeight: FontWeight.w900,
            fontStyle: FontStyle.italic,
            color: AppColors.primary,
            height: 1.0,
          ),
        ),
        const SizedBox(height: 14),
        Text(
          l10n.rankingOptinSubtitle,
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: AppColors.onSurfaceVariant,
          ),
        ),
        const Spacer(flex: 2),
        AnimatedBuilder(
          animation: _bounce,
          builder: (context, child) => Transform.translate(
            offset: Offset(0, 6 * Curves.easeInOut.transform(_bounce.value)),
            child: child,
          ),
          child: Icon(
            Icons.keyboard_arrow_down_rounded,
            size: 32,
            color: AppColors.onSurfaceVariant.withValues(alpha: 0.6),
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}

// ─── Abschnitt pro Punkt ─────────────────────────────────────────────────────

/// Ein Abschnitt: Bühne (Animation) + optionale Nummer + Titel + EINE Zeile.
///
/// Blendet ein, sobald er ins Bild scrollt; die Bühne läuft nur, solange er
/// sichtbar ist (siehe [OnScreenBuilder]). Wird auch im Onboarding
/// (welcome_step.dart) benutzt - dort ohne Nummer.
class StepSection extends StatelessWidget {
  const StepSection({
    super.key,
    this.index,
    required this.title,
    required this.text,
    required this.stage,
  });

  /// null -> keine "01"-Zeile.
  final int? index;
  final String title;
  final String text;
  final Widget Function(bool onScreen) stage;

  @override
  Widget build(BuildContext context) {
    return OnScreenBuilder(
      builder: (context, onScreen, revealed) => AnimatedOpacity(
        opacity: revealed ? 1 : 0,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOut,
        child: AnimatedSlide(
          offset: revealed ? Offset.zero : const Offset(0, 0.08),
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeOutCubic,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 28),
            child: Column(
              children: [
                SizedBox(height: 200, child: stage(onScreen)),
                const SizedBox(height: 22),
                if (index != null) ...[
                  Text(
                    index.toString().padLeft(2, '0'),
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      fontStyle: FontStyle.italic,
                      color: AppColors.primary,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 4),
                ],
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppColors.onSurface,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  text,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    color: AppColors.onSurfaceVariant,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Feste Leiste unten ──────────────────────────────────────────────────────

class _BottomBar extends StatelessWidget {
  const _BottomBar({required this.isLoading, required this.onActivate});

  final bool isLoading;
  final VoidCallback onActivate;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 14, 24, 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(
          top: BorderSide(
            color: AppColors.outlineVariant.withValues(alpha: 0.4),
          ),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PrimaryButton(
            label: l10n.rankingOptinButton,
            isLoading: isLoading,
            onPressed: onActivate,
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  l10n.rankingOptinProfileHint,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ),
              const VotingInfoButton(size: 16),
            ],
          ),
        ],
      ),
    );
  }
}

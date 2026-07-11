import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../app_colors.dart';
import 'ranking_provider.dart';
import 'ranking_pages.dart';
import 'ranking_widgets.dart';

// ─── RankingEnabledView ───────────────────────────────────────────────────────
class RankingEnabledView extends StatefulWidget {
  const RankingEnabledView({super.key});

  @override
  State<RankingEnabledView> createState() => _RankingEnabledViewState();
}

class _RankingEnabledViewState extends State<RankingEnabledView> {
  final bool _isLoading = false;
  bool didRanking = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<RankingProvider>(context, listen: false);
      provider.fetchLeaderboard();
      _refreshDidRanking();
    });
  }

  // Holt den "heute schon gerankt?"-Status und baut die UI neu auf (setState!).
  // Wird beim Öffnen UND nach Rückkehr vom Swipen aufgerufen.
  Future<void> _refreshDidRanking() async {
    final ranked = await Provider.of<RankingProvider>(
      context,
      listen: false,
    ).getDidRanking();
    if (mounted) setState(() => didRanking = ranked);
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<RankingProvider>(context);
    final leaderboard = provider.leaderboardData;
    // Persönliche Stats für die Bento-Cards — beide Quellen liegen schon im
    // Provider (userdata bzw. leaderboard.me), kein zusätzlicher Request.
    final streak = (provider.userdata['streak_count'] as num?)?.toInt() ?? 0;
    final myPoints =
        (provider.leaderboardMe?['my_points'] as num?)?.toInt() ?? 0;

    return Scaffold(
      backgroundColor: AppColors.surface,
      // ── AppBar ────────────────────────────────────────────────────────────
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          'Ranked',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 22,
            fontWeight: FontWeight.w900,
            fontStyle: FontStyle.italic,
            color: AppColors.primary,
            letterSpacing: -0.5,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.local_fire_department_rounded,
                  color: AppColors.primary,
                  size: 22,
                ),
                const SizedBox(width: 2),
                Text(
                  '${provider.userdata["streak_count"] ?? 0}',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      // ── Body ──────────────────────────────────────────────────────────────
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () => provider.refreshLeaderboard(),

        child: provider.isLoadingLeaderboard
            ? Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              )
            : Stack(
                children: [
                  CustomScrollView(
                    slivers: [
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const SizedBox(height: 24),

                              // ── Podium ────────────────────────────────────
                              if (leaderboard.length >= 3)
                                Podium(leaderboard: leaderboard)
                              else if (leaderboard.isEmpty)
                                const EmptyLeaderboard()
                              else
                                Podium(leaderboard: leaderboard),

                              const SizedBox(height: 24),

                              // ── Deine Stats (echte Daten statt Fake-Feats) ─
                              Row(
                                children: [
                                  Icon(
                                    Icons.military_tech_rounded,
                                    color: AppColors.tertiary,
                                    size: 22,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'DEINE STATS',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w900,
                                      fontStyle: FontStyle.italic,
                                      color: AppColors.onSurface,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              // Bento grid: heute erhaltene Punkte + Streak
                              Row(
                                children: [
                                  Expanded(
                                    child: BentoCard(
                                      bg: AppColors.tertiaryContainer,
                                      fgColor: AppColors.tertiary,
                                      icon: Icons.bolt_rounded,
                                      value: '$myPoints',
                                      label: 'PUNKTE HEUTE',
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: BentoCard(
                                      bg: AppColors.primaryContainer,
                                      fgColor: const Color(0xFF4c0600),
                                      icon: Icons.local_fire_department,
                                      value: streak == 1
                                          ? '1 Tag'
                                          : '$streak Tage',
                                      label: 'DEIN STREAK',
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 24),

                              // ── Ranks 4+ list ─────────────────────────────
                              if (leaderboard.length > 3)
                                ...leaderboard
                                    .skip(3)
                                    .toList()
                                    .asMap()
                                    .entries
                                    .map(
                                      (e) => Padding(
                                        padding: const EdgeInsets.only(
                                          bottom: 12,
                                        ),
                                        child: RankListTile(
                                          rank: e.key + 4,
                                          entry: e.value,
                                        ),
                                      ),
                                    ),

                              // Bottom padding for FAB
                              const SizedBox(height: 120),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),

                  // ── Sticky: "Du"-Zeile + Bottom Button ────────────────────
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 100,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (provider.leaderboardMe != null)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                            child: LeaderboardMeCard(me: provider.leaderboardMe!),
                          ),
                        BottomActionBar(
                          isLoading: _isLoading,
                          rankedToday: didRanking,
                          onPressed: () async {
                            // RankingPages holt Target + Posts selbst (my_target)
                            // und behandelt Leerzustände intern.
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const RankingPages(),
                              ),
                            );
                            // Zurück vom Swipen -> evtl. gerade gewertet -> Lock neu prüfen.
                            await _refreshDidRanking();
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:ranked/ranking/ranking_api_service.dart';
import 'package:google_fonts/google_fonts.dart';
import '../user_api_service.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'dart:ui';
import '../app_colors.dart';
import 'package:flutter/services.dart';
import 'package:ranked/streak.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ─── RankingHome ─────────────────────────────────────────────────────────────
class RankingHome extends StatefulWidget {
  const RankingHome({super.key});

  @override
  State<RankingHome> createState() => _RankingHomeState();
}

class _RankingHomeState extends State<RankingHome> {
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<RankingProvider>(
        context,
        listen: false,
      )._fetchUserCredentials();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<RankingProvider>(context);

    if (provider.isLoadingHome || provider.userdata.isEmpty) {
      return Scaffold(
        backgroundColor: AppColors.surface,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    if (provider.userdata["ranking_enabled"] == true) {
      return const RankingEnabledView();
    } else {
      // ── Opt-In Screen ──────────────────────────────────────────────────────
      return Scaffold(
        backgroundColor: AppColors.surface,
        body: SafeArea(
          child: Stack(
            children: [
              // Decorative circles
              Positioned(
                top: -80,
                right: -80,
                child: Container(
                  width: 300,
                  height: 300,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primary.withOpacity(0.05),
                  ),
                ),
              ),
              Positioned(
                bottom: -60,
                left: -60,
                child: Container(
                  width: 240,
                  height: 240,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.tertiary.withOpacity(0.05),
                  ),
                ),
              ),
              // Main content
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Spacer(),
                    // Icon badge
                    Center(
                      child: Container(
                        width: 88,
                        height: 88,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppColors.primary,
                              AppColors.primaryContainer,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withOpacity(0.3),
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
                    ),
                    const SizedBox(height: 32),
                    Text(
                      'JOIN THE\nRANKING',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 40,
                        fontWeight: FontWeight.w900,
                        fontStyle: FontStyle.italic,
                        color: AppColors.primary,
                        height: 1.0,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Aktiviere das Ranking und lass dich täglich von der Community bewerten — Productivity, Creativity & Engagement.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        color: AppColors.onSurfaceVariant,
                        height: 1.5,
                      ),
                    ),
                    const Spacer(),
                    // Activate Button
                    _GradientButton(
                      label: 'AKTIVIEREN',
                      isLoading: _isLoading,
                      onPressed: () async {
                        setState(() => _isLoading = true);
                        await UserApiService.setRankingEnabled(true);
                        await provider._fetchUserCredentials();
                        setState(() => _isLoading = false);
                      },
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }
  }
}

// ─── RankingEnabledView ───────────────────────────────────────────────────────
class RankingEnabledView extends StatefulWidget {
  const RankingEnabledView({super.key});

  @override
  State<RankingEnabledView> createState() => _RankingEnabledViewState();
}

class _RankingEnabledViewState extends State<RankingEnabledView> {
  final bool _isLoading = false;
  bool _isToday = true; // Toggle state (Today / Yesterday) — UI only
  bool didRanking = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<RankingProvider>(context, listen: false);
      provider._fetchLeaderboard();
      provider.fetchStreak();
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

    return Scaffold(
      backgroundColor: AppColors.surface,
      // ── AppBar ────────────────────────────────────────────────────────────
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(Icons.menu, color: AppColors.primary),
          onPressed: () {},
        ),
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
                  '${provider.streak}',
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
        onRefresh: () => provider._refreshLeaderboard(),

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
                              // ── Time Toggle ───────────────────────────────
                              _TimeToggle(
                                isToday: _isToday,
                                onToggle: (val) =>
                                    setState(() => _isToday = val),
                              ),
                              const SizedBox(height: 28),

                              // ── Podium ────────────────────────────────────
                              if (leaderboard.length >= 3)
                                _Podium(leaderboard: leaderboard)
                              else if (leaderboard.isEmpty)
                                _EmptyLeaderboard()
                              else
                                _Podium(leaderboard: leaderboard),

                              const SizedBox(height: 24),

                              // ── Daily Feats Header ────────────────────────
                              if (leaderboard.isNotEmpty) ...[
                                Row(
                                  children: [
                                    Icon(
                                      Icons.military_tech_rounded,
                                      color: AppColors.tertiary,
                                      size: 22,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'DAILY FEATS',
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
                                // Bento grid
                                Row(
                                  children: [
                                    Expanded(
                                      child: _BentoCard(
                                        bg: AppColors.tertiaryContainer,
                                        fgColor: AppColors.tertiary,
                                        icon: Icons.trending_up_rounded,
                                        value: '+25%',
                                        label: 'GLOBAL VELOCITY',
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: _BentoCard(
                                        bg: AppColors.primaryContainer,
                                        fgColor: const Color(0xFF4c0600),
                                        icon: Icons.local_fire_department,
                                        value: 'High Heat',
                                        label: 'COMMUNITY PEAK',
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 24),
                              ],

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
                                        child: _RankListTile(
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

                  // ── Sticky Bottom Button ──────────────────────────────────
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 100,
                    child: _BottomActionBar(
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
                  ),
                ],
              ),
      ),
    );
  }
}

// ─── Time Toggle ─────────────────────────────────────────────────────────────
class _TimeToggle extends StatelessWidget {
  final bool isToday;
  final ValueChanged<bool> onToggle;

  const _TimeToggle({required this.isToday, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(50),
      ),
      child: Row(
        children: [
          _ToggleBtn(
            label: 'Today',
            active: isToday,
            onTap: () => onToggle(true),
          ),
          _ToggleBtn(
            label: 'Yesterday',
            active: !isToday,
            onTap: () => onToggle(false),
          ),
        ],
      ),
    );
  }
}

class _ToggleBtn extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _ToggleBtn({
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            gradient: active
                ? LinearGradient(
                    colors: [AppColors.primary, AppColors.primaryContainer],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            borderRadius: BorderRadius.circular(50),
            boxShadow: active
                ? [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : [],
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: active ? Colors.white : AppColors.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Podium ───────────────────────────────────────────────────────────────────
class _Podium extends StatelessWidget {
  final List<Map<String, dynamic>> leaderboard;
  const _Podium({required this.leaderboard});

  // Server liefert die fertige Punkte-Summe (int) — kein Mitteln mehr.
  String _points(Map<String, dynamic> e) =>
      '${(e['total_points'] as num?)?.toInt() ?? 0}';

  @override
  Widget build(BuildContext context) {
    final first = leaderboard[0];
    final second = leaderboard.length > 1 ? leaderboard[1] : null;
    final third = leaderboard.length > 2 ? leaderboard[2] : null;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Rank 2
        Expanded(
          child: _PodiumCard(
            rank: 2,
            entry: second,
            avatarRadius: 32,
            isFirst: false,
            score: second != null ? _points(second) : '-',
          ),
        ),
        // Rank 1 (center, elevated)
        Expanded(
          child: Transform.translate(
            offset: const Offset(0, -16),
            child: _PodiumCard(
              rank: 1,
              entry: first,
              avatarRadius: 44,
              isFirst: true,
              score: _points(first),
            ),
          ),
        ),
        // Rank 3
        Expanded(
          child: _PodiumCard(
            rank: 3,
            entry: third,
            avatarRadius: 32,
            isFirst: false,
            score: third != null ? _points(third) : '-',
          ),
        ),
      ],
    );
  }
}

class _PodiumCard extends StatelessWidget {
  final int rank;
  final Map<String, dynamic>? entry;
  final double avatarRadius;
  final bool isFirst;
  final String score;

  const _PodiumCard({
    required this.rank,
    required this.entry,
    required this.avatarRadius,
    required this.isFirst,
    required this.score,
  });

  @override
  Widget build(BuildContext context) {
    final username = entry?['username'] as String? ?? '—';
    final picUrl = entry?['profile_picture_url'] as String?;

    Color rankBg;
    Color rankFg;
    if (rank == 1) {
      rankBg = AppColors.primary;
      rankFg = Colors.white;
    } else if (rank == 2) {
      rankBg = AppColors.secondaryFixed;
      rankFg = AppColors.secondary;
    } else {
      rankBg = AppColors.tertiaryFixedDim;
      rankFg = AppColors.tertiary;
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            // Avatar ring
            Container(
              padding: isFirst ? const EdgeInsets.all(3) : EdgeInsets.zero,
              decoration: isFirst
                  ? BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.tertiary,
                          AppColors.tertiaryContainer,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.tertiary.withOpacity(0.3),
                          blurRadius: 20,
                          spreadRadius: 2,
                        ),
                      ],
                    )
                  : null,
              child: CircleAvatar(
                radius: avatarRadius,
                backgroundColor: AppColors.surfaceContainerHighest,
                backgroundImage: (picUrl != null && picUrl.isNotEmpty)
                    ? NetworkImage(picUrl)
                    : null,
                child: (picUrl != null && picUrl.isNotEmpty)
                    ? null
                    : Icon(
                        Icons.person,
                        size: avatarRadius,
                        color: AppColors.onSurfaceVariant,
                      ),
              ),
            ),
            // Rank badge
            Positioned(
              bottom: -6,
              right: -6,
              child: Container(
                width: isFirst ? 36 : 28,
                height: isFirst ? 36 : 28,
                decoration: BoxDecoration(
                  color: rankBg,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.surface, width: 2),
                  boxShadow: isFirst
                      ? [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.4),
                            blurRadius: 10,
                          ),
                        ]
                      : [],
                ),
                child: Center(
                  child: isFirst
                      ? const Icon(
                          Icons.workspace_premium_rounded,
                          color: Colors.white,
                          size: 18,
                        )
                      : Text(
                          '$rank',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            color: rankFg,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          username,
          textAlign: TextAlign.center,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.plusJakartaSans(
            fontSize: isFirst ? 15 : 12,
            fontWeight: isFirst ? FontWeight.w800 : FontWeight.w700,
            color: AppColors.onSurface,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          padding: isFirst
              ? const EdgeInsets.symmetric(horizontal: 10, vertical: 4)
              : EdgeInsets.zero,
          decoration: isFirst
              ? BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.primary, AppColors.primaryContainer],
                  ),
                  borderRadius: BorderRadius.circular(50),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.3),
                      blurRadius: 6,
                    ),
                  ],
                )
              : null,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.bolt_rounded,
                size: isFirst ? 14 : 12,
                color: isFirst ? Colors.white : AppColors.primary,
              ),
              Text(
                score,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: isFirst ? 13 : 11,
                  fontWeight: FontWeight.w900,
                  color: isFirst ? Colors.white : AppColors.primary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}

// ─── Rank List Tile ───────────────────────────────────────────────────────────
class _RankListTile extends StatelessWidget {
  final int rank;
  final Map<String, dynamic> entry;

  const _RankListTile({required this.rank, required this.entry});

  @override
  Widget build(BuildContext context) {
    final username = entry['username'] as String? ?? '—';
    final picUrl = entry['profile_picture_url'] as String?;
    final ratings = (entry['total_ratings'] as num?)?.toInt() ?? 0;
    final points = (entry['total_points'] as num?)?.toInt() ?? 0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 32,
            child: Text(
              '#$rank',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w900,
                fontStyle: FontStyle.italic,
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(width: 8),
          CircleAvatar(
            radius: 22,
            backgroundColor: AppColors.surfaceContainerHighest,
            backgroundImage: (picUrl != null && picUrl.isNotEmpty)
                ? NetworkImage(picUrl)
                : null,
            child: picUrl == null
                ? Icon(
                    Icons.person,
                    color: AppColors.onSurfaceVariant,
                    size: 22,
                  )
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  username,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.onSurface,
                  ),
                ),
                Text(
                  '$ratings RATINGS',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: AppColors.onSurfaceVariant,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          Row(
            children: [
              Icon(
                Icons.bolt_rounded,
                size: 16,
                color: AppColors.primary,
              ),
              Text(
                '$points',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Bento Card ───────────────────────────────────────────────────────────────
class _BentoCard extends StatelessWidget {
  final Color bg;
  final Color fgColor;
  final IconData icon;
  final String value;
  final String label;

  const _BentoCard({
    required this.bg,
    required this.fgColor,
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(28),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(icon, size: 36, color: fgColor),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: fgColor,
                    height: 1.0,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: fgColor,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Empty Leaderboard ────────────────────────────────────────────────────────
class _EmptyLeaderboard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Column(
        children: [
          Icon(
            Icons.leaderboard_outlined,
            size: 56,
            color: AppColors.outlineVariant,
          ),
          const SizedBox(height: 16),
          Text(
            'Noch keine Rankings heute',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Bottom Action Bar ────────────────────────────────────────────────────────
class _BottomActionBar extends StatelessWidget {
  final bool isLoading;
  final bool rankedToday;
  final VoidCallback onPressed;

  const _BottomActionBar({
    required this.isLoading,
    required this.rankedToday,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surface.withOpacity(0.7),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.08),
                blurRadius: 40,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 36),
          child: Opacity(
            // rankedToday -> ausgegraut + null onPressed = wirklich deaktiviert.
            opacity: rankedToday ? 0.5 : 1.0,
            child: _GradientButton(
              label: rankedToday
                  ? 'HEUTE SCHON GEWERTET'
                  : 'GET YOUR RANKED PARTNER',
              isLoading: isLoading,
              onPressed: rankedToday ? null : onPressed,
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Gradient Button ──────────────────────────────────────────────────────────
class _GradientButton extends StatelessWidget {
  final String label;
  final bool isLoading;
  final VoidCallback? onPressed;

  const _GradientButton({
    required this.label,
    required this.isLoading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primaryContainer],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.35),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
        child: isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.5,
                ),
              )
            : Text(
                label,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: 1.0,
                ),
              ),
      ),
    );
  }
}

// ─── RankingPages: Tinder-Style Swipe ─────────────────────────────────────────
class RankingPages extends StatefulWidget {
  const RankingPages({super.key});

  @override
  State<RankingPages> createState() => _RankingPagesState();
}

class _RankingPagesState extends State<RankingPages> {
  final CardSwiperController _controller = CardSwiperController();

  // Sammelt pro Post {post_id, direction}. Lokal -> neue Instanz = frische Session.
  final List<Map<String, dynamic>> _swipes = [];

  List<dynamic> _posts = [];
  int? _targetUserId;
  bool _isLoading = true;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final data = await RankingApiService.getRandomTarget(); // {user_data, posts}
    if (!mounted) return;
    setState(() {
      _posts = (data['posts'] as List<dynamic>?) ?? [];
      _targetUserId = data['user_data']?['id'] as int?;
      _isLoading = false;
    });
  }

  bool _onSwipe(int previousIndex, int? currentIndex, CardSwiperDirection direction) {
    final post = _posts[previousIndex];
    final isRight = direction == CardSwiperDirection.right;
    _swipes.add({'post_id': post['id'], 'direction': isRight});
    HapticFeedback.lightImpact();
    return true;
  }

  Future<void> _submitSession() async {
    if (_submitting || _targetUserId == null) return;
    setState(() => _submitting = true);

    final result =
        await RankingApiService.submitSwipeSession(_targetUserId!, _swipes);
    if (!mounted) return;

    if (result['success'] != true) {
      final status = result['status'] as int?;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => _SwipeErrorScreen(
            alreadyVoted: status == 409,
            detail: result['detail'] as String?,
          ),
        ),
      );
      return;
    }

    final provider = Provider.of<RankingProvider>(context, listen: false);
    provider._refreshLeaderboard();
    await Streak.recordActivity();
    provider.refreshStreak();

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => _SwipeResultScreen(result: result)),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppColors.surface,
        body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    if (_posts.isEmpty) {
      return Scaffold(
        backgroundColor: AppColors.surface,
        appBar: AppBar(
          backgroundColor: AppColors.surface,
          elevation: 0,
          scrolledUnderElevation: 0,
          leading: BackButton(color: AppColors.primary),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.inbox_rounded,
                    size: 56, color: AppColors.outlineVariant),
                const SizedBox(height: 16),
                Text(
                  'Aktuell keine Teilnehmer zum Bewerten verfügbar.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
              child: Row(
                children: [
                  BackButton(color: AppColors.primary),
                  Text(
                    'RANK IT',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      fontStyle: FontStyle.italic,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _submitting
                  ? Center(
                      child: CircularProgressIndicator(color: AppColors.primary),
                    )
                  : CardSwiper(
                      controller: _controller,
                      cardsCount: _posts.length,
                      isLoop: false,
                      numberOfCardsDisplayed: _posts.length >= 2 ? 2 : 1,
                      allowedSwipeDirection:
                          const AllowedSwipeDirection.only(left: true, right: true),
                      padding: const EdgeInsets.all(20),
                      onSwipe: _onSwipe,
                      onEnd: _submitSession,
                      cardBuilder:
                          (context, index, hThresh, vThresh) {
                        final post = _posts[index];
                        return _SwipeCard(
                          title: post['title']?.toString() ?? '',
                          content: post['content']?.toString() ?? '',
                          imageUrl: post['image_url']?.toString() ?? '',
                          flag: post['flag']?.toString(),
                          createdAt: DateTime.parse(post['created_at']),
                          horizontalThreshold: hThresh.toDouble(),
                        );
                      },
                    ),
            ),
            // Like / Nope Buttons
            if (!_submitting)
              Padding(
                padding: const EdgeInsets.fromLTRB(40, 8, 40, 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _SwipeActionButton(
                      icon: Icons.close_rounded,
                      color: AppColors.secondary,
                      onTap: () => _controller.swipe(CardSwiperDirection.left),
                    ),
                    _SwipeActionButton(
                      icon: Icons.favorite_rounded,
                      color: AppColors.primary,
                      onTap: () => _controller.swipe(CardSwiperDirection.right),
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

// ─── Swipe Card ───────────────────────────────────────────────────────────────
class _SwipeCard extends StatelessWidget {
  const _SwipeCard({
    required this.title,
    required this.content,
    required this.imageUrl,
    required this.flag,
    required this.createdAt,
    required this.horizontalThreshold, // -100..100
  });

  final String title;
  final String content;
  final String imageUrl;
  final String? flag;
  final DateTime createdAt;
  final double horizontalThreshold;

  @override
  Widget build(BuildContext context) {
    final dateString = DateFormat('dd.MM.yyyy').format(createdAt);
    final progress = (horizontalThreshold.abs() / 100).clamp(0.0, 1.0);
    final isLike = horizontalThreshold > 0;

    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.network(
            imageUrl,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              color: const Color(0xFF240306),
              child: const Icon(Icons.image_not_supported, color: Colors.white),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.5),
                  Colors.transparent,
                  Colors.transparent,
                  Colors.black.withOpacity(0.85),
                ],
                stops: const [0.0, 0.2, 0.55, 1.0],
              ),
            ),
          ),
          if (flag != null && flag!.isNotEmpty)
            Positioned(
              top: 16,
              left: 16,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(50),
                ),
                child: Text(
                  flag!.toUpperCase(),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title.toUpperCase(),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      fontStyle: FontStyle.italic,
                      color: Colors.white,
                      height: 1.0,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    content,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.9),
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    dateString,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: Colors.white70,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // LIKE / NOPE Overlay je nach Zugrichtung
          if (progress > 0.05)
            Positioned(
              top: 28,
              left: isLike ? 24 : null,
              right: isLike ? null : 24,
              child: Opacity(
                opacity: progress,
                child: Transform.rotate(
                  angle: isLike ? -0.3 : 0.3,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: isLike
                            ? AppColors.primary
                            : AppColors.secondary,
                        width: 4,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      isLike ? 'LIKE' : 'NOPE',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        color: isLike
                            ? AppColors.primary
                            : AppColors.secondary,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ─── Swipe Action Button (Nope / Like) ────────────────────────────────────────
class _SwipeActionButton extends StatelessWidget {
  const _SwipeActionButton({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          color: AppColors.surfaceContainer,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.25),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(icon, color: color, size: 30),
      ),
    );
  }
}

// ─── Swipe Result Screen ──────────────────────────────────────────────────────
class _SwipeResultScreen extends StatelessWidget {
  const _SwipeResultScreen({required this.result});

  final Map<String, dynamic> result;

  @override
  Widget build(BuildContext context) {
    final total = result['total_points'] ?? 0;
    final breakdown =
        (result['breakdown'] as Map?)?.cast<String, dynamic>() ?? {};
    final message = result['message']?.toString() ?? '';

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              Center(
                child: Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.primary, AppColors.primaryContainer],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                  ),
                  child:
                      const Icon(Icons.bolt_rounded, color: Colors.white, size: 48),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                '+$total',
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 64,
                  fontWeight: FontWeight.w900,
                  fontStyle: FontStyle.italic,
                  color: AppColors.primary,
                  height: 1.0,
                ),
              ),
              Text(
                'PUNKTE VERGEBEN',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.5,
                  color: AppColors.onSurfaceVariant,
                ),
              ),
              if (message.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ],
              const SizedBox(height: 32),
              ...breakdown.entries
                  .where((e) => (e.value as num? ?? 0) != 0)
                  .map(
                    (e) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            e.key.toUpperCase(),
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.onSurfaceVariant,
                            ),
                          ),
                          Text(
                            '+${e.value}',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.only(bottom: 40),
                child: _GradientButton(
                  label: 'FERTIG',
                  isLoading: false,
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Swipe Error Screen ───────────────────────────────────────────────────────
class _SwipeErrorScreen extends StatelessWidget {
  const _SwipeErrorScreen({required this.alreadyVoted, this.detail});

  final bool alreadyVoted;
  final String? detail;

  @override
  Widget build(BuildContext context) {
    final iconData = alreadyVoted
        ? Icons.event_available_rounded
        : Icons.cloud_off_rounded;
    final iconColor = alreadyVoted ? AppColors.tertiary : AppColors.secondary;
    final iconBg = alreadyVoted
        ? AppColors.tertiaryContainer
        : AppColors.secondaryFixed;
    final headline = alreadyVoted ? 'BEREITS\nGEWERTET' : 'FEHLER';
    final subtitle = alreadyVoted
        ? 'Du hast heute schon abgestimmt.\nMorgen bist du wieder dran!'
        : (detail ?? 'Etwas ist schiefgelaufen. Versuch es später nochmal.');

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              Center(
                child: Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
                  child: Icon(iconData, color: iconColor, size: 44),
                ),
              ),
              const SizedBox(height: 28),
              Text(
                headline,
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 48,
                  fontWeight: FontWeight.w900,
                  fontStyle: FontStyle.italic,
                  color: iconColor,
                  height: 1.0,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: AppColors.onSurfaceVariant,
                  height: 1.5,
                ),
              ),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.only(bottom: 40),
                child: _GradientButton(
                  label: 'ZURÜCK',
                  isLoading: false,
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── RankingProvider ──────────────────────────────────────────────────────────
class RankingProvider extends ChangeNotifier {

  bool _isLoading = false;
  bool _isLoadingHome = false;
  bool _hasFetched = false;
  Map<String, dynamic> _userdata = {};
  List<Map<String, dynamic>> _leaderboardData = [];
  bool _hasFetchedLeaderboard = false;
  bool _isLoadingLeaderboard = false;
  int _streak = 0;

  bool get isLoading => _isLoading;
  bool get isLoadingHome => _isLoadingHome;
  bool get hasFetched => _hasFetched;
  Map<String, dynamic> get userdata => _userdata;
  List<Map<String, dynamic>> get leaderboardData => _leaderboardData;
  bool get hasFetchedLeaderboard => _hasFetchedLeaderboard;
  bool get isLoadingLeaderboard => _isLoadingLeaderboard;
  int get streak => _streak;

  Future<bool> getDidRanking() async {
    final prefs = await SharedPreferences.getInstance();
    return Streak.didActivityToday(prefs);
  }

  Future<void> fetchStreak() async {
    final s = await Streak.getStreakWithExpiry();
    _streak = s;
    notifyListeners();
  }

  Future<void> refreshStreak() async {
    final s = await Streak.getStreakWithExpiry();
    _streak = s;
    notifyListeners();
  }

  void trueLoading() {
    _isLoading = true;
    notifyListeners();
  }

  void falseLoading() {
    _isLoading = false;
    notifyListeners();
  }

  Future<void> _fetchUserCredentials() async {
    if (_hasFetched) return;
    _isLoadingHome = true;
    notifyListeners();

    try {
      final data = await UserApiService.getCurrentUser();
      _userdata = data;
      _hasFetched = true;
    } catch (e) {
      print("Fehler beim Laden: $e");
    } finally {
      _isLoadingHome = false;
      notifyListeners();
    }
  }

  Future<void> _fetchLeaderboard() async {
    if (_hasFetchedLeaderboard) return;
    _isLoadingLeaderboard = true;
    notifyListeners();

    try {
      final data = await RankingApiService.getLeaderboard();
      _leaderboardData = data;
      _hasFetchedLeaderboard = true;
    } catch (e) {
      print("Fehler beim Laden: $e");
    } finally {
      _isLoadingLeaderboard = false;
      notifyListeners();
    }
  }

  Future<void> _refreshLeaderboard() async {
    try {
      final data = await RankingApiService.getLeaderboard();
      _leaderboardData = data;
      _hasFetchedLeaderboard = true;
    } catch (e) {
      print("Fehler beim Laden: $e");
    } finally {
      _isLoadingLeaderboard = false;
      notifyListeners();
    }
  }
}

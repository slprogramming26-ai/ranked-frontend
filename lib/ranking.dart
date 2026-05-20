import 'package:flutter/material.dart';
import 'package:ranked/ranking_api_service.dart';
import "main.dart";
import 'package:google_fonts/google_fonts.dart';
import 'user_api_service.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'dart:ui';
import 'app_colors.dart';

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
      )._fetch_user_credentials();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<RankingProvider>(context);

    if (provider.isLoadingHome || provider.userdata.isEmpty) {
      return const Scaffold(
        backgroundColor: AppColors.surface,
        body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
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
                          gradient: const LinearGradient(
                            colors: [AppColors.primary, AppColors.primaryContainer],
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
                        await provider._fetch_user_credentials();
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
  bool _isLoading = false;
  bool _isToday = true; // Toggle state (Today / Yesterday) — UI only

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<RankingProvider>(context, listen: false)._fetchLeaderboard();
    });
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
          icon: const Icon(Icons.menu, color: AppColors.primary),
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
          IconButton(
            icon: const Icon(
              Icons.local_fire_department_rounded,
              color: AppColors.primary,
            ),
            onPressed: () {},
          ),
        ],
      ),
      // ── Body ──────────────────────────────────────────────────────────────
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () => provider._refreshLeaderboard(),

        child: provider.isLoadingLeaderboard
            ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
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
                                    const Icon(
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
                      onPressed: () async {
                        setState(() => _isLoading = true);
                        final target =
                            await RankingApiService.getRandomTarget();
                        print(target);

                        //hier morgen weiter
                        if (context.mounted) {
                          if (target.isEmpty) {
                            // Fehler oder bereits abgestimmt
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Du hast heute schon abgestimmt oder ein Fehler ist aufgetreten.',
                                ),
                              ),
                            );
                          } else {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    RankingPages(target_user_id: target['id']),
                              ),
                            );
                          }
                        }

                        if (mounted) setState(() => _isLoading = false);
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
                ? const LinearGradient(
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

  double _avgScore(Map<String, dynamic> e) {
    final p = (e['avg_productivity'] as num?)?.toDouble() ?? 0;
    final c = (e['avg_creativity'] as num?)?.toDouble() ?? 0;
    final en = (e['avg_engagement'] as num?)?.toDouble() ?? 0;
    return (p + c + en) / 3;
  }

  String _fmt(double v) => v.toStringAsFixed(1);

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
            score: second != null ? _fmt(_avgScore(second)) : '-',
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
              score: _fmt(_avgScore(first)),
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
            score: third != null ? _fmt(_avgScore(third)) : '-',
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
                      gradient: const LinearGradient(
                        colors: [AppColors.tertiary, AppColors.tertiaryContainer],
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
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, AppColors.primaryContainer],
                  ),
                  borderRadius: BorderRadius.circular(50),
                  boxShadow: [
                    BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 6),
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

  double _avgScore() {
    final p = (entry['avg_productivity'] as num?)?.toDouble() ?? 0;
    final c = (entry['avg_creativity'] as num?)?.toDouble() ?? 0;
    final e = (entry['avg_engagement'] as num?)?.toDouble() ?? 0;
    return (p + c + e) / 3;
  }

  @override
  Widget build(BuildContext context) {
    final username = entry['username'] as String? ?? '—';
    final picUrl = entry['profile_picture_url'] as String?;
    final total = entry['total_ratings'] as int? ?? 0;

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
                ? const Icon(Icons.person, color: AppColors.onSurfaceVariant, size: 22)
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
                  '$total RATINGS',
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
              const Icon(Icons.bolt_rounded, size: 16, color: AppColors.primary),
              Text(
                _avgScore().toStringAsFixed(1),
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
          const Icon(
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
  final VoidCallback onPressed;

  const _BottomActionBar({required this.isLoading, required this.onPressed});

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
          child: _GradientButton(
            label: 'GET YOUR RANKED PARTNER',
            isLoading: isLoading,
            onPressed: onPressed,
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
        gradient: const LinearGradient(
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

// ─── RankingPages (unverändert) ───────────────────────────────────────────────
class RankingPages extends StatefulWidget {
  const RankingPages({super.key, required this.target_user_id});
  final int target_user_id;

  @override
  State<RankingPages> createState() => _RankingPagesState();
}

class _RankingPagesState extends State<RankingPages> {
  List<dynamic> weekPosts = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final data = await RankingApiService.getLastWeekPosts(
      widget.target_user_id,
    );
    if (mounted) {
      setState(() {
        weekPosts = data;
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) return const Center(child: CircularProgressIndicator());

    return Scaffold(
      body: PageView.builder(
        itemCount: weekPosts.length + 4,
        itemBuilder: (context, index) {
          if (index == 0) {
            return Container(
              color: AppColors.surface,
              child: Center(
                child: Text(
                  'Dein daily target:\nScrolle rechts zum Bewerten!',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                  ),
                ),
              ),
            );
          }

          if (index <= weekPosts.length) {
            final postData = weekPosts[index - 1]['post'];
            return SingleRankingPostPage(
              title: postData['title'],
              content: postData['content'],
              imageUrl: postData['image_url'] ?? '',
              createdAt: DateTime.parse(postData['created_at']),
            );
          }

          final sliderIndex = index - weekPosts.length - 1;
          final categories = [
            {'name': 'Productivity', 'label': 'Wie effizient war der Output?'},
            {'name': 'Creativity', 'label': 'Wie originell war der Ansatz?'},
            {'name': 'Engagement', 'label': 'Wie stark war die Wirkung?'},
          ];

          if (sliderIndex < categories.length) {
            return RankedSliderPage(
              category: categories[sliderIndex]['name']!,
              description: categories[sliderIndex]['label']!,
              isLast: sliderIndex == categories.length - 1,
              onChanged: (double value) {
                final provider = Provider.of<RankingProvider>(
                  context,
                  listen: false,
                );
                int intValue = (value * 10).round();
                provider.updateScore(
                  categories[sliderIndex]['name'].toString(),
                  intValue,
                );
              },
              onComplete: () async {
                final provider = Provider.of<RankingProvider>(
                  context,
                  listen: false,
                );
                provider.trueLoading();

                bool success = await RankingApiService.pushRankingScores(
                  widget.target_user_id,
                  provider.scores['Productivity'] ?? 75,
                  provider.scores['Creativity'] ?? 75,
                  provider.scores['Engagement'] ?? 75,
                );

                if (success && context.mounted) {
                  provider.falseLoading();
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const MyHomePage(
                        title: 'Ranked',
                        initialLoggedIn: true,
                      ),
                    ),
                  );
                }
              },
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }
}

// ─── SingleRankingPostPage (unverändert) ──────────────────────────────────────
class SingleRankingPostPage extends StatelessWidget {
  const SingleRankingPostPage({
    super.key,
    required this.title,
    required this.content,
    required this.imageUrl,
    required this.createdAt,
  });

  final String title;
  final String content;
  final String imageUrl;
  final DateTime createdAt;

  @override
  Widget build(BuildContext context) {
    final String dateString = DateFormat('dd.MM.yyyy').format(createdAt);
    final size = MediaQuery.of(context).size;

    return Scaffold(
      extendBody: true,
      extendBodyBehindAppBar: true,
      body: SizedBox(
        height: size.height,
        width: size.width,
        child: Stack(
          children: [
            Positioned.fill(
              child: Image.network(
                imageUrl,
                fit: BoxFit.cover,
                alignment: Alignment.center,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: const Color(0xFF240306),
                  child: const Icon(
                    Icons.image_not_supported,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0.6),
                      Colors.transparent,
                      Colors.transparent,
                      Colors.black.withOpacity(0.85),
                    ],
                    stops: const [0.0, 0.15, 0.6, 1.0],
                  ),
                ),
              ),
            ),
            SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(
                        color: AppColors.tertiaryContainer,
                        shape: BoxShape.circle,
                      ),
                      child: const CircleAvatar(
                        radius: 18,
                        backgroundColor: Colors.grey,
                        child: Icon(
                          Icons.person,
                          size: 20,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'DAILY TARGET',
                          style: GoogleFonts.plusJakartaSans(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            letterSpacing: 0.5,
                          ),
                        ),
                        Text(
                          dateString,
                          style: GoogleFonts.inter(
                            color: Colors.white70,
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 40),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title.toUpperCase(),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          fontStyle: FontStyle.italic,
                          height: 1.0,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        content,
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          color: Colors.white.withOpacity(0.9),
                          height: 1.4,
                        ),
                        maxLines: 4,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 24),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [AppColors.primary, AppColors.primaryContainer],
                          ),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.favorite,
                              color: Colors.white,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'RANK IT',
                              style: GoogleFonts.plusJakartaSans(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── RankedSliderPage (unverändert) ───────────────────────────────────────────
class RankedSliderPage extends StatefulWidget {
  final String category;
  final String description;
  final bool isLast;
  final VoidCallback onComplete;
  final ValueChanged<double> onChanged;

  const RankedSliderPage({
    super.key,
    required this.category,
    required this.description,
    required this.isLast,
    required this.onComplete,
    required this.onChanged,
  });

  @override
  State<RankedSliderPage> createState() => _RankedSliderPageState();
}

class _RankedSliderPageState extends State<RankedSliderPage> {
  late double _currentValue;

  @override
  void initState() {
    super.initState();
    final provider = Provider.of<RankingProvider>(context, listen: false);
    int savedScore = provider.scores[widget.category] ?? 75;
    _currentValue = savedScore / 10.0;
  }

  String getEmoji(double value) {
    if (value >= 9) return '👑';
    if (value >= 8) return '🔥';
    if (value >= 6) return '⚡️';
    if (value >= 4) return '✨';
    if (value >= 2) return '☁️';
    return '❄️';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
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
            bottom: -80,
            left: -80,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.tertiary.withOpacity(0.05),
              ),
            ),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              Text(
                "${widget.category} Score",
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 36,
                  fontWeight: FontWeight.w900,
                  color: AppColors.primaryDark,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                widget.description,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  color: AppColors.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 48),
              Text(
                _currentValue.toStringAsFixed(1),
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 80,
                  fontWeight: FontWeight.w900,
                  color: AppColors.primary,
                ),
              ),
              Text(
                getEmoji(_currentValue),
                style: const TextStyle(fontSize: 48),
              ),
              const SizedBox(height: 48),
              SliderTheme(
                data: SliderThemeData(
                  trackHeight: 60,
                  activeTrackColor: AppColors.surfaceContainer,
                  inactiveTrackColor: AppColors.surfaceContainer,
                  thumbColor: AppColors.primary,
                  overlayColor: AppColors.primary.withOpacity(0.2),
                  thumbShape: const RoundSliderThumbShape(
                    enabledThumbRadius: 30,
                    elevation: 10,
                  ),
                  activeTickMarkColor: Colors.transparent,
                  inactiveTickMarkColor: Colors.transparent,
                ),
                child: Slider(
                  value: _currentValue,
                  min: 0.1,
                  max: 10,
                  onChanged: (value) {
                    setState(() => _currentValue = value);
                    widget.onChanged(value);
                  },
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "LOW",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: Colors.black26,
                      ),
                    ),
                    Text(
                      "PEAK",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: Colors.black26,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              if (widget.isLast)
                Padding(
                  padding: const EdgeInsets.only(bottom: 48),
                  child: Container(
                    width: double.infinity,
                    height: 70,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.primary, AppColors.primaryContainer],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(35),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.3),
                          blurRadius: 15,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: widget.onComplete,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(35),
                        ),
                      ),
                      child: Text(
                        "SUBMIT RANKING",
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 20),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── RankingProvider (unverändert) ────────────────────────────────────────────
class RankingProvider extends ChangeNotifier {
  Map<String, int> _scores = {
    'Productivity': 75,
    'Creativity': 75,
    'Engagement': 75,
  };

  bool _isLoading = false;
  bool _isLoadingHome = false;
  bool _hasFetched = false;
  Map<String, dynamic> _userdata = {};
  List<Map<String, dynamic>> _leaderboardData = [];
  bool _hasFetchedLeaderboard = false;
  bool _isLoadingLeaderboard = false;

  bool get isLoading => _isLoading;
  bool get isLoadingHome => _isLoadingHome;
  bool get hasFetched => _hasFetched;
  Map<String, int> get scores => _scores;
  Map<String, dynamic> get userdata => _userdata;
  List<Map<String, dynamic>> get leaderboardData => _leaderboardData;
  bool get hasFetchedLeaderboard => _hasFetchedLeaderboard;
  bool get isLoadingLeaderboard => _isLoadingLeaderboard;

  void updateScore(String category, int value) {
    _scores[category] = value;
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

  Future<void> _fetch_user_credentials() async {
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

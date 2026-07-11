import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui';
import '../app_colors.dart';

// ─── Podium ───────────────────────────────────────────────────────────────────
class Podium extends StatelessWidget {
  final List<Map<String, dynamic>> leaderboard;
  const Podium({super.key, required this.leaderboard});

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
class RankListTile extends StatelessWidget {
  final int rank;
  final Map<String, dynamic> entry;

  const RankListTile({super.key, required this.rank, required this.entry});

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

// ─── "Du"-Zeile ───────────────────────────────────────────────────────────────
// Sticky Karte mit dem eigenen Stand aus leaderboard.me — sichtbar auch dann,
// wenn man selbst nicht in den Top 7 steht. Drei Zustände:
//   1. my_points == 0  -> noch keine Punkte heute (Rang wäre irreführend)
//   2. my_rank == 1    -> Tagesführung
//   3. sonst           -> Rang + Abstand zum nächsthöheren Platz
class LeaderboardMeCard extends StatelessWidget {
  final Map<String, dynamic> me;

  const LeaderboardMeCard({super.key, required this.me});

  @override
  Widget build(BuildContext context) {
    final rank = (me['my_rank'] as num?)?.toInt() ?? 0;
    final points = (me['my_points'] as num?)?.toInt() ?? 0;
    final toNext = (me['points_to_next'] as num?)?.toInt() ?? 0;

    final hasPoints = points > 0;
    final isFirst = hasPoints && rank == 1;

    final String headline;
    final String subline;
    if (!hasPoints) {
      headline = 'Noch keine Punkte heute';
      subline = 'Poste, um bewertet zu werden';
    } else if (isFirst) {
      headline = 'Du führst heute!';
      subline = 'Verteidige deinen Platz';
    } else {
      headline = 'Platz #$rank';
      subline =
          'Noch $toNext ${toNext == 1 ? 'Punkt' : 'Punkte'} bis zum nächsten Platz';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primaryContainer],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.35),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          // "DU"-Badge an der Stelle, wo die Liste den Avatar hat
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: isFirst
                  ? const Icon(
                      Icons.workspace_premium_rounded,
                      color: Colors.white,
                      size: 22,
                    )
                  : Text(
                      'DU',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  headline,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                Text(
                  subline,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withOpacity(0.85),
                  ),
                ),
              ],
            ),
          ),
          Row(
            children: [
              const Icon(Icons.bolt_rounded, size: 18, color: Colors.white),
              Text(
                '$points',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
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
class BentoCard extends StatelessWidget {
  final Color bg;
  final Color fgColor;
  final IconData icon;
  final String value;
  final String label;

  const BentoCard({
    super.key,
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
class EmptyLeaderboard extends StatelessWidget {
  const EmptyLeaderboard({super.key});

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
class BottomActionBar extends StatelessWidget {
  final bool isLoading;
  final bool rankedToday;
  final VoidCallback onPressed;

  const BottomActionBar({
    super.key,
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
            child: GradientButton(
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
class GradientButton extends StatelessWidget {
  final String label;
  final bool isLoading;
  final VoidCallback? onPressed;

  const GradientButton({
    super.key,
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

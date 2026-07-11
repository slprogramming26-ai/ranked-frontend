import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui';
import '../app_colors.dart';
import 'ranking_provider.dart';

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

import 'package:flutter/material.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import '../app_colors.dart';
import '../net_image.dart';
import '../profile.dart';
import 'ranking_api_service.dart';
import 'ranking_provider.dart';
import 'ranking_widgets.dart' show GradientButton, PopIn;

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
  // Wer bewertet wird — kommt schon in der my_target-Response mit (user_data).
  Map<String, dynamic>? _targetUser;
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
      _targetUser = data['user_data'] as Map<String, dynamic>?;
      _targetUserId = data['user_data']?['id'] as int?;
      _isLoading = false;
    });
  }

  bool _onSwipe(int previousIndex, int? currentIndex, CardSwiperDirection direction) {
    final post = _posts[previousIndex];
    final isRight = direction == CardSwiperDirection.right;
    // setState nur fuer die UI: Fortschrittsbalken + Zaehler bauen neu.
    setState(() {
      _swipes.add({'post_id': post['id'], 'direction': isRight});
    });
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
    provider.refreshLeaderboard();
    // Punkte/Streak haben sich durch die Session geaendert -> forceRefresh.
    Provider.of<ProfileProvider>(context, listen: false)
        .fetchUser(forceRefresh: true);
    Streak.markRankedToday();

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
            // Header: Story-Progress + Target-User + Karten-Zaehler
            _SessionHeader(
              targetUser: _targetUser,
              totalCards: _posts.length,
              swipedCards: _swipes.length,
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
                      // Bis zu 3 Karten sichtbar: hintere lugen skaliert
                      // darunter hervor -> echter Deck-Look statt Einzelkarte.
                      numberOfCardsDisplayed:
                          _posts.length < 3 ? _posts.length : 3,
                      backCardOffset: const Offset(0, 36),
                      scale: 0.92,
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
                      size: 60,
                      onTap: () => _controller.swipe(CardSwiperDirection.left),
                    ),
                    // Like ist groesser + gradient-gefuellt: die "Haupt-Aktion".
                    _SwipeActionButton(
                      icon: Icons.favorite_rounded,
                      color: AppColors.primary,
                      size: 72,
                      filled: true,
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

// ─── Session Header ───────────────────────────────────────────────────────────
// Story-Style Fortschritt (ein Segment pro Karte), wer bewertet wird und ein
// Zaehler-Chip. Rein visuell — der Fortschritt kommt aus _swipes.length.
class _SessionHeader extends StatelessWidget {
  const _SessionHeader({
    required this.targetUser,
    required this.totalCards,
    required this.swipedCards,
  });

  final Map<String, dynamic>? targetUser;
  final int totalCards;
  final int swipedCards;

  @override
  Widget build(BuildContext context) {
    final username = targetUser?['username']?.toString() ?? '';
    final picUrl = targetUser?['profile_picture_url']?.toString();
    // Aktuelle Kartennummer: eins weiter als die schon gewerteten, aber nie
    // ueber das Deck hinaus (letzte Karte bleibt "5/5").
    final current = (swipedCards + 1).clamp(1, totalCards == 0 ? 1 : totalCards);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Column(
        children: [
          // ── Fortschrittssegmente ────────────────────────────────────────
          Row(
            children: List.generate(totalCards, (i) {
              final done = i < swipedCards;
              return Expanded(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 350),
                  curve: Curves.easeOutCubic,
                  height: 5,
                  margin:
                      EdgeInsets.only(right: i == totalCards - 1 ? 0 : 6),
                  decoration: BoxDecoration(
                    gradient: done
                        ? LinearGradient(
                            colors: [
                              AppColors.primary,
                              AppColors.primaryContainer,
                            ],
                          )
                        : null,
                    color: done ? null : AppColors.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 10),
          // ── Zurueck + Target-User + Zaehler ─────────────────────────────
          Row(
            children: [
              BackButton(color: AppColors.primary),
              const Spacer(),
              CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.surfaceContainerHighest,
                // Avatar-Radius 18 -> Durchmesser 36 als Dekodier-Breite.
                backgroundImage: (picUrl != null && picUrl.isNotEmpty)
                    ? netImage(context, picUrl, logicalWidth: 36)
                    : null,
                child: (picUrl != null && picUrl.isNotEmpty)
                    ? null
                    : Icon(
                        Icons.person,
                        size: 18,
                        color: AppColors.onSurfaceVariant,
                      ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'DU BEWERTEST',
                    style: GoogleFonts.inter(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.5,
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    username.isEmpty ? '—' : '@$username',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      fontStyle: FontStyle.italic,
                      color: AppColors.onSurface,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              // Zaehler-Chip "2/5"
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainer,
                  borderRadius: BorderRadius.circular(50),
                ),
                child: Text(
                  '$current/$totalCards',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
        ],
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
    final glowColor = isLike ? AppColors.primary : AppColors.secondary;

    return Container(
      // Glow waehrend des Ziehens: farbiger Schatten, Staerke folgt progress.
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
          if (progress > 0.05)
            BoxShadow(
              color: glowColor.withValues(alpha: 0.45 * progress),
              blurRadius: 36,
              spreadRadius: 2,
            ),
        ],
      ),
      // Border als foregroundDecoration: liegt UEBER dem Bild, sonst wuerde
      // das Cover-Foto sie einfach zudecken.
      foregroundDecoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        border: progress > 0.05
            ? Border.all(
                color: glowColor.withValues(alpha: progress),
                width: 3,
              )
            : null,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Stack(
        fit: StackFit.expand,
        children: [
          Image(
            // Karte ist bildschirmbreit -> logische Bildschirmbreite als
            // Dekodier-Breite.
            image: netImage(
              context,
              imageUrl,
              logicalWidth: MediaQuery.sizeOf(context).width,
            ),
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
                  Colors.black.withValues(alpha: 0.5),
                  Colors.transparent,
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.85),
                ],
                stops: const [0.0, 0.2, 0.55, 1.0],
              ),
            ),
          ),
          // Farb-Wash von der Zugseite her (Like: von links, Nope: von rechts)
          if (progress > 0.05)
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin:
                      isLike ? Alignment.centerLeft : Alignment.centerRight,
                  end: isLike ? Alignment.centerRight : Alignment.centerLeft,
                  colors: [
                    glowColor.withValues(alpha: 0.35 * progress),
                    Colors.transparent,
                  ],
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
                      color: Colors.white.withValues(alpha: 0.9),
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
      ),
    );
  }
}

// ─── Swipe Action Button (Nope / Like) ────────────────────────────────────────
// Stateful wegen der Press-Animation: onTapDown/-Up steuern _pressed, der
// AnimatedScale federt den Button beim Druecken kurz ein.
class _SwipeActionButton extends StatefulWidget {
  const _SwipeActionButton({
    required this.icon,
    required this.color,
    required this.onTap,
    this.size = 64,
    this.filled = false,
  });

  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final double size;
  final bool filled;

  @override
  State<_SwipeActionButton> createState() => _SwipeActionButtonState();
}

class _SwipeActionButtonState extends State<_SwipeActionButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? 0.82 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            gradient: widget.filled
                ? LinearGradient(
                    colors: [AppColors.primary, AppColors.primaryContainer],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            color: widget.filled ? null : AppColors.surfaceContainer,
            shape: BoxShape.circle,
            border: widget.filled
                ? null
                : Border.all(color: AppColors.outlineVariant, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: widget.color.withValues(alpha: widget.filled ? 0.4 : 0.2),
                blurRadius: widget.filled ? 18 : 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Icon(
            widget.icon,
            color: widget.filled ? Colors.white : widget.color,
            size: widget.size * 0.45,
          ),
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
    // toInt: der Count-up unten braucht einen echten int fuer den IntTween.
    final total = (result['total_points'] as num? ?? 0).toInt();
    final breakdown =
        (result['breakdown'] as Map?)?.cast<String, dynamic>() ?? {};
    // Als Liste, damit jede Zeile ueber ihren Index ihr Stagger-Delay bekommt.
    final breakdownRows = breakdown.entries
        .where((e) => (e.value as num? ?? 0) != 0)
        .toList();
    final message = result['message']?.toString() ?? '';
    // Belohnung fuer den BEWERTER (seit XP-Update in der Response enthalten).
    final xpGained = (result['xp_gained'] as num?)?.toInt() ?? 0;
    final streak = (result['streak'] as num?)?.toInt() ?? 0;

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              // Badge poppt elastisch rein (leichtes Ueberschwingen durch
              // elasticOut). Opacity muss geclampt werden, weil elasticOut
              // ueber 1.0 hinausschiesst — Scale darf das, Opacity nicht.
              Center(
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: const Duration(milliseconds: 800),
                  curve: Curves.elasticOut,
                  builder: (context, t, child) => Transform.scale(
                    scale: 0.4 + 0.6 * t,
                    child: Opacity(opacity: t.clamp(0.0, 1.0), child: child),
                  ),
                  // Glow-Ring: aeusserer Kreis in zartem Primary + Schatten
                  // hinter dem eigentlichen Gradient-Badge.
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.primary.withValues(alpha: 0.06),
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.15),
                        width: 2,
                      ),
                    ),
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
                            color: AppColors.primary.withValues(alpha: 0.45),
                            blurRadius: 36,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.bolt_rounded,
                        color: Colors.white,
                        size: 48,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // Count-up: der IntTween zaehlt von 0 bis total hoch, easeOut
              // laesst ihn am Ende "ausrollen" wie ein Spielautomat.
              TweenAnimationBuilder<int>(
                tween: IntTween(begin: 0, end: total),
                duration: const Duration(milliseconds: 900),
                curve: Curves.easeOutCubic,
                builder: (context, value, _) => Text(
                  '+$value',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 64,
                    fontWeight: FontWeight.w900,
                    fontStyle: FontStyle.italic,
                    color: AppColors.primary,
                    height: 1.0,
                  ),
                ),
              ),
              PopIn(
                delayMs: 250,
                child: Text(
                  'PUNKTE VERGEBEN',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.5,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ),
              if (message.isNotEmpty) ...[
                const SizedBox(height: 12),
                PopIn(
                  delayMs: 350,
                  child: Text(
                    message,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
              // Deine Belohnung als Bewerter: XP + Streak aus der Response.
              if (xpGained > 0 || streak > 0) ...[
                const SizedBox(height: 24),
                PopIn(
                  delayMs: 550,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (xpGained > 0)
                        _RewardChip(
                          icon: Icons.auto_awesome_rounded,
                          label: '+$xpGained XP',
                          bg: AppColors.tertiaryContainer,
                          fg: AppColors.tertiary,
                        ),
                      if (xpGained > 0 && streak > 0)
                        const SizedBox(width: 12),
                      if (streak > 0)
                        _RewardChip(
                          icon: Icons.local_fire_department_rounded,
                          label: streak == 1 ? '1 TAG' : '$streak TAGE',
                          bg: AppColors.primaryContainer,
                          fg: AppColors.primary,
                        ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 32),
              // Zeile fuer Zeile einsliden: jede startet 130ms nach der vorigen.
              ...List.generate(breakdownRows.length, (i) {
                final e = breakdownRows[i];
                return PopIn(
                  delayMs: 700 + i * 130,
                  child: Padding(
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
                );
              }),
              const Spacer(),
              PopIn(
                delayMs: 900,
                dy: 0,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 40),
                  child: GradientButton(
                    label: 'FERTIG',
                    isLoading: false,
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Reward Chip (XP / Streak auf dem Result-Screen) ──────────────────────────
class _RewardChip extends StatelessWidget {
  const _RewardChip({
    required this.icon,
    required this.label,
    required this.bg,
    required this.fg,
  });

  final IconData icon;
  final String label;
  final Color bg;
  final Color fg;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(50),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: fg),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.w900,
              color: fg,
            ),
          ),
        ],
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
                child: GradientButton(
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


import 'package:flutter/material.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import 'package:ranked/streak.dart';
import '../app_colors.dart';
import 'ranking_api_service.dart';
import 'ranking_provider.dart';
import 'ranking_widgets.dart';

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


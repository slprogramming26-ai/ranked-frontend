import 'package:flutter/material.dart';
import '../../app_colors.dart';

/// Wiederverwendbare Puls-Huelle fuer Skeletons: laesst alles darunter weich
/// zwischen 45% und 100% Deckkraft atmen (gleiche Technik wie das
/// LeaderboardSkeleton im Ranking). Ein Controller pro Huelle — deshalb am
/// besten EINE Huelle um eine ganze Skeleton-Gruppe legen statt eine pro Box.
class SkeletonPulse extends StatefulWidget {
  final Widget child;

  const SkeletonPulse({super.key, required this.child});

  @override
  State<SkeletonPulse> createState() => _SkeletonPulseState();
}

class _SkeletonPulseState extends State<SkeletonPulse>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween(begin: 0.45, end: 1.0).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
      ),
      child: widget.child,
    );
  }
}

/// Platzhalter fuer den Feed waehrend des ersten Ladens: drei Post-foermige
/// Skeletons (Header, Titel, Bildflaeche, Footer) unter EINER Puls-Huelle,
/// damit alles synchron atmet.
class FeedSkeleton extends StatelessWidget {
  const FeedSkeleton({super.key});

  Widget _box({double? w, double? h, BorderRadius? radius, BoxShape shape = BoxShape.rectangle}) {
    return Container(
      width: w,
      height: h,
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerHigh,
        shape: shape,
        borderRadius: shape == BoxShape.rectangle
            ? (radius ?? BorderRadius.circular(8))
            : null,
      ),
    );
  }

  // Ein Post-Skelett: spiegelt das Layout von TextPost (ListTile-Header,
  // Titelzeile, Bild mit 24er-Radius, Footer-Zeile).
  Widget _postSkeleton() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Row(
            children: [
              _box(w: 44, h: 44, shape: BoxShape.circle),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _box(w: 120, h: 12),
                  const SizedBox(height: 6),
                  _box(w: 72, h: 10),
                ],
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: _box(w: 200, h: 16),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: AspectRatio(
            aspectRatio: 16 / 10,
            child: _box(
              w: double.infinity,
              radius: BorderRadius.circular(24),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(24),
          child: Row(
            children: [
              _box(w: 76, h: 32, radius: BorderRadius.circular(16)),
              const SizedBox(width: 15),
              _box(w: 28, h: 28, shape: BoxShape.circle),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return SkeletonPulse(
      child: Column(
        children: [
          _postSkeleton(),
          _postSkeleton(),
          _postSkeleton(),
        ],
      ),
    );
  }
}
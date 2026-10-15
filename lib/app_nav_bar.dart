import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'post/create_post.dart';
import 'app_colors.dart';
import 'profile.dart';
import 'ranking/ranking_provider.dart';

/// Flache Bar unten ueber die volle Breite: neutraler Hintergrund, duenne
/// Linie oben, kein Blur/Schatten (der Blur ueber scrollendem Inhalt war
/// teuer). Aktiver Tab = gefuelltes Icon in Rot, inaktiv = Outline in Grau.
/// In der Mitte der Erstellen-Button als abgerundetes Quadrat — gleiche Form
/// wie die Story-Ringe.
class AppNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTabSelected;

  const AppNavBar({
    super.key,
    required this.currentIndex,
    required this.onTabSelected,
  });

  @override
  Widget build(BuildContext context) {
    // Flamme am Ranking-Tab: nur wenn Ranking aktiviert UND heute noch nicht
    // gerankt. select -> die Bar baut nur neu, wenn sich genau dieser Wert
    // aendert, nicht bei jedem anderen notifyListeners der Provider.
    final rankingEnabled = context.select<ProfileProvider, bool>(
      (p) => p.userdata['ranking_enabled'] == true,
    );
    final rankedToday = context.select<RankingProvider, bool>(
      (p) => p.rankedToday,
    );
    final showFlame = rankingEnabled && !rankedToday;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.outlineVariant)),
      ),
      // Bar selbst 64 hoch, SafeArea legt den Abstand zur Gestenleiste drauf.
      // minimum: auch ohne System-Inset (z.B. 3-Button-Navigation) bleiben
      // 8px Luft, damit die Icons nicht an der Unterkante kleben.
      child: SafeArea(
        top: false,
        minimum: const EdgeInsets.only(bottom: 8),
        child: SizedBox(
          height: 64,
          child: Row(
            children: [
              _buildNavTab(Icons.home_outlined, Icons.home_rounded, 0),
              _buildNavTab(
                Icons.leaderboard_outlined,
                Icons.leaderboard_rounded,
                1,
                showFlame: showFlame,
              ),
              Expanded(child: Center(child: _buildCreateButton(context))),
              _buildNavTab(
                Icons.chat_bubble_outline_rounded,
                Icons.chat_bubble_rounded,
                2,
              ),
              _buildNavTab(
                Icons.person_outline_rounded,
                Icons.person_rounded,
                3,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCreateButton(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const CreatePost()),
      ),
      child: Container(
        width: 50,
        height: 38,
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
      ),
    );
  }

  Widget _buildNavTab(
    IconData icon,
    IconData activeIcon,
    int index, {
    bool showFlame = false,
  }) {
    final bool isSelected = currentIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => onTabSelected(index),
        // Ganze Spalte tippbar, nicht nur das Icon.
        behavior: HitTestBehavior.opaque,
        child: Center(
          child: Stack(
            clipBehavior: Clip.none, // Flamme ragt ueber die Icon-Ecke
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                transitionBuilder: (child, animation) => ScaleTransition(
                  scale: animation,
                  child: FadeTransition(opacity: animation, child: child),
                ),
                child: Icon(
                  isSelected ? activeIcon : icon,
                  key: ValueKey(isSelected),
                  color: isSelected
                      ? AppColors.primary
                      : AppColors.onSurfaceVariant,
                  size: 28,
                ),
              ),
              Positioned(
                top: -6,
                right: -8,
                // Ein- und Ausblenden per Scale, statt hart aufzupoppen.
                child: AnimatedScale(
                  scale: showFlame ? 1 : 0,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOutBack,
                  child: const _StreakFlame(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Kleine Flamme oben rechts am Ranking-Tab: "Heute noch nicht gerankt —
// Streak in Gefahr". Heller Kreis drumherum trennt sie vom Icon darunter.
class _StreakFlame extends StatelessWidget {
  const _StreakFlame();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(1.5),
      decoration: BoxDecoration(
        color: AppColors.surface,
        shape: BoxShape.circle,
      ),
      child: Icon(
        Icons.local_fire_department_rounded,
        color: AppColors.primary,
        size: 16,
      ),
    );
  }
}

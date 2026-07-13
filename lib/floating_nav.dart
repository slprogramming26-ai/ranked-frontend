import 'dart:ui';
import 'package:flutter/material.dart';
import 'post/create_post.dart';
import 'app_colors.dart';

class FloatingNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTabSelected;

  const FloatingNavBar({
    super.key,
    required this.currentIndex,
    required this.onTabSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: SizedBox(
        height: 76,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Glass bar
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.navGlass.withValues(alpha: 0.88),
                  borderRadius: BorderRadius.circular(40),
                  border: Border.all(
                    color: AppColors.navBorder.withValues(alpha: 0.6),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      blurRadius: 40,
                      offset: const Offset(0, 10),
                    ),
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(40),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                    child: Row(
                      children: [
                        _buildNavTab(
                          Icons.home_outlined,
                          Icons.home_rounded,
                          0,
                        ),
                        _buildNavTab(
                          Icons.leaderboard_outlined,
                          Icons.leaderboard_rounded,
                          1,
                        ),
                        const SizedBox(width: 72),
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
              ),
            ),

            // Center Create button (elevated above bar)
            GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CreatePost()),
              ),
              child: Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.primary, AppColors.primaryContainer],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.45),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.2),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.add_rounded,
                  color: Colors.white,
                  size: 32,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavTab(IconData icon, IconData activeIcon, int index) {
    final bool isSelected = currentIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => onTabSelected(index),
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
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
                    : AppColors.onSurfaceVariant.withValues(alpha: 0.45),
                size: 24,
              ),
            ),
            const SizedBox(height: 5),
            AnimatedContainer(
              duration: const Duration(milliseconds: 350),
              curve: Curves.easeOutBack,
              width: isSelected ? 20 : 4,
              height: 3,
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : Colors.transparent,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
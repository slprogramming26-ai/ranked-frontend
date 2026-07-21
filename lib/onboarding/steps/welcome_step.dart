import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../app_colors.dart';

class WelcomeStep extends StatelessWidget {
  const WelcomeStep({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            "Welcome to\nthe Pulse",
            style: GoogleFonts.plusJakartaSans(
              fontSize: 48,
              fontWeight: FontWeight.w900,
              height: 1,
              color: AppColors.onSurface,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            "The world’s first editorial social feed where your energy matters.",
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 40),
          _bentoItem(
            Icons.analytics,
            "Post your life",
            "Share your daily Pulse. Authentic and raw.",
            AppColors.primary,
            true,
          ),
          _bentoItem(
            Icons.military_tech,
            "Get Ranked",
            "The community evaluates your creativity.",
            AppColors.tertiaryContainer,
            false,
          ),
          _bentoItem(
            Icons.insert_emoticon_rounded,
            'Earn and customize',
            'Rank others to earn coins. Unlock exclusive avatar items and "Freundebuch" skins',
            Colors.lightGreen,
            true,
          ),
        ],
      ),
    );
  }

  Widget _bentoItem(
    IconData icon,
    String title,
    String sub,
    Color color,
    bool rotateLeft,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        children: [
          Transform.rotate(
            angle: rotateLeft ? -0.1 : 0.1,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Icon(icon, color: Colors.white, size: 30),
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                Text(
                  sub,
                  style: const TextStyle(color: Colors.grey, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

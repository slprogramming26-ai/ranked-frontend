import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../app_colors.dart';

// Zustandslos: Auswahl-Map und Toggle-Callback kommen vom OnboardingFlow,
// damit die gewaehlten Vibes dort fuer addUserDetails verfuegbar bleiben.
class VibeStep extends StatelessWidget {
  final Map<String, bool> selections;
  final void Function(String name) onToggle;

  const VibeStep({
    super.key,
    required this.selections,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          Text(
            "What's Your Vibe?",
            style: GoogleFonts.plusJakartaSans(
              fontSize: 32,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            "Pick up to 2 Pulse Factors that define your daily rhythm — "
            "or none at all. Share only what you want to share.",
          ),
          const SizedBox(height: 30),
          Expanded(
            child: GridView.count(
              crossAxisCount: 2,
              mainAxisSpacing: 15,
              crossAxisSpacing: 15,
              childAspectRatio: 1.2,
              children: [
                _vibeCard(Icons.bolt, "Productivity"),
                _vibeCard(Icons.palette, "Creativity"),
                _vibeCard(Icons.fitness_center, "Fitness"),
                _vibeCard(Icons.sports_esports, "Gaming"),
                _vibeCard(Icons.computer, 'Coding'),
                _vibeCard(Icons.music_note, 'Music'),
                _vibeCard(Icons.book, 'Reading'),
                _vibeCard(Icons.sports_soccer, 'Sports'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _vibeCard(IconData icon, String label) {
    final bool isActive = selections[label] ?? false;

    return InkWell(
      onTap: () => onToggle(label),
      borderRadius: BorderRadius.circular(30),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: isActive
              ? LinearGradient(
                  colors: [AppColors.primary, AppColors.primaryContainer],
                )
              : null,
          color: isActive ? null : AppColors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isActive ? Colors.white : AppColors.primary,
              size: 32,
            ),
            const SizedBox(height: 10),
            Text(
              label,
              style: TextStyle(
                color: isActive ? Colors.white : Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../ui/app_colors.dart';

/// Die eine Liste aller Vibes (Name -> Icon). Vorher 3x kopiert (Onboarding-
/// Flow, VibeStep, Profil) — ein neuer Vibe musste an allen Stellen rein.
/// Die Namen sind gleichzeitig die Werte fuer vibe_factor_1/2 im Backend,
/// also NICHT uebersetzen oder umbenennen, sonst passen alte Profile nicht.
const Map<String, IconData> kVibes = {
  'Productivity': Icons.bolt,
  'Creativity': Icons.palette,
  'Fitness': Icons.fitness_center,
  'Gaming': Icons.sports_esports,
  'Coding': Icons.computer,
  'Music': Icons.music_note,
  'Reading': Icons.book,
  'Sports': Icons.sports_soccer,
};

/// Maximal so viele Vibes gleichzeitig (Backend hat genau 2 Felder).
const int kMaxVibes = 2;

/// Schaltet [name] in [selections] um. Gibt false zurueck, wenn nichts
/// passiert ist (schon [kMaxVibes] aktiv und [name] waere ein weiterer).
/// Aendert die Map direkt — der Aufrufer ruft danach setState.
bool toggleVibe(Map<String, bool> selections, String name) {
  final isActive = selections[name] ?? false;
  final activeCount = selections.values.where((v) => v).length;
  if (activeCount >= kMaxVibes && !isActive) return false;
  selections[name] = !isActive;
  return true;
}

/// Grid aus Vibe-Kacheln. Zustandslos: Auswahl + Toggle kommen von aussen.
/// [shrinkWrap] = true, wenn das Grid in einer ScrollView steckt (Edit-Screen);
/// im Onboarding steckt es in einem Expanded und scrollt selbst.
class VibeGrid extends StatelessWidget {
  final Map<String, bool> selections;
  final void Function(String name) onToggle;
  final bool shrinkWrap;

  const VibeGrid({
    super.key,
    required this.selections,
    required this.onToggle,
    this.shrinkWrap = false,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      mainAxisSpacing: 15,
      crossAxisSpacing: 15,
      childAspectRatio: 1.2,
      shrinkWrap: shrinkWrap,
      // In einer aeusseren ScrollView darf das Grid nicht selbst scrollen,
      // sonst kaempfen zwei Scroller um dieselbe Geste.
      physics: shrinkWrap ? const NeverScrollableScrollPhysics() : null,
      children: [
        for (final e in kVibes.entries) _vibeCard(e.value, e.key),
      ],
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
          color: isActive ? AppColors.primary : AppColors.surfaceContainerLow,
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
                color: isActive ? Colors.white : AppColors.onSurface,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

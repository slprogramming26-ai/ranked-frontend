import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ranked/l10n/l10n.dart';
import '../../profile/vibes.dart';

// Zustandslos: Auswahl-Map und Toggle-Callback kommen vom OnboardingFlow,
// damit die gewaehlten Vibes dort fuer addUserDetails verfuegbar bleiben.
// Das Grid selbst liegt in profile/vibes.dart (teilt sich der Edit-Screen).
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
            context.l10n.onboardingVibeTitle,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 32,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            context.l10n.onboardingVibeSubtitle,
          ),
          const SizedBox(height: 30),
          Expanded(
            child: VibeGrid(selections: selections, onToggle: onToggle),
          ),
        ],
      ),
    );
  }
}

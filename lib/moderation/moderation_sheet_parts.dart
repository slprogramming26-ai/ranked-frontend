import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../app_colors.dart';

// Gemeinsame Bausteine fuer Entfernen- und Ban-Sheet, damit beide gleich
// aussehen und nichts doppelt gepflegt wird.

class ModerationSheetHandle extends StatelessWidget {
  const ModerationSheetHandle({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
    );
  }
}

class ModerationSectionLabel extends StatelessWidget {
  const ModerationSectionLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.8,
        color: AppColors.onSurfaceVariant,
      ),
    );
  }
}

// Eigener Chip statt ChoiceChip: gleicher Pill-Look wie die Filter-Chips der
// Queue, ohne Material-Haken und Theme-Abhaengigkeiten.
class ModerationChip extends StatelessWidget {
  const ModerationChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary
              : AppColors.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: selected ? Colors.white : AppColors.onSurface,
          ),
        ),
      ),
    );
  }
}

/// Grauer Hinweis mit Info-Icon direkt ueber dem Bestaetigen-Button.
class ModerationInfoRow extends StatelessWidget {
  const ModerationInfoRow(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(Icons.info_outline_rounded,
            size: 16, color: AppColors.onSurfaceVariant),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: TextStyle(fontSize: 13, color: AppColors.onSurfaceVariant),
          ),
        ),
      ],
    );
  }
}

/// Roter Bestaetigen-Button. onPressed == null -> gedimmt + gesperrt.
class ModerationDangerButton extends StatelessWidget {
  const ModerationDangerButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final danger = Colors.red.shade700;
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: FilledButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 20),
        label: Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
        style: FilledButton.styleFrom(
          backgroundColor: danger,
          foregroundColor: Colors.white,
          disabledBackgroundColor: danger.withValues(alpha: 0.35),
          disabledForegroundColor: Colors.white.withValues(alpha: 0.8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }
}

/// Look der Textfelder in den Moderations-Sheets.
InputDecoration moderationFieldDecoration(String hint) => InputDecoration(
  hintText: hint,
  hintStyle: TextStyle(color: AppColors.onSurfaceVariant),
  filled: true,
  fillColor: AppColors.surfaceContainerHighest,
  counterStyle: TextStyle(color: AppColors.onSurfaceVariant),
  border: OutlineInputBorder(
    borderRadius: BorderRadius.circular(16),
    borderSide: BorderSide.none,
  ),
);

/// Gemeinsamer Rahmen: rundes Sheet, schiebt sich ueber die Tastatur,
/// Griff + zentrierter Titel, darunter [children].
class ModerationSheetFrame extends StatelessWidget {
  const ModerationSheetFrame({
    super.key,
    required this.title,
    required this.children,
  });

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Center(child: ModerationSheetHandle()),
                const SizedBox(height: 20),
                Center(
                  child: Text(
                    title,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.onSurface,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                ...children,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

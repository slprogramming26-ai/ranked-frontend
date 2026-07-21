import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../app_colors.dart';

class AgeStep extends StatefulWidget {
  // DSGVO-Check: Das Alter wird nur einmal ans Backend geschickt (createUser)
  // und dort NICHT gespeichert.
  final int age;
  final ValueChanged<int> onChanged;

  const AgeStep({
    super.key,
    required this.age,
    required this.onChanged,
  });

  @override
  State<AgeStep> createState() => _AgeStepState();
}

class _AgeStepState extends State<AgeStep> {
  static const int _minAge = 13;
  static const int _maxAge = 99;

  late final FixedExtentScrollController _wheelController;

  @override
  void initState() {
    super.initState();
    // Controller lebt im State (nicht im build), damit die Wheel-Position
    // die setState-Rebuilds des Flows ueberlebt.
    _wheelController =
        FixedExtentScrollController(initialItem: widget.age - _minAge);
  }

  @override
  void dispose() {
    _wheelController.dispose();
    super.dispose();
  }

  bool get _isUnderage => widget.age < 16;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          const SizedBox(height: 20),

          // --- Icon Badge ---
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  AppColors.primary,
                  AppColors.primaryContainer,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.3),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Icon(
              Icons.cake_outlined,
              color: Colors.white,
              size: 32,
            ),
          ),

          const SizedBox(height: 20),

          // --- Hero Text ---
          Text(
            "One Last Check",
            style: GoogleFonts.plusJakartaSans(
              fontSize: 26,
              fontWeight: FontWeight.w900,
              color: AppColors.onSurface,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            "How old are you? We only check this once — your age is never stored.",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: AppColors.onSurfaceVariant,
              height: 1.5,
            ),
          ),

          const SizedBox(height: 24),

          // --- Age Wheel ---
          SizedBox(
            height: 220,
            child: CupertinoPicker(
              scrollController: _wheelController,
              itemExtent: 52,
              diameterRatio: 1.2,
              selectionOverlay: Container(
                margin: const EdgeInsets.symmetric(horizontal: 70),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainer.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onSelectedItemChanged: (index) =>
                  widget.onChanged(_minAge + index),
              children: [
                for (int a = _minAge; a <= _maxAge; a++)
                  Center(
                    child: Text(
                      '$a',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: a == widget.age
                            ? AppColors.primary
                            : AppColors.onSurfaceVariant,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // --- Under-16 Hint ---
          AnimatedOpacity(
            opacity: _isUnderage ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 200),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFA26769).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.lock_clock_outlined,
                    color: Color(0xFFA26769),
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      "Ranked is 16+. We'd love to see you again in a few years!",
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFFA26769),
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }
}
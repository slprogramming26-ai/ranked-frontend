import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ranked/l10n/l10n.dart';
import '../../ui/app_colors.dart';
import '../../ui/avatar_picker.dart';
import '../onboarding_text_field.dart';

class AboutMeStep extends StatefulWidget {
  // Collect-first: Das Bild wird hier nur lokal gemerkt — der Upload braucht
  // einen Token und passiert erst ganz am Ende (nach createUser + login).
  final Function(File image) onImagePicked;
  final Function(String bio) onAboutMeFinished;

  const AboutMeStep({
    super.key,
    required this.onImagePicked,
    required this.onAboutMeFinished,
  });

  @override
  State<AboutMeStep> createState() => _AboutMeStepState();
}

class _AboutMeStepState extends State<AboutMeStep> {
  File? _image;
  late TextEditingController _bioController;

  @override
  void initState() {
    super.initState();
    _bioController = TextEditingController();
    _bioController.addListener(() {
      widget.onAboutMeFinished(_bioController.text);
    });
  }

  @override
  void dispose() {
    _bioController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          const SizedBox(height: 20),

          // --- Avatar ---
          AvatarPicker(
            localImage: _image,
            onPicked: (file) {
              setState(() => _image = file);
              widget.onImagePicked(file);
            },
          ),

          const SizedBox(height: 20),

          // --- Hero Text ---
          Text(
            context.l10n.onboardingAboutMeTitle,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 26,
              fontWeight: FontWeight.w900,
              color: AppColors.onSurface,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            context.l10n.onboardingAboutMeSubtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: AppColors.onSurfaceVariant,
              height: 1.5,
            ),
          ),

          const SizedBox(height: 28),

          // --- Story Label ---
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              context.l10n.onboardingAboutMeStoryLabel,
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: AppColors.onSurfaceVariant,
                letterSpacing: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 8),

          OnboardingTextField(
            controller: _bioController,
            hint: context.l10n.onboardingAboutMeBioHint,
            maxLines: 6,
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

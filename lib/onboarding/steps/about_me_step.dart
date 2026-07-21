import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../../app_colors.dart';

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
  final _picker = ImagePicker();
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

  Future<void> _pickImage() async {
    // Picker skaliert nativ runter: Das Backend lehnt Bilder >20 Mio. Pixel
    // mit 400 ab (Decompression-Bomb-Schutz) — moderne 48/50-MP-Kameras
    // liegen darueber. 1024px passt zum Backend-Thumbnail, Avatar ist eh klein.
    final pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );
    if (pickedFile == null) return;

    setState(() => _image = File(pickedFile.path));
    widget.onImagePicked(_image!);
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          const SizedBox(height: 20),

          // --- Avatar ---
          GestureDetector(
            onTap: _pickImage,
            child: Stack(
              alignment: Alignment.bottomRight,
              children: [
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        AppColors.primary,
                        AppColors.primaryContainer,
                        AppColors.tertiaryContainer,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.surface,
                        width: 3,
                      ),
                      color: AppColors.surfaceContainerHighest,
                    ),
                    child: ClipOval(
                      child: _image != null
                          ? Image.file(_image!, fit: BoxFit.cover)
                          : Icon(
                              Icons.person,
                              size: 44,
                              color: AppColors.primary,
                            ),
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.35),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.photo_camera,
                    color: Colors.white,
                    size: 14,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // --- Hero Text ---
          Text(
            "The Digital Pulse",
            style: GoogleFonts.plusJakartaSans(
              fontSize: 26,
              fontWeight: FontWeight.w900,
              color: AppColors.onSurface,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            "Let others feel your energy. This is your curated scrapbook entry.",
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
              "YOUR STORY",
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: const Color(0xFFA26769),
                letterSpacing: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 8),

          // --- Textarea with shadow effect ---
          Stack(
            children: [
              // Offset shadow layer
              Positioned(
                top: 4,
                left: 4,
                right: -4,
                bottom: -4,
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
              // Actual TextField
              TextField(
                controller: _bioController,
                maxLines: 6,
                decoration: InputDecoration(
                  hintText:
                      "Share your story, your goals, or what makes you unique...",
                  hintStyle: TextStyle(
                    color: AppColors.outlineVariant,
                    fontSize: 13,
                    height: 1.6,
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.all(16),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: AppColors.surfaceContainerHighest,
                      width: 1.5,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: AppColors.surfaceContainerHighest,
                      width: 1.5,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: AppColors.primary,
                      width: 1.5,
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

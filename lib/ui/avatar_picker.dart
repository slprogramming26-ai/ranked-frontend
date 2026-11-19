import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'app_colors.dart';
import 'net_image.dart';

/// Runder Avatar mit Gradient-Ring + Kamera-Badge; Tippen oeffnet die Galerie.
/// Genutzt im Onboarding (AboutMeStep) und im Profil-bearbeiten-Screen.
///
/// Zustandslos: Die gewaehlte Datei merkt sich der Aufrufer und gibt sie als
/// [localImage] zurueck rein — so gibt es nur EINE Wahrheit (der Aufrufer
/// braucht die Datei eh fuer den Upload).
/// Anzeige-Reihenfolge: frisch gewaehlte Datei > aktuelles Netzbild > Icon.
class AvatarPicker extends StatelessWidget {
  final File? localImage;
  final String? networkUrl;
  final void Function(File image) onPicked;

  const AvatarPicker({
    super.key,
    this.localImage,
    this.networkUrl,
    required this.onPicked,
  });

  static const double _size = 100;

  Future<void> _pickImage() async {
    // Picker skaliert nativ runter: Das Backend lehnt Bilder >20 Mio. Pixel
    // mit 400 ab (Decompression-Bomb-Schutz) — moderne 48/50-MP-Kameras
    // liegen darueber. 1024px passt zum Backend-Thumbnail, Avatar ist eh klein.
    final pickedFile = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );
    if (pickedFile == null) return;
    onPicked(File(pickedFile.path));
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
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
              width: _size,
              height: _size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.surface, width: 3),
                color: AppColors.surfaceContainerHighest,
              ),
              child: ClipOval(child: _image(context)),
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
            child: const Icon(Icons.photo_camera, color: Colors.white, size: 14),
          ),
        ],
      ),
    );
  }

  Widget _image(BuildContext context) {
    if (localImage != null) {
      return Image.file(localImage!, fit: BoxFit.cover);
    }
    // Leerer String = "kein Bild": das Onboarding speichert "" statt null,
    // wenn kein Bild gewaehlt wurde.
    final url = networkUrl;
    if (url != null && url.isNotEmpty) {
      return Image(
        image: netImage(context, url, logicalWidth: _size),
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => _placeholder(),
      );
    }
    return _placeholder();
  }

  Widget _placeholder() =>
      Icon(Icons.person, size: 44, color: AppColors.primary);
}

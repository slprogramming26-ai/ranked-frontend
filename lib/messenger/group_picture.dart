// =============================================================================
//  Gruppenbild auswählen + säubern
// =============================================================================
//  Geteilt von Info-Sheet (Bild ändern) und Erstellen-Sheet (Bild von Anfang
//  an). Bewusst ZWEI Funktionen statt einer: so kann der Aufrufer
//  "abgebrochen" (pick -> null) von "Bild kaputt" (sanitize -> null)
//  unterscheiden und dazwischen einen Spinner zeigen.
// =============================================================================

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

import '../core/image_sanitizer.dart';

const _maxSize = 1024;
const _quality = 85;

/// Öffnet die Galerie. null = abgebrochen.
/// Der Picker skaliert nativ runter (Backend lehnt >20 MP ab, siehe
/// about_me_step.dart), den Rest macht [sanitizeGroupPicture].
Future<XFile?> pickGroupPicture() {
  return ImagePicker().pickImage(
    source: ImageSource.gallery,
    maxWidth: _maxSize.toDouble(),
    maxHeight: _maxSize.toDouble(),
    imageQuality: _quality,
  );
}

/// EXIF/GPS raus im Hintergrund-Isolate. null = Bild nicht lesbar.
/// Kein Fallback aufs Original — sonst gingen die Metadaten doch hoch.
Future<File?> sanitizeGroupPicture(XFile picked) async {
  final cleanPath = await compute(sanitizeImageFile, (
    path: picked.path,
    maxSize: _maxSize,
    quality: _quality,
  ));
  return cleanPath == null ? null : File(cleanPath);
}

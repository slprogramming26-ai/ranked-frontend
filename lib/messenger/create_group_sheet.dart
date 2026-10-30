// =============================================================================
//  Erstellen-Sheet für neue Gruppen
// =============================================================================
//  Sammelt nur die Eingaben (Name + Bild, beides optional) und gibt sie per
//  pop zurück. Erstellen/Hochladen macht der Aufrufer (messenger.dart) —
//  das Bild braucht nämlich die Gruppen-ID, die es erst NACH createGroup gibt.
// =============================================================================

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ranked/l10n/l10n.dart';

import '../ui/app_colors.dart';
import 'group_picture.dart';
import 'messenger_api_service.dart';

/// Ergebnis des Sheets. picture ist schon gesäubert (EXIF raus).
typedef NewGroupInput = ({String name, File? picture});

/// null = Sheet ohne "Erstellen" geschlossen.
Future<NewGroupInput?> showCreateGroupSheet(BuildContext context) {
  return showModalBottomSheet<NewGroupInput>(
    context: context,
    backgroundColor: AppColors.surface,
    isScrollControlled: true, // sonst schiebt die Tastatur das Sheet nicht hoch
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (_) => const _CreateGroupSheet(),
  );
}

class _CreateGroupSheet extends StatefulWidget {
  const _CreateGroupSheet();

  @override
  State<_CreateGroupSheet> createState() => _CreateGroupSheetState();
}

class _CreateGroupSheetState extends State<_CreateGroupSheet> {
  final _nameController = TextEditingController();
  File? _picture;
  bool _processing = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  // Säubern schon hier statt erst beim Erstellen: ein kaputtes Bild merkt
  // man so sofort, solange das Sheet noch offen ist.
  Future<void> _pickPicture() async {
    if (_processing) return;
    final messenger = ScaffoldMessenger.of(context);
    final l10n = context.l10n;

    final picked = await pickGroupPicture();
    if (picked == null || !mounted) return;

    setState(() => _processing = true);
    final clean = await sanitizeGroupPicture(picked);
    if (!mounted) return;
    setState(() {
      _processing = false;
      if (clean != null) _picture = clean;
    });
    if (clean == null) {
      messenger.showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.primary,
          content: Text(
            l10n.chatInfoPictureProcessFailed,
            style: GoogleFonts.inter(
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),
      );
    }
  }

  void _submit() {
    if (_processing) return;
    Navigator.pop<NewGroupInput>(context, (
      name: _nameController.text.trim(),
      picture: _picture,
    ));
  }

  @override
  Widget build(BuildContext context) {
    // Tastatur-Höhe als Abstand unten, damit Feld + Button sichtbar bleiben.
    final keyboard = MediaQuery.of(context).viewInsets.bottom;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(20, 10, 20, 18 + keyboard),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 42,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.onSurfaceVariant.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              context.l10n.createGroupTitle,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.onSurface,
              ),
            ),
            const SizedBox(height: 20),
            _PicturePicker(
              picture: _picture,
              processing: _processing,
              onTap: _pickPicture,
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _nameController,
              maxLength: MessengerApiService.groupNameMaxLength,
              textCapitalization: TextCapitalization.sentences,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _submit(),
              style: GoogleFonts.inter(color: AppColors.onSurface),
              decoration: InputDecoration(
                hintText: context.l10n.createGroupNameHint,
                hintStyle: GoogleFonts.inter(
                  color: AppColors.onSurfaceVariant,
                ),
                counterText: '', // Limit greift trotzdem, nur ohne Zähler
                filled: true,
                fillColor: AppColors.surfaceContainerHigh,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: FilledButton(
                onPressed: _processing ? null : _submit,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(
                  context.l10n.createGroupSubmit,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Runder Bild-Platzhalter mit Kamera-Badge — gleiche Optik wie im Info-Sheet.
class _PicturePicker extends StatelessWidget {
  final File? picture;
  final bool processing;
  final VoidCallback onTap;

  const _PicturePicker({
    required this.picture,
    required this.processing,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const size = 84.0;
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: size,
            height: size,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.surfaceContainerHigh,
            ),
            child: picture != null
                ? Image.file(picture!, fit: BoxFit.cover)
                : Icon(
                    Icons.groups_rounded,
                    size: 38,
                    color: AppColors.onSurfaceVariant,
                  ),
          ),
          if (processing)
            Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.black.withValues(alpha: 0.35),
              ),
              child: const Padding(
                padding: EdgeInsets.all(28),
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Colors.white,
                ),
              ),
            ),
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary,
                border: Border.all(color: AppColors.surface, width: 2),
              ),
              child: const Icon(
                Icons.camera_alt_rounded,
                size: 14,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

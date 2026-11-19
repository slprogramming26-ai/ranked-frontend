import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../core/image_sanitizer.dart';
import '../core/user_api_service.dart';
import '../l10n/app_localizations.dart';
import '../l10n/l10n.dart';
import '../onboarding/onboarding_text_field.dart';
import '../ui/app_colors.dart';
import '../ui/avatar_picker.dart';
import '../ui/confirm_dialog.dart';
import 'profile.dart';
import 'vibes.dart';

/// Profilbild, Bio und Vibes nachtraeglich aendern (vorher nur im Onboarding).
/// Schickt beim Speichern NUR die geaenderten Felder (siehe updateProfile).
class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  // Startwerte — gegen die vergleicht der Dirty-Check.
  late final String? _initialImageUrl;
  late final String _initialBio;
  late final Set<String> _initialVibes;

  // Aktueller Stand im Formular.
  File? _newImage; // null = altes Bild bleibt
  late final TextEditingController _bio;
  late final Map<String, bool> _vibes;

  bool _saving = false;

  @override
  void initState() {
    super.initState();
    // listen: false — wir lesen nur einmal den Startwert; spaetere Provider-
    // Updates sollen das Formular nicht mitten im Tippen ueberschreiben.
    final data = context.read<ProfileProvider>().userdata;
    _initialImageUrl = data['profile_picture_url'] as String?;
    _initialBio = (data['biography'] as String?) ?? '';
    _initialVibes = {
      ?data['vibe_factor_1'] as String?,
      ?data['vibe_factor_2'] as String?,
    };

    _bio = TextEditingController(text: _initialBio)
      ..addListener(() => setState(() {})); // Dirty-Check fuer den Button
    // Reihenfolge vibe1, vibe2 bleibt erhalten (Map merkt sich Einfuege-
    // Reihenfolge, Umschalten eines bestehenden Keys verschiebt ihn nicht).
    _vibes = {for (final v in _initialVibes) v: true};
  }

  @override
  void dispose() {
    _bio.dispose();
    super.dispose();
  }

  List<String> get _selectedVibes =>
      [for (final e in _vibes.entries) if (e.value) e.key];

  bool get _bioChanged => _bio.text.trim() != _initialBio;

  // Als Set vergleichen: nur WELCHE Vibes zaehlt, nicht die Reihenfolge.
  bool get _vibesChanged =>
      !setEquals(_selectedVibes.toSet(), _initialVibes);

  bool get _isDirty => _newImage != null || _bioChanged || _vibesChanged;

  void _toggleVibe(String name) {
    if (toggleVibe(_vibes, name)) setState(() {});
  }

  Future<void> _save() async {
    if (_saving || !_isDirty) return;
    setState(() => _saving = true);

    final ok = await _saveToServer();

    if (!mounted) return;
    setState(() => _saving = false);
    if (ok) Navigator.pop(context);
  }

  /// Bild (falls neu) hochladen, dann PUT. true = alles gespeichert.
  /// Fehler zeigt sie selbst als Snackbar an.
  Future<bool> _saveToServer() async {
    // VOR dem ersten await holen: Der Provider lebt app-weit, der Screen
    // nicht. Ist der Screen nach dem PUT schon weg, muss das Profil die
    // neuen Werte trotzdem bekommen (Server hat sie ja schon).
    final profile = context.read<ProfileProvider>();
    String? imageUrl;
    if (_newImage != null) {
      // Kein Fallback auf die Originaldatei — die traegt noch GPS/Kameradaten.
      final cleanPath = await compute(sanitizeImageFile, (
        path: _newImage!.path,
        maxSize: 1024,
        quality: 85,
      ));
      if (cleanPath == null) {
        _snack((l) => l.editProfileImageProcessFailed);
        return false;
      }
      imageUrl = await UserApiService.uploadUserImage(File(cleanPath));
      if (imageUrl == null) {
        _snack((l) => l.editProfileImageUploadFailed);
        return false;
      }
    }

    final bio = _bio.text.trim();
    final vibes = _selectedVibes;
    final updated = await UserApiService.updateProfile(
      bio: _bioChanged ? bio : null,
      imageUrl: imageUrl,
      vibes: _vibesChanged
          ? (vibes.elementAtOrNull(0), vibes.elementAtOrNull(1))
          : null,
    );
    if (updated == null) {
      _snack((l) => l.editProfileSaveFailed);
      return false;
    }

    // Server hat's -> lokal nachziehen statt fetchUser(forceRefresh), das
    // auch die Activity neu laden wuerde. Profil zeigt es sofort an.
    if (imageUrl != null) profile.setUserField('profile_picture_url', imageUrl);
    if (_bioChanged) profile.setUserField('biography', bio);
    if (_vibesChanged) {
      profile.setUserField('vibe_factor_1', vibes.elementAtOrNull(0));
      profile.setUserField('vibe_factor_2', vibes.elementAtOrNull(1));
    }
    // Kein Cache-Evict noetig: /users/upload liefert pro Upload eine neue URL
    // (live geprueft 19.11.). Feed-Posts zeigen das alte Bild bis zum
    // naechsten Refresh — bewusst so, der Feed soll seine Position behalten.
    return true;
  }

  void _snack(String Function(AppLocalizations l) text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(text(context.l10n))));
  }

  /// Zurueck (Pfeil ODER System-Geste) mit ungespeicherten Aenderungen.
  Future<void> _confirmDiscard() async {
    if (_saving) return; // waehrend des Speicherns kein Verlassen
    final discard = await showDialog<bool>(
      context: context,
      builder: (_) => ConfirmDialog(
        icon: Icons.edit_off_outlined,
        title: context.l10n.editProfileDiscardTitle,
        message: context.l10n.editProfileDiscardMessage,
        confirmLabel: context.l10n.editProfileDiscardConfirm,
      ),
    );
    if (discard == true && mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      // Sauber -> normal zurueck. Dirty -> Pop wird geblockt und wir fragen.
      // (Navigator.pop nach dem Speichern umgeht PopScope, das ist gewollt.)
      canPop: !_isDirty,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _confirmDiscard();
      },
      child: Scaffold(
        backgroundColor: AppColors.surface,
        body: SafeArea(
          child: Column(
            children: [
              _header(),
              Expanded(
                // Waehrend des Speicherns nichts mehr aenderbar — sonst
                // weicht das Formular von dem ab, was gerade hochgeht.
                child: IgnorePointer(
                  ignoring: _saving,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                    children: [
                      Center(
                        child: AvatarPicker(
                          localImage: _newImage,
                          networkUrl: _initialImageUrl,
                          onPicked: (file) => setState(() => _newImage = file),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        context.l10n.editProfilePhotoHint,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 32),
                      _label(context.l10n.editProfileBioLabel),
                      const SizedBox(height: 8),
                      OnboardingTextField(
                        controller: _bio,
                        hint: context.l10n.onboardingAboutMeBioHint,
                        maxLines: 5,
                      ),
                      const SizedBox(height: 32),
                      _label(
                        context.l10n.editProfileVibesLabel,
                        trailing: context.l10n.editProfileVibesHint(kMaxVibes),
                      ),
                      const SizedBox(height: 12),
                      VibeGrid(
                        selections: _vibes,
                        onToggle: _toggleVibe,
                        shrinkWrap: true,
                      ),
                    ],
                  ),
                ),
              ),
              _saveButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
      child: Row(
        children: [
          GestureDetector(
            // maybePop statt pop: laeuft durch PopScope -> Verwerfen-Dialog.
            onTap: () => Navigator.maybePop(context),
            behavior: HitTestBehavior.opaque,
            child: Icon(Icons.arrow_back, color: AppColors.primary, size: 24),
          ),
          const SizedBox(width: 16),
          Text(
            context.l10n.editProfileTitle,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: AppColors.onSurface,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _label(String text, {String? trailing}) {
    return Row(
      children: [
        Text(
          text,
          style: GoogleFonts.inter(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            color: AppColors.onSurfaceVariant,
            letterSpacing: 1.5,
          ),
        ),
        const Spacer(),
        if (trailing != null)
          Text(
            trailing,
            style: GoogleFonts.inter(
              fontSize: 11,
              color: AppColors.onSurfaceVariant,
            ),
          ),
      ],
    );
  }

  Widget _saveButton() {
    final enabled = _isDirty && !_saving;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
      child: SizedBox(
        width: double.infinity,
        child: FilledButton(
          onPressed: enabled ? _save : null,
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.primary,
            // Beim Speichern rot bleiben (weisser Spinner drauf), sonst grau.
            disabledBackgroundColor: _saving
                ? AppColors.primary
                : AppColors.surfaceContainerHighest,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: _saving
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: Colors.white,
                  ),
                )
              : Text(
                  context.l10n.editProfileSave,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: enabled ? Colors.white : AppColors.onSurfaceVariant,
                  ),
                ),
        ),
      ),
    );
  }
}

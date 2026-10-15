import 'dart:io';
import 'package:flutter/foundation.dart';
import 'post_api_service.dart';
import 'package:flutter/material.dart';
import '../app_colors.dart';
import '../l10n/l10n.dart';
import '../app_loading.dart';
import '../location_picker.dart';
import '../net_image.dart';
import '../profile.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../image_sanitizer.dart';
import 'package:ranked/local_data/database.dart';

class CreatePost extends StatefulWidget {
  const CreatePost({super.key});

  @override
  State<CreatePost> createState() => _CreatePostState();
}

class _CreatePostState extends State<CreatePost> {
  late TextEditingController titleController;
  late TextEditingController contentController;
  // Damit ein Tipp auf die freie Flaeche der Composer-Karte ins Textfeld geht.
  final _contentFocus = FocusNode();
  late final AppDatabase _db;
  File? _image;

  // Heimatort des Users — nur Anzeige ("erbt der Post automatisch").
  String? _defaultLocationName;
  // Explizit gewaehlter Ort fuer DIESEN Post (z.B. Urlaub). null = kein
  // Override, das Backend nimmt dann den Heimatort.
  Map<String, dynamic>? _overrideLocation;

  @override
  void initState() {
    super.initState();
    _db = Provider.of<AppDatabase>(context, listen: false);
    titleController = TextEditingController();
    contentController = TextEditingController();
    fetchPostDraft();
    _loadDefaultLocation();
  }

  Future<void> _loadDefaultLocation() async {
    // fetchUser() ist geguarded (_hasFetched) — meist schon seit dem Login
    // geladen, kein zusaetzlicher Request noetig.
    final provider = context.read<ProfileProvider>();
    await provider.fetchUser();
    if (!mounted) return;
    setState(() {
      _defaultLocationName =
          (provider.userdata['location'] as Map<String, dynamic>?)?['name']
              as String?;
    });
  }

  Future<void> _pickLocation() async {
    final loc = await showLocationPicker(context);
    if (loc == null || !mounted) return;
    setState(() => _overrideLocation = loc);
  }

  @override
  void dispose() {
    titleController.dispose();
    contentController.dispose();
    _contentFocus.dispose();
    _db.deletePostDraft();
    super.dispose();
  }

  Future<void> fetchPostDraft() async {
    final postDraft = await _db.getPostDraft();
    if (postDraft == null || !mounted) return;

    titleController.text = postDraft.title;
    contentController.text = postDraft.content;
    final tag = postDraft.tag;
    if (tag != null && iconActivated.containsKey(tag)) {
      iconActivated[tag] = true;
    }
    // Bild nur wiederherstellen, wenn die Datei noch existiert (Android darf
    // den Cache zwischen zwei Starts aufraeumen).
    final path = postDraft.imagePath;
    if (path != null && File(path).existsSync()) {
      _image = File(path);
    }
    setState(() {});
  }

  final _picker = ImagePicker();

  void pickImageFromGallery() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      // Sofort das Original anzeigen – komprimiert wird erst beim Upload.
      _image = File(pickedFile.path);
      setState(() {});
    }
  }

  void pickImageFromCamera() async {
    final selectedTag = iconActivated.entries
        .where((e) => e.value)
        .map((e) => e.key)
        .firstOrNull;
    final hasAnythingToSave =
        titleController.text.isNotEmpty ||
        contentController.text.isNotEmpty ||
        selectedTag != null ||
        _image != null;
    if (hasAnythingToSave) {
      await _db.savePostDraft(
        title: titleController.text,
        content: contentController.text,
        tag: selectedTag,
        imagePath: _image?.path,
      );
    }
    final pickedFile = await _picker.pickImage(source: ImageSource.camera);

    if (pickedFile != null) {
      _image = File(pickedFile.path);
      setState(() {});
    }
  }

  Map<String, bool> iconActivated = {
    'Productivity': false,
    'Creativity': false,
    'Engagement': false,
  };

  // Radio-Verhalten: hoechstens eine Kategorie. Antippen der aktiven waehlt
  // sie ab, Antippen einer anderen schaltet direkt um.
  void _toggleIcon(String name) {
    final wasActive = iconActivated[name] ?? false;
    setState(() {
      iconActivated.updateAll((_, _) => false);
      iconActivated[name] = !wasActive;
    });
  }

  // Unveraendert aus dem frueheren onPressed des Post-Buttons herausgezogen
  // (nur verschoben, damit die AppBar lesbar bleibt).
  Future<void> _submit() async {
    try {
      String? imageUrl;
      AppLoadingDialog.show(
        context,
        title: context.l10n.createPostSendingTitle,
        messages: [
          context.l10n.createPostSendingUpload,
          context.l10n.createPostSendingCreate,
          context.l10n.createPostSendingAlmost,
        ],
        trailing: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(3, (i) => _Dot(delay: i * 200)),
        ),
      );
      if (_image != null) {
        // Metadaten raus + Komprimierung im Hintergrund-Isolate –
        // UI/Dialog bleibt flüssig. compute() schickt NUR den
        // Record ins Isolate, keine Closure die den Widget-Baum
        // einfängt (sonst „unsendable").
        final cleanPath = await compute(sanitizeImageFile, (
          path: _image!.path,
          maxSize: 1080,
          quality: 85,
        ));

        if (!mounted) return;

        // Kein Fallback auf die Originaldatei: die trägt noch
        // GPS/Kameradaten. Lieber den Post abbrechen als den
        // Standort des Users hochladen.
        if (cleanPath == null) {
          Navigator.pop(context);

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(context.l10n.createPostImageProcessFailed)),
          );

          return;
        }

        imageUrl = await PostApiService.uploadPostImage(File(cleanPath));

        if (!mounted) return;

        if (imageUrl == null) {
          Navigator.pop(context);

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(context.l10n.createPostImageUploadFailed)),
          );

          return;
        }
      }

      final success = await PostApiService.createPost(
        titleController.text,
        contentController.text,
        imageUrl,
        iconActivated.entries
            .where((e) => e.value)
            .map((e) => e.key)
            .firstOrNull
            ?.toLowerCase(),
        locationId: _overrideLocation?['id'] as int?,
      );

      if (!mounted) return;
      Navigator.pop(context);

      if (success) {
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(context.l10n.createPostFailed)));
      }
    } catch (_) {
      // Unerwarteter Fehler: Dialog schließen, damit die UI nicht
      // hängen bleibt, und dem User kurz Bescheid geben.
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.createPostSomethingWrong)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.close, color: AppColors.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          context.l10n.createPostTitle,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 17,
            color: AppColors.onSurface,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: _PostPill(
              label: context.l10n.createPostSubmit,
              onTap: _submit,
            ),
          ),
        ],
      ),
      // SliverFillRemaining(hasScrollBody: false): der Inhalt ist MINDESTENS
      // so hoch wie der sichtbare Bereich (-> Expanded darf den Rest fuellen)
      // und darf laenger werden (-> scrollt dann ganz normal). So bleibt bei
      // einem leeren Post keine leere untere Haelfte stehen.
      body: CustomScrollView(
        slivers: [
          SliverFillRemaining(
            hasScrollBody: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(child: _buildComposer()),
                  const SizedBox(height: 12),
                  _buildCategorySection(),
                  const SizedBox(height: 12),
                  _buildLocationRow(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Karte im Stil der Text-Posts im Feed (flach, surfaceContainerLow, r16).
  // Material statt Container mit Farbe: sonst verdeckt die Farbe den
  // InkWell-Ripple (z.B. beim Antippen der Standort-Karte).
  Widget _card({required Widget child}) {
    return Material(
      color: AppColors.surfaceContainerLow,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: child,
    );
  }

  // Kleines getoentes Icon-Badge vor Kategorie/Standort -> Farbakzent,
  // ohne die Flaechen selbst einzufaerben.
  Widget _sectionIcon(IconData icon) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, size: 18, color: AppColors.primary),
    );
  }

  // Threads/X-Stil: Avatar links, rechts daneben Name, Felder und Anhang.
  // Die Karte fuellt den freien Platz; unten sitzt die Medien-Toolbar.
  Widget _buildComposer() {
    // select -> nur neu bauen, wenn sich Bild oder Name aendern.
    final picUrl = context.select<ProfileProvider, String?>(
      (p) => p.userdata['profile_picture_url']?.toString(),
    );
    final username = context.select<ProfileProvider, String>(
      (p) => p.userdata['username']?.toString() ?? '',
    );
    final image = _image;

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _ComposerAvatar(picUrl: picUrl, username: username),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        username,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color: AppColors.onSurface,
                        ),
                      ),
                      TextField(
                        controller: titleController,
                        textCapitalization: TextCapitalization.sentences,
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: AppColors.onSurface,
                        ),
                        decoration: _bareInput(
                          context.l10n.createPostTitleHint,
                        ),
                      ),
                      TextField(
                        controller: contentController,
                        focusNode: _contentFocus,
                        // maxLines null -> Feld waechst mit dem Text mit, gescrollt
                        // wird der ganze Screen (wie bei Threads/X).
                        minLines: 1,
                        maxLines: null,
                        keyboardType: TextInputType.multiline,
                        textCapitalization: TextCapitalization.sentences,
                        style: TextStyle(
                          fontSize: 15,
                          height: 1.45,
                          color: AppColors.onSurface,
                        ),
                        decoration: _bareInput(
                          context.l10n.createPostContentHint,
                        ),
                      ),
                      if (image != null) ...[
                        const SizedBox(height: 10),
                        _buildAttachedImage(image),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Freie Flaeche der Karte: Tippen setzt den Cursor ins Textfeld
          // (sonst fuehlt sich der leere Bereich "tot" an).
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _contentFocus.requestFocus,
              child: const SizedBox(width: double.infinity, height: 24),
            ),
          ),
          // Medien-Toolbar unten in der Karte, Icons in primary (Aktion).
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 4),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.photo_library_outlined),
                  color: AppColors.primary,
                  tooltip: context.l10n.createPostGallery,
                  onPressed: pickImageFromGallery,
                ),
                IconButton(
                  icon: const Icon(Icons.photo_camera_outlined),
                  color: AppColors.primary,
                  tooltip: context.l10n.createPostCamera,
                  onPressed: pickImageFromCamera,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Randloses Eingabefeld: kein Rahmen, kein Fuell-Hintergrund, Hint grau.
  InputDecoration _bareInput(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: AppColors.onSurfaceVariant),
      border: InputBorder.none,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(vertical: 6),
    );
  }

  // Angehaengtes Bild in Originalproportion (max. 420 hoch, sonst cover),
  // oben rechts ein X zum Entfernen.
  Widget _buildAttachedImage(File image) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 420),
            child: Image.file(image, width: double.infinity, fit: BoxFit.cover),
          ),
        ),
        Positioned(
          top: 8,
          right: 8,
          child: Material(
            color: Colors.black.withValues(alpha: 0.55),
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: () => setState(() => _image = null),
              child: Padding(
                padding: const EdgeInsets.all(6),
                child: Icon(
                  Icons.close,
                  size: 18,
                  color: Colors.white,
                  semanticLabel: context.l10n.createPostRemoveImage,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Kategorie als Chip-Reihe: Ueberschrift + kurzer Hinweis, darunter die
  // drei Chips. Die Map-Keys ('Productivity' ...) sind die IDs fuers Backend
  // und den Entwurf -> nur die ANZEIGE wird uebersetzt.
  Widget _buildCategorySection() {
    final l10n = context.l10n;
    final categories = [
      (
        'Productivity',
        Icons.rocket_launch_outlined,
        l10n.createPostCategoryProductivity,
      ),
      ('Creativity', Icons.palette_outlined, l10n.createPostCategoryCreativity),
      ('Engagement', Icons.forum_outlined, l10n.createPostCategoryEngagement),
    ];

    return _card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _sectionIcon(Icons.local_offer_outlined),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.createPostCategory,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.onSurface,
                        ),
                      ),
                      Text(
                        l10n.createPostCategoryHint,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final (id, icon, label) in categories)
                  _CategoryChip(
                    icon: icon,
                    label: label,
                    active: iconActivated[id] ?? false,
                    onTap: () => _toggleIcon(id),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Standort als antippbare Karte (oeffnet den Location-Picker).
  Widget _buildLocationRow() {
    final l10n = context.l10n;
    final override = _overrideLocation;
    final String subtitle;
    if (override != null) {
      subtitle = l10n.createPostLocationOnlyThisPost;
    } else if (_defaultLocationName != null) {
      subtitle = l10n.createPostLocationYours;
    } else {
      subtitle = l10n.createPostLocationAdd;
    }
    final title =
        override?['name'] as String? ??
        _defaultLocationName ??
        l10n.createPostLocationNone;

    return _card(
      child: InkWell(
        onTap: _pickLocation,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 8, 10),
          child: Row(
            children: [
              _sectionIcon(Icons.location_on_outlined),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.onSurface,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              if (override != null)
                // Override zuruecknehmen -> Post erbt wieder den Heimatort.
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  color: AppColors.onSurfaceVariant,
                  tooltip: l10n.createPostLocationReset,
                  onPressed: () => setState(() => _overrideLocation = null),
                )
              else
                // Gleiche Breite wie der IconButton -> Text springt nicht.
                SizedBox(
                  width: 48,
                  height: 48,
                  child: Icon(
                    Icons.chevron_right,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Kategorie-Chip im Stil der Hype-Pille: aktiv = solid primary + weiss,
/// inaktiv = transparent mit outlineVariant-Rand. Rand ist IMMER da (aktiv in
/// primary), damit der Chip beim Umschalten nicht die Groesse aendert.
class _CategoryChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _CategoryChip({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final fg = active ? Colors.white : AppColors.onSurface;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: active ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: active ? AppColors.primary : AppColors.outlineVariant,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: active ? Colors.white : AppColors.primary,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: fg,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Kompakte "Posten"-Pille in der AppBar (solid primary, kein Schatten) –
/// gleiche Form wie die Teilen-Pille in der Story-Vorschau.
class _PostPill extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _PostPill({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Material(
        color: AppColors.primary,
        shape: const StadiumBorder(),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Eigener Avatar im Composer: abgerundetes Quadrat wie in der Story-Reihe,
/// Fallback = erster Buchstabe des Namens.
class _ComposerAvatar extends StatelessWidget {
  final String? picUrl;
  final String username;

  const _ComposerAvatar({required this.picUrl, required this.username});

  @override
  Widget build(BuildContext context) {
    final url = picUrl;
    final hasPic = url != null && url.isNotEmpty && url != 'null';
    final letter = username.isNotEmpty ? username[0].toUpperCase() : '?';

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        width: 40,
        height: 40,
        child: hasPic
            ? Image(
                image: netImage(context, url, logicalWidth: 40),
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => _fallback(letter),
              )
            : _fallback(letter),
      ),
    );
  }

  Widget _fallback(String letter) {
    return Container(
      color: AppColors.surfaceContainerHighest,
      alignment: Alignment.center,
      child: Text(
        letter,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w800,
          color: AppColors.onSurfaceVariant,
        ),
      ),
    );
  }
}

class _Dot extends StatefulWidget {
  final int delay;
  const _Dot({required this.delay});
  @override
  State<_Dot> createState() => _DotState();
}

class _DotState extends State<_Dot> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
    _anim = Tween(begin: 0.0, end: -6.0).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: Interval(
          widget.delay / 1200,
          (widget.delay + 400) / 1200,
          curve: Curves.easeInOut,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, _) => Container(
        margin: const EdgeInsets.symmetric(horizontal: 3),
        transform: Matrix4.translationValues(0, _anim.value, 0),
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          color: AppColors.primary,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

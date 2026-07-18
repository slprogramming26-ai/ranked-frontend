import
'dart:io';
import 'package:flutter/foundation.dart';
import 'post_api_service.dart';
import 'package:flutter/material.dart';
import '../app_colors.dart';
import '../location_picker.dart';
import '../profile.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:async';
import 'package:image/image.dart' as img;
import 'package:provider/provider.dart';
import 'package:ranked/local_data/database.dart';

class CreatePost extends StatefulWidget {
  const CreatePost({super.key});

  @override
  State<CreatePost> createState() => _CreatePostState();
}

class _CreatePostState extends State<CreatePost> {
  late TextEditingController titleController;
  late TextEditingController contentController;
  late final AppDatabase _db;
  bool isPublic = true;
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
      _defaultLocationName = (provider.userdata['location']
          as Map<String, dynamic>?)?['name'] as String?;
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
    _db.deletePostDraft();
    super.dispose();
  }

  Future<void> fetchPostDraft() async {
    final postDraft = await _db.getPostDraft();
    if (postDraft == null || !mounted) return;

    isPublic = postDraft.isPublic;
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
        isPublic: isPublic,
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

  void _toggleIcon(String name) {
    final isActive = iconActivated[name] ?? false;
    final activeCount = iconActivated.values.where((v) => v).length;

    if (activeCount >= 1 && !isActive) return;

    setState(() {
      iconActivated[name] = !isActive;
    });
  }

  double _getOpacityForTag(String title) {
    bool isActive = iconActivated[title] ?? false;
    bool anyTagActive = iconActivated.values.any((isActive) => isActive);
    if (isActive) return 1.0;
    if (anyTagActive) return 0.5;
    return 1.0;
  }

  static const _kPremiumShadow = [
    BoxShadow(
      color: Color(0x0DB41B00),
      blurRadius: 30,
      offset: Offset(0, 10),
      spreadRadius: -5,
    ),
    BoxShadow(
      color: Color(0x05000000),
      blurRadius: 15,
      offset: Offset(0, 4),
      spreadRadius: -5,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFAF9),
      appBar: AppBar(
        backgroundColor: Colors.white.withValues(alpha: 0.6),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            color: AppColors.outlineVariant.withValues(alpha: 0.1),
          ),
        ),
        leading: Padding(
          padding: const EdgeInsets.only(left: 8),
          child: IconButton(
            icon: Icon(
              Icons.close,
              color: AppColors.onSurface.withValues(alpha: 0.7),
            ),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        title: Text(
          'Create Post',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w800,
            color: AppColors.primary,
            fontSize: 20,
            letterSpacing: -0.5,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0, top: 8, bottom: 8),
            child: ElevatedButton(
              onPressed: () async {
                try {
                  String? imageUrl;
                  _showLoadingDialog(context);
                  if (_image != null) {
                    // Komprimierung im Hintergrund-Isolate – UI/Dialog bleibt flüssig.
                    // compute() schickt NUR den path-String ins Isolate, keine
                    // Closure die den Widget-Baum einfängt (sonst „unsendable").
                    final path = _image!.path;
                    final compressedPath = await compute(_compressImage, path);
                    final fileToUpload = compressedPath != null
                        ? File(compressedPath)
                        : _image!;

                    imageUrl = await PostApiService.uploadPostImage(
                      fileToUpload,
                    );

                    if (!context.mounted) return;

                    if (imageUrl == null) {
                      Navigator.pop(context);

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Bild-Upload fehlgeschlagen'),
                        ),
                      );

                      return;
                    }
                  }

                  final success = await PostApiService.createPost(
                    titleController.text,
                    contentController.text,
                    isPublic,
                    imageUrl,
                    iconActivated.entries
                        .where((e) => e.value)
                        .map((e) => e.key)
                        .firstOrNull
                        ?.toLowerCase(),
                    locationId: _overrideLocation?['id'] as int?,
                  );

                  if (!context.mounted) return;
                  Navigator.pop(context);

                  if (success) {
                    Navigator.pop(context);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Post konnte nicht erstellt werden'),
                      ),
                    );
                  }
                } catch (_) {
                  // Unerwarteter Fehler: Dialog schließen, damit die UI nicht
                  // hängen bleibt, und dem User kurz Bescheid geben.
                  if (!context.mounted) return;
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Etwas ist schiefgelaufen')),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: const StadiumBorder(),
                elevation: 4,
                shadowColor: AppColors.primary.withValues(alpha: 0.3),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 0,
                ),
              ),
              child: Text(
                'Post',
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. MEDIA UPLOAD AREA
            AspectRatio(
              aspectRatio: 4 / 5,
              child: _image == null
                  ? CustomPaint(
                      painter: _DashedBorderPainter(
                        color: AppColors.outlineVariant.withValues(alpha: 0.4),
                        strokeWidth: 2,
                        borderRadius: 28,
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.02),
                          borderRadius: BorderRadius.circular(28),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 96,
                              height: 96,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(24),
                                boxShadow: _kPremiumShadow,
                              ),
                              child: Icon(
                                Icons.add_a_photo_outlined,
                                color: AppColors.primary,
                                size: 44,
                              ),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              'Drop your Pulse',
                              style: GoogleFonts.plusJakartaSans(
                                fontWeight: FontWeight.w800,
                                fontSize: 22,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 48,
                              ),
                              child: Text(
                                'Share a photo or video to start climbing the rankings.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: AppColors.onSurfaceVariant.withValues(
                                    alpha: 0.8,
                                  ),
                                  fontSize: 13,
                                  height: 1.5,
                                ),
                              ),
                            ),
                            const SizedBox(height: 32),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                GestureDetector(
                                  onTap: pickImageFromGallery,
                                  child: _buildMediaButton(
                                    Icons.image_outlined,
                                    'Library',
                                  ),
                                ),
                                const SizedBox(width: 12),
                                GestureDetector(
                                  onTap: pickImageFromCamera,
                                  child: _buildMediaButton(
                                    Icons.videocam_outlined,
                                    'Camera',
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    )
                  : ClipRRect(
                      borderRadius: BorderRadius.circular(28),
                      child: Image.file(
                        _image!,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                      ),
                    ),
            ),

            const SizedBox(height: 24),

            // 2. CAPTION CARD
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: AppColors.outlineVariant.withValues(alpha: 0.1),
                ),
                boxShadow: _kPremiumShadow,
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: AppColors.surfaceContainerHigh,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: Colors.white, width: 2),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.08),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.person,
                              color: AppColors.onSurfaceVariant,
                              size: 24,
                            ),
                          ),
                          Positioned(
                            bottom: -2,
                            right: -2,
                            child: Container(
                              width: 14,
                              height: 14,
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 2,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 14),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Ich',
                            style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                              height: 1.2,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Creator',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: AppColors.onSurfaceVariant.withValues(
                                alpha: 0.6,
                              ),
                              letterSpacing: 1.0,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  TextField(
                    controller: titleController,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: AppColors.onSurface,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Post title...',
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 8),
                      hintStyle: TextStyle(
                        color: AppColors.outlineVariant.withValues(alpha: 0.7),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  TextField(
                    controller: contentController,
                    maxLines: 5,
                    onChanged: (_) => setState(() {}),
                    style: TextStyle(
                      fontSize: 15,
                      color: AppColors.onSurface,
                      height: 1.55,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Tell your story...',
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                      hintStyle: TextStyle(
                        color: AppColors.outlineVariant.withValues(alpha: 0.7),
                        fontSize: 15,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Divider(
                    color: AppColors.outlineVariant.withValues(alpha: 0.15),
                    height: 1,
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      _buildCaptionAction(Icons.alternate_email),
                      const SizedBox(width: 20),
                      _buildCaptionAction(Icons.tag),
                      const SizedBox(width: 20),
                      _buildCaptionAction(Icons.mood_outlined),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${contentController.text.length}/2200',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: AppColors.outlineVariant,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // 3. TAGS SECTION
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.bolt, color: AppColors.primary, size: 20),
                ),
                const SizedBox(width: 10),
                Text(
                  'Tag your Pulse',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w800,
                    fontSize: 20,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.only(left: 2, bottom: 16),
              child: Text(
                'Categorize your post to compete in specific leaderboards.',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppColors.onSurfaceVariant.withValues(alpha: 0.7),
                ),
              ),
            ),
            _buildCategoryItem(
              Icons.rocket_launch_outlined,
              'Productivity',
              'Climb the efficiency ladder',
            ),
            _buildCategoryItem(
              Icons.palette_outlined,
              'Creativity',
              'Express the inner vision',
            ),
            _buildCategoryItem(
              Icons.forum_outlined,
              'Engagement',
              'Drive the conversation',
            ),

            const SizedBox(height: 24),

            // 4. VISIBILITY SWITCH
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: AppColors.outlineVariant.withValues(alpha: 0.1),
                ),
                boxShadow: _kPremiumShadow,
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.public,
                      color: AppColors.onSurfaceVariant,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Public Post',
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Visible to the global Pulse',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: AppColors.onSurfaceVariant.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Switch(
                    value: isPublic,
                    activeColor: AppColors.primary,
                    onChanged: (val) => setState(() => isPublic = val),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // 5. LOCATION CARD
            _buildLocationCard(),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationCard() {
    final override = _overrideLocation;
    final String subtitle;
    if (override != null) {
      subtitle = 'Nur für diesen Post';
    } else if (_defaultLocationName != null) {
      subtitle = 'Dein Standort';
    } else {
      subtitle = 'Optional hinzufügen';
    }
    final title = override?['name'] as String? ??
        _defaultLocationName ??
        'Kein Standort';

    return GestureDetector(
      onTap: _pickLocation,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: AppColors.outlineVariant.withValues(alpha: 0.1),
          ),
          boxShadow: _kPremiumShadow,
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.location_on_outlined,
                color: AppColors.onSurfaceVariant,
                size: 20,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: AppColors.onSurfaceVariant.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
            if (override != null)
              // Override zuruecknehmen -> Post erbt wieder den Heimatort.
              IconButton(
                icon: Icon(
                  Icons.close,
                  size: 20,
                  color: AppColors.onSurfaceVariant,
                ),
                tooltip: 'Zurück zu deinem Standort',
                onPressed: () => setState(() => _overrideLocation = null),
              )
            else
              Icon(
                Icons.chevron_right,
                color: AppColors.onSurfaceVariant,
                size: 22,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCaptionAction(IconData icon) {
    return Icon(
      icon,
      color: AppColors.onSurfaceVariant.withValues(alpha: 0.7),
      size: 20,
    );
  }

  Widget _buildMediaButton(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.onSurface),
          const SizedBox(width: 8),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryItem(IconData icon, String title, String subtitle) {
    bool isActive = iconActivated[title] ?? false;

    return GestureDetector(
      onTap: () => _toggleIcon(title),
      child: AnimatedOpacity(
        opacity: _getOpacityForTag(title),
        duration: const Duration(milliseconds: 250),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isActive
                  ? AppColors.primary.withValues(alpha: 0.25)
                  : AppColors.outlineVariant.withValues(alpha: 0.12),
            ),
            boxShadow: isActive ? _kPremiumShadow : [],
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: isActive
                      ? AppColors.primary.withValues(alpha: 0.1)
                      : AppColors.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: AppColors.primary, size: 22),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                      color: isActive ? AppColors.primary : AppColors.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.onSurfaceVariant.withValues(alpha: 0.6),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                transitionBuilder: (Widget child, Animation<double> animation) {
                  return RotationTransition(
                    turns: Tween<double>(
                      begin: -0.25,
                      end: 0.0,
                    ).animate(animation),
                    child: FadeTransition(opacity: animation, child: child),
                  );
                },
                child: isActive
                    ? Icon(
                        Icons.check_circle_rounded,
                        key: const ValueKey('checkIcon'),
                        color: AppColors.primary,
                        size: 26,
                      )
                    : Icon(
                        Icons.add_circle_outline_rounded,
                        key: const ValueKey('addIcon'),
                        color: AppColors.outlineVariant,
                        size: 26,
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Läuft in einem separaten Isolate (kein Zugriff auf `this`/State).
/// Bekommt nur den Pfad, dekodiert/skaliert/kodiert das Bild und schreibt
/// es als neue Datei. Gibt den Pfad der komprimierten Datei zurück – oder
/// null, wenn das Bild nicht dekodiert werden konnte.
Future<String?> _compressImage(String path) async {
  final bytes = await File(path).readAsBytes();
  final decoded = img.decodeImage(bytes);
  if (decoded == null) return null;

  final resized = (decoded.width > 1080 || decoded.height > 1080)
      ? img.copyResize(
          decoded,
          width: decoded.width >= decoded.height ? 1080 : null,
          height: decoded.height > decoded.width ? 1080 : null,
        )
      : decoded;

  final fixed = img.encodeJpg(resized, quality: 85);
  final newPath = '$path.compressed.jpg';
  await File(newPath).writeAsBytes(fixed);
  return newPath;
}

class _DashedBorderPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double borderRadius;

  const _DashedBorderPainter({
    required this.color,
    required this.strokeWidth,
    required this.borderRadius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    const dashWidth = 10.0;
    const dashSpace = 7.0;
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            strokeWidth / 2,
            strokeWidth / 2,
            size.width - strokeWidth,
            size.height - strokeWidth,
          ),
          Radius.circular(borderRadius),
        ),
      );

    for (final metric in path.computeMetrics()) {
      double distance = 0;
      while (distance < metric.length) {
        canvas.drawPath(
          metric.extractPath(distance, distance + dashWidth),
          paint,
        );
        distance += dashWidth + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

void _showLoadingDialog(BuildContext context) {
  showDialog(
    context: context,
    barrierDismissible: false,
    barrierColor: AppColors.onSurface.withValues(alpha: 0.55),
    builder: (context) => const _RankedLoadingDialog(),
  );
}

class _RankedLoadingDialog extends StatefulWidget {
  const _RankedLoadingDialog();
  @override
  State<_RankedLoadingDialog> createState() => _RankedLoadingDialogState();
}

class _RankedLoadingDialogState extends State<_RankedLoadingDialog> {
  final List<String> _messages = [
    'Uploading media...',
    'Creating your post...',
    'Almost there...',
  ];
  int _index = 0;
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 1800), (_) {
      setState(() => _index = (_index + 1) % _messages.length);
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Container(
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(28),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 80,
              height: 80,
              child: CircularProgressIndicator(
                strokeWidth: 6,
                color: AppColors.primary,
                backgroundColor: AppColors.surfaceContainer,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Sending your Pulse',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppColors.onSurface,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 6),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Text(
                _messages[_index],
                key: ValueKey(_index),
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.onSurfaceVariant,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(3, (i) => _Dot(delay: i * 200)),
            ),
          ],
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
      builder: (_, __) => Container(
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

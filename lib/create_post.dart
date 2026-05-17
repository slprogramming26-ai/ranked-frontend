import 'dart:io';
import 'post_api_service.dart';
import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:async';
import 'package:image/image.dart' as img;

class CreatePost extends StatefulWidget {
  const CreatePost({super.key});

  @override
  State<CreatePost> createState() => _CreatePostState();
}

class _CreatePostState extends State<CreatePost> {
  late TextEditingController titleController;
  late TextEditingController contentController;
  bool isPublic = true;
  File? _image;

  @override
  void initState() {
    super.initState();
    titleController = TextEditingController();
    contentController = TextEditingController();
  }

  @override
  void dispose() {
    titleController.dispose();
    contentController.dispose();
    super.dispose();
  }

  final _picker = ImagePicker();

  Future<File?> _fixOrientation(String path) async {
    final bytes = await File(path).readAsBytes();
    final decoded = img.decodeImage(bytes);
    if (decoded == null) return null;
    final fixed = img.encodeJpg(decoded);
    return await File(path).writeAsBytes(fixed);
  }

  pickImageFromGallery() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      _image = await _fixOrientation(pickedFile.path) ?? File(pickedFile.path);
      setState(() {});
    }
  }

  pickImageFromCamera() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.camera);

    if (pickedFile != null) {
      _image = await _fixOrientation(pickedFile.path) ?? File(pickedFile.path);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: AppColors.primary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Create Post',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w800,
            color: AppColors.primary,
            fontSize: 18,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0, top: 8, bottom: 8),
            child: ElevatedButton(
              onPressed: () async {
                String? imageUrl;
                _showLoadingDialog(context);
                // Erst Bild hochladen falls vorhanden
                if (_image != null) {
                  imageUrl = await PostApiService.uploadPostImage(_image!);

                  if (!context.mounted) return;

                  if (imageUrl == null) {
                    Navigator.pop(context);

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Bild-Upload fehlgeschlagen')),
                    );

                    return;
                  }

                }

                final success = await PostApiService.createPost(
                  titleController.text,
                  contentController.text,
                  isPublic,
                  imageUrl,
                    iconActivated.entries.where((e) => e.value).map((e) => e.key).firstOrNull
                );

                if (!context.mounted) return;
                Navigator.pop(context);

                if (success) {
                  Navigator.pop(context); // CreatePost schließen
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Post konnte nicht erstellt werden'),
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: const StadiumBorder(),
                elevation: 4,
                shadowColor: AppColors.primary.withOpacity(0.4),
              ),
              child: const Text(
                'Post',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. MEDIA SELECTION AREA (Bento Style)
            Container(
              width: double.infinity,
              height: 300,
              decoration: BoxDecoration(
                color: AppColors.surfaceContainer,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: AppColors.primary.withOpacity(0.1),
                  width: 2,
                ),
              ),
              child: _image == null
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.add_a_photo,
                            color: AppColors.primary,
                            size: 40,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Drop your Pulse',
                          style: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.w800,
                            fontSize: 20,
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 40,
                            vertical: 8,
                          ),
                          child: Text(
                            'Share a photo or video to start climbing the rankings.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: AppColors.onSurfaceVariant,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            InkWell(
                              onTap: () {
                                pickImageFromGallery();
                              },
                              child: _buildMediaButton(Icons.image, "Library"),
                            ),
                            const SizedBox(width: 12),
                            InkWell(
                              onTap: () {
                                pickImageFromCamera();
                              },
                              child: _buildMediaButton(
                                Icons.videocam,
                                "Camera",
                              ),
                            ),
                          ],
                        ),
                      ],
                    )
                  : Image.file(_image!),
            ),

            const SizedBox(height: 24),

            // 2. CAPTION AREA
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      const CircleAvatar(
                        radius: 20,
                        backgroundColor: AppColors.surfaceContainerHigh,
                        child: Text(
                          "ME",
                          style: TextStyle(color: AppColors.onSurface),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        "Ich",
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  TextField(
                    controller: titleController,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    decoration: const InputDecoration(
                      hintText: "Post Title",
                      border: InputBorder.none,
                      hintStyle: TextStyle(color: AppColors.outlineVariant),
                    ),
                  ),
                  TextField(
                    controller: contentController,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      hintText: "Write a caption...",
                      border: InputBorder.none,
                      hintStyle: TextStyle(color: AppColors.outlineVariant),
                    ),
                  ),
                  const Divider(color: Color(0x1F834C4F)),
                  Row(
                    children: [
                      const Icon(
                        Icons.alternate_email,
                        color: AppColors.outlineVariant,
                        size: 20,
                      ),
                      const SizedBox(width: 16),
                      const Icon(Icons.tag, color: AppColors.outlineVariant, size: 20),
                      const SizedBox(width: 16),
                      const Icon(
                        Icons.mood,
                        color: AppColors.outlineVariant,
                        size: 20,
                      ),
                      const Spacer(),
                      Text(
                        "${contentController.text.length}/2200",
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: AppColors.outlineVariant,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // 3. TAGS SECTION
            Row(
              children: [
                const Icon(Icons.bolt, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(
                  "Tag your Pulse",
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildCategoryItem(
              Icons.rocket_launch,
              "Productivity",
              "Climb the efficiency ladder",
            ),
            _buildCategoryItem(
              Icons.palette,
              "Creativity",
              "Express the inner vision",
            ),
            _buildCategoryItem(
              Icons.chat,
              "Engagement",
              "Drive the conversation",
            ),

            const SizedBox(height: 24),

            // 4. VISIBILITY SWITCH
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainer,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  const Icon(Icons.public, color: AppColors.onSurfaceVariant),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Public Post",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        "Visible to the global Pulse",
                        style: TextStyle(color: Colors.grey[600], fontSize: 10),
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
          ],
        ),
      ),
    );
  }

  Widget _buildMediaButton(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.onSurface),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryItem(IconData icon, String title, String subtitle) {
    bool isActive = iconActivated[title] ?? false;

    return GestureDetector(
      onTap: () {
        _toggleIcon(title);
      },
      child: AnimatedOpacity(
        // Nutzt die Hilfsmethode für den Opacity-Wert
        opacity: _getOpacityForTag(title),
        duration: const Duration(milliseconds: 250), // Sanfter Übergang beim Ghosting
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainer,
            borderRadius: BorderRadius.circular(16),
            // Optional: Ein subtiler Rand, wenn aktiv
            border: isActive
                ? Border.all(color: AppColors.primary.withOpacity(0.5), width: 1)
                : Border.all(color: Colors.transparent, width: 1),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: AppColors.primary),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  Text(subtitle,
                      style: const TextStyle(fontSize: 10, fontStyle: FontStyle.italic)),
                ],
              ),
              const Spacer(),

              // --- HIER IST DIE ANIMATION ---
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300), // Dauer der Drehung/Fades
                transitionBuilder: (Widget child, Animation<double> animation) {
                  // Das neue Icon dreht sich von -90 Grad (pi/2) auf 0 Grad
                  return RotationTransition(
                    turns: Tween<double>(begin: -0.25, end: 0.0).animate(animation),
                    child: FadeTransition(opacity: animation, child: child),
                  );
                },
                // WICHTIG: Das 'key' Attribut sagt Flutter, welches Icon sich ändert
                child: isActive
                    ? Icon(
                  Icons.check,
                  key: const ValueKey('checkIcon'), // Eindeutiger Key
                  color: AppColors.primary, // Kräftigere Farbe für 'aktiv'
                )
                    : Icon(
                  Icons.add,
                  key: const ValueKey('addIcon'), // Eindeutiger Key
                  color: AppColors.outlineVariant,
                ),
              ),
              // ------------------------------
            ],
          ),
        ),
      ),
    );
  }


}

void _showLoadingDialog(BuildContext context) {
  showDialog(
    context: context,
    barrierDismissible: false,
    barrierColor: AppColors.onSurface.withOpacity(0.55),
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
                style: const TextStyle(fontSize: 13, color: AppColors.onSurfaceVariant),
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
        decoration: const BoxDecoration(
          color: AppColors.primary,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

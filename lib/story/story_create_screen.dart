import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:pro_image_editor/pro_image_editor.dart';

import '../app_colors.dart';
import '../local_data/database.dart';
import 'story.dart';
import 'story_editor_configs.dart';

/// Story-Erstellung im "ranked"-Look.
///
/// Flow: Quelle wählen (Galerie/Kamera) -> Bild ins 9:16-Format bringen
/// (Hintergrund-Isolate, kein UI-Freeze) -> ranked-Editor -> Vorschau ->
/// hochladen. Bei Erfolg landet die Story über [StoryProvider.addStory]
/// sofort in der Story-Row des Feeds.
class StoryCreateScreen extends StatefulWidget {
  /// Foto, das nach einem Kamera-Prozesstod via retrieveLostData()
  /// zurueckgeholt wurde: steigt direkt in den Format->Editor-Flow ein.
  final String? recoveredImagePath;

  const StoryCreateScreen({super.key, this.recoveredImagePath});

  @override
  State<StoryCreateScreen> createState() => _StoryCreateScreenState();
}

enum _Stage { pick, preview }

class _StoryCreateScreenState extends State<StoryCreateScreen>
    with TickerProviderStateMixin {
  final _picker = ImagePicker();
  _Stage _stage = _Stage.pick;
  File? _image; // fertig bearbeitete Story (nach dem Editor)
  bool _processing = false; // Format-Schritt läuft (Loader-Overlay)
  bool _uploading = false;
  late final AppDatabase _db;

  // Zwei endlose Deko-Animationen fuer Stage 1 (Punkte-Orbit + Blob-Schweben).
  // Eigene Controller statt AnimatedXxx-Widgets, weil wir volle Kontrolle
  // ueber das Loop-Verhalten brauchen (repeat() statt einmalig A->B).
  late final AnimationController _rotationController;
  late final AnimationController _blobController;

  @override
  void initState() {
    super.initState();
    _db = Provider.of<AppDatabase>(context, listen: false);
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 14),
    )..repeat();
    _blobController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 18),
    )..repeat();
    final recovered = widget.recoveredImagePath;
    if (recovered != null) {
      // Erst nach dem ersten Frame, weil _openEditor navigiert und dafuer
      // der Screen fertig aufgebaut sein muss.
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _processPicked(File(recovered)),
      );
    }
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _blobController.dispose();
    super.dispose();
  }

  Future<void> _pick(ImageSource source) async {
    // Story-Marker VOR der Kamera: killt Android uns dort, weiss der
    // App-Start dadurch, dass das gerettete Foto eine Story werden sollte.
    if (source == ImageSource.camera) {
      await _db.savePostDraft(
        title: '',
        content: '',
        isPublic: true,
        draftType: 'story',
      );
    }
    final picked = await _picker.pickImage(source: source);
    if (source == ImageSource.camera) {
      // Normal zurueckgekehrt (kein Kill) -> Marker sofort wieder weg.
      await _db.deletePostDraft();
    }
    if (picked == null || !mounted) return;
    await _processPicked(File(picked.path));
  }

  Future<void> _processPicked(File picked) async {
    // 1. Ins 9:16-Format bringen (schwere Pixel-Arbeit im Isolate).
    setState(() => _processing = true);
    final formatted = await _toStoryFormat(picked);
    if (!mounted) return;
    setState(() => _processing = false);

    // 2. Direkt in den ranked-Editor.
    _openEditor(formatted);
  }

  Future<File> _toStoryFormat(File source) async {
    final bytes = await source.readAsBytes();
    final outBytes = await compute(_formatToStoryBytes, bytes);
    final out = File(
      '${Directory.systemTemp.path}/story_fmt_'
      '${DateTime.now().millisecondsSinceEpoch}.jpg',
    );
    await out.writeAsBytes(outBytes);
    return out;
  }

  Future<void> _openEditor(File source) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ProImageEditor.file(
          source,
          configs: buildRankedStoryEditorConfigs(context),
          callbacks: ProImageEditorCallbacks(
            onImageEditingComplete: (Uint8List bytes) async {
              final tempFile = File(
                '${Directory.systemTemp.path}/story_'
                '${DateTime.now().millisecondsSinceEpoch}.jpg',
              );
              await tempFile.writeAsBytes(bytes);
              if (!mounted) return;
              setState(() {
                _image = tempFile;
                _stage = _Stage.preview;
              });
              Navigator.of(context).pop(); // Editor schließen -> Vorschau
            },
          ),
        ),
      ),
    );
  }

  Future<void> _upload() async {
    if (_image == null) return;
    setState(() => _uploading = true);

    final data = await StoryApiService.uploadStory(_image!);
    if (!mounted) return;
    setState(() => _uploading = false);

    if (data == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Story-Upload fehlgeschlagen')),
      );
      return;
    }

    // Story sofort in den Provider -> Row im Feed aktualisiert sich direkt.
    context.read<StoryProvider>().addStory(data);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        _stage == _Stage.pick ? _buildPickStage() : _buildPreviewStage(),
        if (_processing) _buildProcessingOverlay(),
      ],
    );
  }

  // --- Stage 1: Quelle wählen -------------------------------------------------

  Widget _buildPickStage() {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Stack(
        children: [
          // Dekorative Glow-Blobs im Hintergrund (RadialGradient statt echtem
          // Blur-Filter -> optisch fast gleich, aber ohne Blur-Kosten).
          // Position bleibt fix (Positioned), nur der Transform.translate
          // innen bewegt sie -> reines Neu-Zeichnen, kein Re-Layout.
          Positioned(
            top: -50,
            right: -60,
            child: _floatingBlob(
              _glowBlob(AppColors.primary, 220),
              phase: 0,
            ),
          ),
          Positioned(
            bottom: -70,
            left: -70,
            // Gegenphase (+ pi) -> bewegt sich entgegengesetzt zum ersten
            // Blob, wirkt organischer als synchrones Schweben.
            child: _floatingBlob(
              _glowBlob(AppColors.primaryContainer, 260),
              phase: math.pi,
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                // Kopfzeile
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 8, 20, 0),
                  child: Row(
                    children: [
                      IconButton(
                        icon: Icon(Icons.close, color: AppColors.onSurface),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      Text(
                        'Neue Story',
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w800,
                          fontSize: 20,
                          letterSpacing: -0.5,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: TweenAnimationBuilder<double>(
                      // Sanftes Einblenden/Hochgleiten beim Öffnen des Screens
                      // (rein kosmetisch, läuft einmalig).
                      tween: Tween(begin: 0, end: 1),
                      duration: const Duration(milliseconds: 500),
                      curve: Curves.easeOutCubic,
                      builder: (context, t, child) => Opacity(
                        opacity: t,
                        child: Transform.translate(
                          offset: Offset(0, (1 - t) * 20),
                          child: child,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Hero-Icon mit Gradient-Ring + verstreuten
                          // Akzent-Punkten (Story-Ring-Optik, etwas verspielt).
                          SizedBox(
                            width: 150,
                            height: 150,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                // Orbit-Gruppe: die 3 Punkte bleiben relativ
                                // zueinander fix, nur die ganze Gruppe rotiert
                                // um den Mittelpunkt -> wirkt wie ein Orbit
                                // ums Icon. Icon selbst bleibt unrotiert
                                // (steht als eigenes Geschwister daneben).
                                AnimatedBuilder(
                                  animation: _rotationController,
                                  builder: (context, child) => Transform.rotate(
                                    angle: _rotationController.value * 2 * math.pi,
                                    child: child,
                                  ),
                                  child: SizedBox(
                                    width: 150,
                                    height: 150,
                                    child: Stack(
                                      children: [
                                        Positioned(
                                          top: 2,
                                          right: 14,
                                          child: _sparkleDot(
                                            AppColors.primaryContainer,
                                            14,
                                          ),
                                        ),
                                        Positioned(
                                          bottom: 14,
                                          left: 2,
                                          child: _sparkleDot(Colors.white, 9),
                                        ),
                                        Positioned(
                                          top: 24,
                                          left: 6,
                                          child: _sparkleDot(AppColors.primary, 11),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                Container(
                                  width: 120,
                                  height: 120,
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
                                        color: AppColors.primary.withValues(alpha: 0.35),
                                        blurRadius: 30,
                                        offset: const Offset(0, 12),
                                        spreadRadius: -6,
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.auto_awesome,
                                    color: Colors.white,
                                    size: 52,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'Teile deinen Moment',
                            style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.w800,
                              fontSize: 24,
                              letterSpacing: -0.5,
                              color: AppColors.onSurface,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Erstelle in Sekunden eine Story für deine Follower.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              height: 1.5,
                              color: AppColors.onSurfaceVariant.withValues(alpha: 0.8),
                            ),
                          ),
                          const SizedBox(height: 14),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.bolt_rounded,
                                  size: 14,
                                  color: AppColors.primary,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '24H sichtbar',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 52),
                          Row(
                            children: [
                              Expanded(
                                child: _SourceCard(
                                  icon: Icons.photo_library_rounded,
                                  label: 'Galerie',
                                  subtitle: 'Bild wählen',
                                  filled: true,
                                  onTap: () => _pick(ImageSource.gallery),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: _SourceCard(
                                  icon: Icons.photo_camera_rounded,
                                  label: 'Kamera',
                                  subtitle: 'Live aufnehmen',
                                  filled: false,
                                  onTap: () => _pick(ImageSource.camera),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Legt einen sanften Schwebe-Versatz um den Blob herum: [phase] verschiebt
  // die Sinuskurve, damit zwei Blobs, die denselben Controller nutzen, sich
  // trotzdem nicht synchron bewegen (wirkt organischer/zufälliger).
  Widget _floatingBlob(Widget blob, {required double phase}) {
    return AnimatedBuilder(
      animation: _blobController,
      builder: (context, child) {
        final t = _blobController.value * 2 * math.pi + phase;
        return Transform.translate(
          offset: Offset(math.sin(t) * 24, math.cos(t) * 18),
          child: child,
        );
      },
      child: blob,
    );
  }

  Widget _glowBlob(Color color, double size) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [color.withValues(alpha: 0.28), color.withValues(alpha: 0)],
          ),
        ),
      ),
    );
  }

  Widget _sparkleDot(Color color, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: 0.85),
        boxShadow: [
          BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 8),
        ],
      ),
    );
  }

  // --- Stage 2: Vorschau + Teilen --------------------------------------------

  Widget _buildPreviewStage() {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Das fertige 9:16-Bild
          if (_image != null)
            Center(child: Image.file(_image!, fit: BoxFit.contain)),

          // Sanfter dunkler Verlauf unten für die Button-Lesbarkeit
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: 220,
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.7),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Zurück-Button (oben links) -> nochmal neu wählen
          SafeArea(
            child: Align(
              alignment: Alignment.topLeft,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: _circleIconButton(
                  Icons.arrow_back,
                  onTap: _uploading
                      ? null
                      : () => setState(() {
                            _stage = _Stage.pick;
                            _image = null;
                      }),
                ),
              ),
            ),
          ),

          // Teilen-Button (unten)
          SafeArea(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                child: SizedBox(
                  width: double.infinity,
                  child: Material(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(30),
                    elevation: 6,
                    shadowColor: AppColors.primary.withValues(alpha: 0.4),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(30),
                      onTap: _uploading ? null : _upload,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (_uploading)
                              const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: Colors.white,
                                ),
                              )
                            else
                              const Icon(Icons.send_rounded,
                                  color: Colors.white, size: 20),
                            const SizedBox(width: 10),
                            Text(
                              _uploading ? 'Wird geteilt...' : 'Story teilen',
                              style: GoogleFonts.plusJakartaSans(
                                fontWeight: FontWeight.w800,
                                fontSize: 16,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _circleIconButton(IconData icon, {VoidCallback? onTap}) {
    return Material(
      color: Colors.black.withValues(alpha: 0.35),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Icon(icon, color: Colors.white, size: 22),
        ),
      ),
    );
  }

  // --- Format-Loader-Overlay --------------------------------------------------

  Widget _buildProcessingOverlay() {
    return Positioned.fill(
      // Material statt ColoredBox: das Overlay liegt im Stack NEBEN dem
      // Scaffold, ohne Material-Vorfahr rendert Text im gelb unterstrichenen
      // Fallback-Stil.
      child: Material(
        color: Colors.black.withValues(alpha: 0.75),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 64,
                height: 64,
                child: CircularProgressIndicator(
                  strokeWidth: 5,
                  color: AppColors.primary,
                  backgroundColor: Colors.white.withValues(alpha: 0.15),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Loading editor...',
                style: GoogleFonts.plusJakartaSans(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Quelle-Wählen-Card (Galerie/Kamera). Skaliert beim Antippen kurz runter
/// (Press-Feedback) statt nur auf den InkWell-Ripple zu verlassen — soll
/// haptischer/"drückbarer" wirken und zum Antippen einladen.
class _SourceCard extends StatefulWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final bool filled;
  final VoidCallback onTap;

  const _SourceCard({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.filled,
    required this.onTap,
  });

  @override
  State<_SourceCard> createState() => _SourceCardState();
}

class _SourceCardState extends State<_SourceCard> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed != value) setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final fg = widget.filled ? Colors.white : AppColors.onSurface;
    return GestureDetector(
      onTapDown: (_) => _setPressed(true),
      onTapUp: (_) => _setPressed(false),
      onTapCancel: () => _setPressed(false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? 0.94 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: Material(
          color: widget.filled ? AppColors.primary : AppColors.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(24),
          child: InkWell(
            borderRadius: BorderRadius.circular(24),
            // onTap bleibt hier leer -> GestureDetector oben entscheidet, wir
            // wollen nur den Ripple des InkWell als Zusatz-Feedback.
            onTap: widget.onTap,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                border: widget.filled
                    ? null
                    : Border.all(
                        color: AppColors.primary.withValues(alpha: 0.18),
                        width: 1.5,
                      ),
                boxShadow: widget.filled
                    ? [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.35),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                          spreadRadius: -4,
                        ),
                      ]
                    : null,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: widget.filled
                          ? Colors.white.withValues(alpha: 0.2)
                          : AppColors.primary.withValues(alpha: 0.12),
                    ),
                    child: Icon(widget.icon, color: fg, size: 22),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    widget.label,
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                      color: fg,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    widget.subtitle,
                    style: TextStyle(fontSize: 11, color: fg.withValues(alpha: 0.75)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Bildverarbeitung (läuft via compute in eigenem Isolate -> kein UI-Freeze).
// ---------------------------------------------------------------------------

// Story-Format: 9:16 hochkant, füllt den ganzen Screen.
const int _storyWidth = 1080;
const int _storyHeight = 1920;

/// Bringt das Bild ins 9:16-Format OHNE etwas abzuschneiden:
/// - Vordergrund: ganzes Bild "contain" (komplett sichtbar), zentriert.
/// - Hintergrund: dasselbe Bild "cover" + Weichzeichner, füllt den Rest.
/// Gibt die fertigen JPG-Bytes zurück.
Uint8List _formatToStoryBytes(Uint8List sourceBytes) {
  final decoded = img.decodeImage(sourceBytes);
  if (decoded == null) return sourceBytes;

  const targetRatio = _storyWidth / _storyHeight; // 0.5625
  final srcRatio = decoded.width / decoded.height;

  // --- Hintergrund: "cover" in 1/8-Groesse, blur, hochskalieren ---
  // Der Blur ist der teuerste Schritt (pure-Dart-CPU): in voller Groesse
  // dauert er Sekunden. Klein blurren + hochskalieren sieht identisch aus
  // (das Upscaling verschmiert selbst nochmal), kostet aber ~1/50.
  const smallW = _storyWidth ~/ 8; // 135
  const smallH = _storyHeight ~/ 8; // 240
  int bgW, bgH;
  if (srcRatio > targetRatio) {
    bgH = smallH;
    bgW = (smallH * srcRatio).round();
  } else {
    bgW = smallW;
    bgH = (smallW / srcRatio).round();
  }
  var small = img.copyResize(decoded, width: bgW, height: bgH);
  small = img.copyCrop(
    small,
    x: (bgW - smallW) ~/ 2,
    y: (bgH - smallH) ~/ 2,
    width: smallW,
    height: smallH,
  );
  small = img.gaussianBlur(small, radius: 3);
  var canvas = img.copyResize(
    small,
    width: _storyWidth,
    height: _storyHeight,
    interpolation: img.Interpolation.linear,
  );

  // --- Vordergrund: "contain" (ganzes Bild), zentriert draufsetzen ---
  int fgW, fgH;
  if (srcRatio > targetRatio) {
    fgW = _storyWidth;
    fgH = (_storyWidth / srcRatio).round();
  } else {
    fgH = _storyHeight;
    fgW = (_storyHeight * srcRatio).round();
  }
  final foreground = img.copyResize(decoded, width: fgW, height: fgH);
  img.compositeImage(
    canvas,
    foreground,
    dstX: (_storyWidth - fgW) ~/ 2,
    dstY: (_storyHeight - fgH) ~/ 2,
  );

  return img.encodeJpg(canvas, quality: 90);
}
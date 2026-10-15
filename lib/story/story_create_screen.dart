import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:pro_image_editor/pro_image_editor.dart';

import '../app_colors.dart';
import '../l10n/l10n.dart';
import '../app_loading.dart';
import '../image_sanitizer.dart';
import '../local_data/database.dart';
import '../net_image.dart';
import '../profile.dart';
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

class _StoryCreateScreenState extends State<StoryCreateScreen> {
  final _picker = ImagePicker();
  _Stage _stage = _Stage.pick;
  File? _image; // fertig bearbeitete Story (nach dem Editor)
  bool _processing = false; // Format-Schritt läuft (Loader-Overlay)
  bool _uploading = false;
  late final AppDatabase _db;

  @override
  void initState() {
    super.initState();
    _db = Provider.of<AppDatabase>(context, listen: false);
    final recovered = widget.recoveredImagePath;
    if (recovered != null) {
      // Erst nach dem ersten Frame, weil _openEditor navigiert und dafuer
      // der Screen fertig aufgebaut sein muss.
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _processPicked(File(recovered)),
      );
    }
  }

  Future<void> _pick(ImageSource source) async {
    // Story-Marker VOR der Kamera: killt Android uns dort, weiss der
    // App-Start dadurch, dass das gerettete Foto eine Story werden sollte.
    if (source == ImageSource.camera) {
      await _db.savePostDraft(
        title: '',
        content: '',
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

    // Kein Fallback auf die Originaldatei: die traegt noch GPS/Kameradaten.
    if (formatted == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.storyProcessingError)),
      );
      return;
    }

    // 2. Direkt in den ranked-Editor.
    _openEditor(formatted);
  }

  Future<File?> _toStoryFormat(File source) async {
    final bytes = await source.readAsBytes();
    final outBytes = await compute(_formatToStoryBytes, bytes);
    if (outBytes == null) return null;

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
        SnackBar(content: Text(context.l10n.storyUploadError)),
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

  // Kamera-Look wie Insta/TikTok: schwarzer Vollbild-Screen, oben X + Titel,
  // in der Mitte die "Sucher"-Flaeche (9:16-Leinwand der spaeteren Story),
  // unten Galerie-Kachel + Ausloeser. Bewusst immer dunkel (auch im
  // Light-Mode), damit Auswahl -> Editor -> Vorschau ein durchgehender
  // dunkler Flow ist.
  Widget _buildPickStage() {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            // Kopfzeile: X links, Titel mittig. Rechts ein gleich breiter
            // Platzhalter, damit der Titel wirklich in der Mitte sitzt.
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 4, 4, 8),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  Expanded(
                    child: Text(
                      context.l10n.storyCreateTitle,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),

            // Sucher-Flaeche: nimmt den Platz ueber den Bedienelementen ein.
            // Kein echtes Kamerabild (image_picker oeffnet die System-Kamera),
            // nur ein ruhiger Hinweis, was hier passiert.
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        context.l10n.storyPickHint,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 15,
                          height: 1.4,
                          color: Colors.white.withValues(alpha: 0.7),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        context.l10n.storyVisibleTime,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withValues(alpha: 0.4),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Bedienleiste: Galerie | Ausloeser | (leer). Links und rechts
            // gleich breite Expanded -> Ausloeser exakt mittig.
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
              child: Row(
                children: [
                  Expanded(
                    child: Align(
                      alignment: Alignment.center,
                      child: _GalleryButton(
                        label: context.l10n.storySourceGallery,
                        onTap: () => _pick(ImageSource.gallery),
                      ),
                    ),
                  ),
                  _ShutterButton(
                    semanticLabel: context.l10n.storySourceCamera,
                    onTap: () => _pick(ImageSource.camera),
                  ),
                  const Expanded(child: SizedBox()),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Stage 2: Vorschau + Teilen --------------------------------------------

  // Gleiches Geruest wie Stage 1 (Kopfzeile / Flaeche / Leiste), damit der
  // Sucher sichtbar zur fertigen Story "wird". Bedienelemente liegen auf
  // Schwarz statt auf dem Bild -> kein Verlauf/Glas-Kreis noetig.
  Widget _buildPreviewStage() {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            // Kopfzeile: Zurück -> nochmal neu wählen (Bearbeitung verworfen).
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 4, 4, 8),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: _uploading
                        ? null
                        : () => setState(() {
                            _stage = _Stage.pick;
                            _image = null;
                          }),
                  ),
                  Expanded(
                    child: Text(
                      context.l10n.storyPreviewTitle,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),

            // Die fertige Story exakt in 9:16 + r16 -> sieht aus wie spaeter
            // im Viewer. AspectRatio nimmt die groesste 9:16-Flaeche, die in
            // den freien Platz passt (je nach Display hoehen- oder
            // breitenbegrenzt), Center zentriert den Rest.
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Center(
                  child: AspectRatio(
                    aspectRatio: 9 / 16,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: _image != null
                          ? Image.file(_image!, fit: BoxFit.cover)
                          : const SizedBox(),
                    ),
                  ),
                ),
              ),
            ),

            // Leiste: wohin geteilt wird (neutral) | Teilen (Aktion = rot).
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
              child: Row(
                children: [
                  const _MyStoryChip(),
                  const Spacer(),
                  _SharePill(
                    uploading: _uploading,
                    onTap: _uploading ? null : _upload,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Format-Loader-Overlay --------------------------------------------------

  Widget _buildProcessingOverlay() {
    return const AppLoadingOverlay(messages: ['Loading editor...']);
  }
}

/// Skaliert sein Kind beim Gedrückthalten kurz runter (Press-Feedback wie
/// beim Kamera-Auslöser in Insta/TikTok). Ersetzt den Ripple: auf schwarzem
/// Grund und runden Formen sieht ein InkWell-Ripple eher fehl am Platz aus.
class _PressScale extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;

  const _PressScale({required this.child, required this.onTap});

  @override
  State<_PressScale> createState() => _PressScaleState();
}

class _PressScaleState extends State<_PressScale> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed != value) setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      // opaque: auch die transparenten Ecken um den runden Inhalt sind
      // antippbar -> groessere Trefferflaeche.
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => _setPressed(true),
      onTapUp: (_) => _setPressed(false),
      onTapCancel: () => _setPressed(false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? 0.92 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}

/// Runder Auslöser: weißer Ring + weiße Füllung mit schmalem schwarzen Spalt.
/// Öffnet die System-Kamera.
class _ShutterButton extends StatelessWidget {
  final String semanticLabel;
  final VoidCallback onTap;

  const _ShutterButton({required this.semanticLabel, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticLabel,
      child: _PressScale(
        onTap: onTap,
        child: Container(
          width: 78,
          height: 78,
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 4),
          ),
          child: const DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}

/// Galerie-Kachel links vom Auslöser (Insta-Position), mit Label darunter.
class _GalleryButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _GalleryButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return _PressScale(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white, width: 1.5),
            ),
            child: const Icon(
              Icons.photo_library_outlined,
              color: Colors.white,
              size: 22,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.white.withValues(alpha: 0.85),
            ),
          ),
        ],
      ),
    );
  }
}

/// "Wohin geht's"-Chip in der Vorschau: eigener Avatar + "Deine Story".
/// Rein informativ (nicht antippbar), daher neutral statt rot.
class _MyStoryChip extends StatelessWidget {
  const _MyStoryChip();

  @override
  Widget build(BuildContext context) {
    // select -> nur neu bauen, wenn sich Bild oder Name aendern.
    final picUrl = context.select<ProfileProvider, String?>(
      (p) => p.userdata['profile_picture_url']?.toString(),
    );
    final username = context.select<ProfileProvider, String>(
      (p) => p.userdata['username']?.toString() ?? '',
    );
    final hasPic = picUrl != null && picUrl.isNotEmpty && picUrl != 'null';
    final letter = username.isNotEmpty ? username[0].toUpperCase() : '?';

    return Container(
      padding: const EdgeInsets.fromLTRB(4, 4, 14, 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Abgerundetes Quadrat wie die Avatare in der Story-Reihe.
          ClipRRect(
            borderRadius: BorderRadius.circular(9),
            child: SizedBox(
              width: 30,
              height: 30,
              child: hasPic
                  ? Image(
                      image: netImage(context, picUrl, logicalWidth: 30),
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => _fallback(letter),
                    )
                  : _fallback(letter),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            context.l10n.storyYourStory,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _fallback(String letter) {
    return Container(
      color: Colors.white.withValues(alpha: 0.2),
      alignment: Alignment.center,
      child: Text(
        letter,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w800,
          color: Colors.white,
        ),
      ),
    );
  }
}

/// Kompakte Teilen-Pille (solid primary, kein Schatten). Beim Hochladen
/// ersetzt ein Spinner den Pfeil; onTap == null sperrt den Button.
class _SharePill extends StatelessWidget {
  final bool uploading;
  final VoidCallback? onTap;

  const _SharePill({required this.uploading, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.primary,
      shape: const StadiumBorder(),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 11, 16, 11),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                uploading
                    ? context.l10n.storyUploadingButton
                    : context.l10n.storyShareButton,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 8),
              if (uploading)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              else
                const Icon(
                  Icons.arrow_forward_rounded,
                  color: Colors.white,
                  size: 18,
                ),
            ],
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
Uint8List? _formatToStoryBytes(Uint8List sourceBytes) {
  // decodeImageSafely statt img.decodeImage: eine abgeschnittene Datei
  // (Prozesstod waehrend der Kamera) laesst die Decoder werfen, und hier
  // faengt niemand — der Fehler kaeme aus dem compute-Isolate zurueck.
  final raw = decodeImageSafely(sourceBytes);
  if (raw == null) return null;

  // Metadaten runter, BEVOR wir mit den Pixeln arbeiten: copyResize und
  // compositeImage klonen die EXIF-Daten des Originals sonst bis in die
  // fertige Leinwand — und der Encoder schreibt sie wieder ins JPG.
  // Die Drehung ist zu diesem Zeitpunkt schon eingebacken (der JPEG-Decoder
  // erledigt das selbst), `width`/`height` stimmen also mit dem ueberein,
  // was man spaeter sieht.
  final decoded = stripMetadata(raw);

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

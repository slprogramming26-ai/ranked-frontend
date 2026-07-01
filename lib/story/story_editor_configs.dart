import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pro_image_editor/pro_image_editor.dart';
import 'package:pro_image_editor/designs/grounded/grounded_design.dart';

import '../app_colors.dart';

/// Zentrale Editor-Konfiguration für Stories im "ranked"-Look.
///
/// Statt nur Farben zu setzen, wird hier das komplette "grounded"-Layout
/// verwendet: dunkler Vollbild-Canvas, Werkzeug-Leisten unten (wie ein echter
/// Story-Editor), eingebautes Undo/Redo/Done/Close. Darauf legen wir den
/// ranked-Look (Primary-Akzente), deutsche Texte und Story-typische Fonts.
///
/// [buildRankedStoryEditorConfigs] wird vom Story-Create-Screen an
/// `ProImageEditor.file(..., configs: ...)` übergeben.

// Story-relevante Werkzeuge (Reihenfolge = Reihenfolge in der Tool-Leiste).
// Bewusst schlank gehalten: Zeichnen, Text, Zuschneiden/Drehen, Filter, Emojis.
const List<SubEditorMode> _kRankedStoryTools = [
  SubEditorMode.text,
  SubEditorMode.paint,
  SubEditorMode.cropRotate,
  SubEditorMode.filter,
  SubEditorMode.emoji,
];

// Dunkler Editor-Hintergrund (Story-Editoren sind klassisch dunkel, damit das
// Bild im Fokus steht). Leicht ins ranked-Warmschwarz gezogen.
const Color _kEditorBg = Color(0xFF0E0B0A);
const Color _kEditorBar = Color(0xFF1A1413);

/// Baut die fertige Editor-Konfiguration. Braucht den [context] nur für den
/// Color-Picker-Dialog.
ProImageEditorConfigs buildRankedStoryEditorConfigs(BuildContext context) {
  // Eigene Farb-Auswahl im ranked-Stil (ersetzt den Default-ColorPicker).
  void showPicker(Color current, ValueChanged<Color> apply) {
    _showRankedColorPicker(context, current).then((picked) {
      if (picked != null) apply(picked);
    });
  }

  final scheme = ColorScheme.fromSeed(
    seedColor: AppColors.primary,
    brightness: Brightness.dark,
  ).copyWith(primary: AppColors.primary, surface: _kEditorBg);

  return ProImageEditorConfigs(
    theme: ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: scheme,
      scaffoldBackgroundColor: _kEditorBg,
    ),
    i18n: _rankedI18n,
    layerInteraction: const LayerInteractionConfigs(
      hideToolbarOnInteraction: false,
    ),

    // --- Haupt-Editor: dunkler Canvas + grounded Tool-Leiste unten ---
    mainEditor: MainEditorConfigs(
      tools: _kRankedStoryTools,
      style: const MainEditorStyle(
        background: _kEditorBg,
        bottomBarBackground: _kEditorBar,
        appBarBackground: _kEditorBg,
      ),
      widgets: MainEditorWidgets(
        appBar: (editor, rebuildStream) => null,
        bottomBar: (editor, rebuildStream, key) => ReactiveWidget(
          key: key,
          stream: rebuildStream,
          builder: (_) => GroundedMainBar(
            editor: editor,
            configs: editor.configs,
            callbacks: editor.callbacks,
          ),
        ),
      ),
    ),

    // --- Text: Story-Fonts + ranked Color-Picker ---
    textEditor: TextEditorConfigs(
      customTextStyles: [
        GoogleFonts.plusJakartaSans(),
        GoogleFonts.bebasNeue(),
        GoogleFonts.dancingScript(),
        GoogleFonts.lobster(),
        GoogleFonts.pacifico(),
        GoogleFonts.oswald(),
        GoogleFonts.caveat(),
      ],
      style: const TextEditorStyle(
        textFieldMargin: EdgeInsets.only(top: kToolbarHeight),
        bottomBarBackground: _kEditorBar,
        bottomBarMainAxisAlignment: MainAxisAlignment.spaceEvenly,
      ),
      widgets: TextEditorWidgets(
        appBar: (textEditor, rebuildStream) => null,
        colorPicker: (textEditor, rebuildStream, currentColor, setColor) => null,
        bottomBar: (editorState, rebuildStream) => ReactiveWidget(
          stream: rebuildStream,
          builder: (_) => GroundedTextBar(
            configs: editorState.configs,
            callbacks: editorState.callbacks,
            editor: editorState,
            i18nColor: 'Farbe',
            showColorPicker: (currentColor) =>
                showPicker(currentColor, (c) => editorState.primaryColor = c),
          ),
        ),
        bodyItems: (editorState, rebuildStream) => [
          ReactiveWidget(
            stream: rebuildStream,
            builder: (_) => Padding(
              padding: const EdgeInsets.only(top: kToolbarHeight),
              child: GroundedTextSizeSlider(textEditor: editorState),
            ),
          ),
        ],
      ),
    ),

    // --- Zeichnen: ranked Color-Picker + Primary-Akzente ---
    paintEditor: PaintEditorConfigs(
      style: const PaintEditorStyle(
        background: _kEditorBg,
        bottomBarBackground: _kEditorBar,
        initialStrokeWidth: 6,
      ),
      widgets: PaintEditorWidgets(
        appBar: (paintEditor, rebuildStream) => null,
        colorPicker: (paintEditor, rebuildStream, currentColor, setColor) =>
            null,
        bottomBar: (editorState, rebuildStream) => ReactiveWidget(
          stream: rebuildStream,
          builder: (_) => GroundedPaintBar(
            configs: editorState.configs,
            callbacks: editorState.callbacks,
            editor: editorState,
            i18nColor: 'Farbe',
            showColorPicker: (currentColor) =>
                showPicker(currentColor, (c) => editorState.setColor(c)),
          ),
        ),
      ),
    ),

    // --- Zuschneiden/Drehen: ranked Eck-Farben ---
    cropRotateEditor: CropRotateEditorConfigs(
      style: CropRotateEditorStyle(
        cropCornerColor: Colors.white,
        cropCornerLength: 32,
        cropCornerThickness: 4,
        background: _kEditorBg,
        bottomBarBackground: _kEditorBar,
        helperLineColor: Colors.white.withValues(alpha: 0.15),
      ),
      widgets: CropRotateEditorWidgets(
        appBar: (cropRotateEditor, rebuildStream) => null,
        bottomBar: (cropRotateEditor, rebuildStream) => ReactiveWidget(
          stream: rebuildStream,
          builder: (_) => GroundedCropRotateBar(
            configs: cropRotateEditor.configs,
            callbacks: cropRotateEditor.callbacks,
            editor: cropRotateEditor,
            selectedRatioColor: AppColors.primary,
          ),
        ),
      ),
    ),

    // --- Filter: ranked Slider + grounded Leiste ---
    filterEditor: FilterEditorConfigs(
      style: const FilterEditorStyle(
        filterListSpacing: 8,
        filterListMargin: EdgeInsets.fromLTRB(8, 0, 8, 8),
        background: _kEditorBg,
      ),
      widgets: FilterEditorWidgets(
        appBar: (editorState, rebuildStream) => null,
        slider: (editorState, rebuildStream, value, onChanged, onChangeEnd) =>
            ReactiveWidget(
          stream: rebuildStream,
          builder: (_) => Slider(
            value: value,
            onChanged: onChanged,
            onChangeEnd: onChangeEnd,
            activeColor: AppColors.primary,
          ),
        ),
        bottomBar: (editorState, rebuildStream) => ReactiveWidget(
          stream: rebuildStream,
          builder: (_) => GroundedFilterBar(
            configs: editorState.configs,
            callbacks: editorState.callbacks,
            editor: editorState,
          ),
        ),
      ),
    ),

    // --- Emojis ---
    emojiEditor: EmojiEditorConfigs(
      style: EmojiEditorStyle(
        backgroundColor: _kEditorBg,
        bottomActionBarConfig: const BottomActionBarConfig(enabled: false),
      ),
    ),

    // --- Loading-Dialog: gestylter grounded-Dialog statt des ungestylten
    //     Defaults (sonst erscheint der Text gelb-unterstrichen, weil ihm der
    //     Material/DefaultTextStyle-Vorfahr fehlt). ---
    dialogConfigs: DialogConfigs(
      widgets: DialogWidgets(
        loadingDialog: (message, configs) => GroundedLoadingDialog(
          message: message,
          configs: configs,
        ),
      ),
    ),
  );
}

/// Deutsche Beschriftungen passend zur restlichen App.
const I18n _rankedI18n = I18n(
  cancel: 'Abbrechen',
  undo: 'Zurück',
  redo: 'Vor',
  done: 'Fertig',
  remove: 'Entfernen',
  doneLoadingMsg: 'Wird angewendet...',
  various: I18nVarious(
    loadingDialogMsg: 'Bitte warten...',
    closeEditorWarningTitle: 'Story verwerfen?',
    closeEditorWarningMessage: 'Deine Änderungen gehen verloren.',
    closeEditorWarningConfirmBtn: 'Verwerfen',
    closeEditorWarningCancelBtn: 'Weiter bearbeiten',
  ),
  paintEditor: I18nPaintEditor(
    bottomNavigationBarText: 'Zeichnen',
    freestyle: 'Frei',
    arrow: 'Pfeil',
    line: 'Linie',
    rectangle: 'Rechteck',
    circle: 'Kreis',
    eraser: 'Radierer',
    lineWidth: 'Stärke',
    toggleFill: 'Füllen',
    changeOpacity: 'Deckkraft',
    done: 'Fertig',
    back: 'Zurück',
  ),
  textEditor: I18nTextEditor(
    inputHintText: 'Text eingeben...',
    bottomNavigationBarText: 'Text',
    textAlign: 'Ausrichtung',
    fontScale: 'Größe',
    backgroundMode: 'Modus',
    done: 'Fertig',
    back: 'Zurück',
  ),
  cropRotateEditor: I18nCropRotateEditor(
    bottomNavigationBarText: 'Zuschneiden',
    rotate: 'Drehen',
    flip: 'Spiegeln',
    ratio: 'Format',
    reset: 'Zurücksetzen',
    done: 'Fertig',
    back: 'Zurück',
  ),
  filterEditor: I18nFilterEditor(
    bottomNavigationBarText: 'Filter',
    filters: I18nFilters(none: 'Keiner'),
    done: 'Fertig',
    back: 'Zurück',
  ),
  emojiEditor: I18nEmojiEditor(
    bottomNavigationBarText: 'Emojis',
    search: 'Suchen',
  ),
);

// ---------------------------------------------------------------------------
// Ranked Color-Picker (eigenes kleines Dialog-Widget, kein Extra-Package).
// ---------------------------------------------------------------------------

const List<Color> _kRankedPalette = [
  Colors.white,
  Colors.black,
  Color(0xFFB41B00), // ranked primary (light)
  Color(0xFFFF7058), // ranked primary (dark)
  Color(0xFFEFC900), // ranked gold
  Color(0xFFFF4D6D),
  Color(0xFFFF8FAB),
  Color(0xFF7B2CBF),
  Color(0xFF3A86FF),
  Color(0xFF00B4D8),
  Color(0xFF2EC4B6),
  Color(0xFF52B788),
  Color(0xFFFFB703),
  Color(0xFFFB8500),
  Color(0xFF8D99AE),
  Color(0xFF6C757D),
];

Future<Color?> _showRankedColorPicker(BuildContext context, Color current) {
  return showModalBottomSheet<Color>(
    context: context,
    backgroundColor: _kEditorBar,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (ctx) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Text(
              'Farbe wählen',
              style: GoogleFonts.plusJakartaSans(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 18,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 14,
              runSpacing: 14,
              children: _kRankedPalette.map((color) {
                final selected = color.toARGB32() == current.toARGB32();
                return GestureDetector(
                  onTap: () => Navigator.of(ctx).pop(color),
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: selected ? AppColors.primary : Colors.white24,
                        width: selected ? 3 : 1,
                      ),
                    ),
                    child: selected
                        ? Icon(
                            Icons.check,
                            size: 20,
                            color: color.computeLuminance() > 0.5
                                ? Colors.black
                                : Colors.white,
                          )
                        : null,
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    ),
  );
}
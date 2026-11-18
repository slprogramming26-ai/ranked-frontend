import 'package:flutter/material.dart';

/// Merkt selbst, ob das Kind gerade im Bild der umgebenden Scroll-Fläche ist,
/// und baut es mit diesen zwei Werten:
///  - `onScreen`: gerade sichtbar -> Animationen dürfen laufen. Scrollt man
///    weg, geht's auf false -> sie pausieren (Akku).
///  - `revealed`: einmal reingescrollt -> bleibt true (zum Einblenden).
///
/// Hängt sich an das NÄCHSTE Scrollable über ihm (`Scrollable.maybeOf`) -
/// im Onboarding also an die SingleChildScrollView der Seite, nicht an den
/// PageView darüber.
class OnScreenBuilder extends StatefulWidget {
  const OnScreenBuilder({super.key, required this.builder});

  final Widget Function(BuildContext context, bool onScreen, bool revealed)
  builder;

  @override
  State<OnScreenBuilder> createState() => _OnScreenBuilderState();
}

class _OnScreenBuilderState extends State<OnScreenBuilder> {
  ScrollableState? _scrollable;
  bool _revealed = false;
  bool _onScreen = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final scrollable = Scrollable.maybeOf(context);
    if (scrollable != _scrollable) {
      _scrollable?.position.removeListener(_check);
      _scrollable = scrollable?..position.addListener(_check);
    }
    // Evtl. schon beim Öffnen im Bild -> einmal prüfen, sobald das Layout
    // steht.
    WidgetsBinding.instance.addPostFrameCallback((_) => _check());
  }

  @override
  void dispose() {
    _scrollable?.position.removeListener(_check);
    super.dispose();
  }

  void _check() {
    if (!mounted) return;
    final box = context.findRenderObject() as RenderBox?;
    final viewport = _scrollable?.context.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize || viewport == null || !viewport.hasSize) {
      return;
    }
    // Position RELATIV zur Scroll-Fläche (nicht zum Display) -> feste
    // Leisten drumherum zählen automatisch nicht mit.
    final top = box.localToGlobal(Offset.zero, ancestor: viewport).dy;
    final bottom = top + box.size.height;
    final height = viewport.size.height;
    // "Im Bild" = ein gutes Stück drin, nicht nur angeschnitten.
    final onScreen = top < height * 0.75 && bottom > height * 0.2;
    if (onScreen == _onScreen) return;
    setState(() {
      _onScreen = onScreen;
      if (onScreen) _revealed = true;
    });
  }

  @override
  Widget build(BuildContext context) =>
      widget.builder(context, _onScreen, _revealed);
}

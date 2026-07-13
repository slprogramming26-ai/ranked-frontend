import 'package:flutter/material.dart';
import '../../app_colors.dart';
import '../../net_image.dart';

/// Netzwerkbild fuer den Feed ohne "Aufpopp"-Effekt:
///  - Waehrend des Ladens reserviert ein 16:10-Platzhalter die Flaeche
///    (vorher war der Post erst flach und sprang auf, sobald das Bild kam).
///  - Ist das Bild da, blendet AnimatedCrossFade weich rueber und animiert
///    dabei auch den Hoehen-Unterschied zwischen Platzhalter und echtem Bild.
///  - Kommt das Bild aus dem Speicher-Cache (wasSync), erscheint es sofort
///    ohne Fade — sonst wuerde jedes Zurueckscrollen erneut blenden.
class FeedImage extends StatelessWidget {
  final String url;

  const FeedImage({super.key, required this.url});

  Widget _placeholder({Widget? child}) {
    return AspectRatio(
      aspectRatio: 16 / 10,
      child: Container(
        color: AppColors.surfaceContainerHigh,
        alignment: Alignment.center,
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Image(
      // Feed-Bild ist bildschirmbreit → logische Bildschirmbreite als
      // Dekodier-Breite.
      image: netImage(
        context,
        url,
        logicalWidth: MediaQuery.sizeOf(context).width,
      ),
      width: double.infinity,
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => _placeholder(
        child: Icon(
          Icons.broken_image_outlined,
          color: AppColors.onSurfaceVariant,
        ),
      ),
      frameBuilder: (context, child, frame, wasSyncLoaded) {
        if (wasSyncLoaded) return child;
        return AnimatedCrossFade(
          duration: const Duration(milliseconds: 350),
          sizeCurve: Curves.easeOutCubic,
          // frame == null heisst: noch kein einziges Bild-Frame decodiert.
          crossFadeState: frame == null
              ? CrossFadeState.showFirst
              : CrossFadeState.showSecond,
          firstChild: _placeholder(),
          secondChild: child,
        );
      },
    );
  }
}
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:visibility_detector/visibility_detector.dart';

import '../impression_tracker.dart';

/// Misst, wie lange ein Feed-Post wirklich sichtbar war, und meldet es dem
/// [ImpressionTracker]. Rein passiv — am Aussehen des Kindes aendert sich nichts.
class ImpressionWrapper extends StatefulWidget {
  const ImpressionWrapper({
    super.key,
    required this.postId,
    required this.position,
    required this.child,
  });

  final int postId;
  final int position;
  final Widget child;

  @override
  State<ImpressionWrapper> createState() => _ImpressionWrapperState();
}

class _ImpressionWrapperState extends State<ImpressionWrapper> {
  late ImpressionTracker _tracker;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Einmal merken: in dispose() ist context.read<>() nicht mehr erlaubt.
    _tracker = context.read<ImpressionTracker>();
  }

  @override
  void dispose() {
    // Der Post verlaesst den Baum (Wegscrollen, Refresh, Tab zu) -> Stopuhr
    // anhalten. Verlassen wir uns hier auf einen letzten 0%-Callback des
    // Detectors, laeuft die Messung im Zweifel unbegrenzt weiter.
    _tracker.onHidden(widget.postId);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.sizeOf(context).height;

    return VisibilityDetector(
      key: ValueKey('vd-${widget.postId}'),
      onVisibilityChanged: (info) {
        if (!mounted) return;
        // NICHT visibleFraction >= 0.5: ein Post mit grossem Bild ist hoeher
        // als der Screen und erreicht die 0.5 nie. Also gegen die sichtbare
        // Hoehe rechnen, gedeckelt auf die Screenhoehe.
        final cap = math.min(info.size.height, screenHeight);
        final isVisible = cap > 0 && info.visibleBounds.height >= cap * 0.5;

        if (isVisible) {
          _tracker.onVisible(widget.postId, widget.position);
        } else {
          _tracker.onHidden(widget.postId);
        }
      },
      child: widget.child,
    );
  }
}

import 'package:flutter/material.dart';

/// Auftritts-Animation fuer Feed-Elemente: faded ein und slided dabei leicht
/// von unten hoch. [delayMs] staffelt mehrere Elemente nacheinander
/// (Choreografie: Element 0 sofort, Element 1 kurz danach, ...).
///
/// [animate] = false zeigt das Kind sofort fertig an — dafuer gedacht, dass
/// jedes Element nur bei seinem ERSTEN Erscheinen animiert (der Aufrufer
/// merkt sich, was schon mal zu sehen war). Sonst wuerde z.B. Hochscrollen
/// dieselben Posts immer wieder einfliegen lassen.
class FeedEntrance extends StatefulWidget {
  final Widget child;
  final bool animate;
  final int delayMs;

  const FeedEntrance({
    super.key,
    required this.child,
    this.animate = true,
    this.delayMs = 0,
  });

  @override
  State<FeedEntrance> createState() => _FeedEntranceState();
}

class _FeedEntranceState extends State<FeedEntrance>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 380),
  );
  late final CurvedAnimation _curved = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeOutCubic,
  );

  @override
  void initState() {
    super.initState();
    if (!widget.animate) {
      // Direkt auf "fertig" springen — kein Frame Unsichtbarkeit.
      _controller.value = 1;
    } else if (widget.delayMs == 0) {
      _controller.forward();
    } else {
      Future.delayed(Duration(milliseconds: widget.delayMs), () {
        if (mounted) _controller.forward();
      });
    }
  }

  @override
  void dispose() {
    _curved.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _curved,
      child: SlideTransition(
        position: Tween(
          begin: const Offset(0, 0.06),
          end: Offset.zero,
        ).animate(_curved),
        child: widget.child,
      ),
    );
  }
}
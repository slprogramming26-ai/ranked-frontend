import 'package:flutter/material.dart';

/// Klappt ein Feed-Element weg (Hoehe -> 0 + Ausblenden), z.B. nach dem
/// Melden. Sobald [collapsed] auf true springt, laeuft die Animation, und
/// am Ende wird [onCollapsed] genau EINMAL aufgerufen. Dort entfernt der
/// Aufrufer das Element dann wirklich aus seiner Liste.
///
/// Falle: Scrollt der User waehrend der Animation weg, entsorgt
/// ListView.builder dieses Widget, und die Animation endet nie. Dann holt
/// dispose() den Callback nach, aber erst nach dem Frame, weil ein
/// Provider-Update mitten im dispose "setState during build" wirft.
class CollapseOut extends StatefulWidget {
  final bool collapsed;
  final VoidCallback onCollapsed;
  final Widget child;

  const CollapseOut({
    super.key,
    required this.collapsed,
    required this.onCollapsed,
    required this.child,
  });

  @override
  State<CollapseOut> createState() => _CollapseOutState();
}

class _CollapseOutState extends State<CollapseOut>
    with SingleTickerProviderStateMixin {
  // value 1 = voll sichtbar, 0 = weggeklappt. Wir laufen also rueckwaerts.
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 280),
    value: 1,
  );
  late final CurvedAnimation _curved = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeInOutCubic,
  );

  // Schutz gegen doppeltes Feuern (Animationsende UND dispose).
  bool _fired = false;

  @override
  void initState() {
    super.initState();
    if (widget.collapsed) _collapse();
  }

  @override
  void didUpdateWidget(CollapseOut oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.collapsed && !oldWidget.collapsed) _collapse();
  }

  Future<void> _collapse() async {
    await _controller.reverse().orCancel.catchError((_) {});
    if (mounted) _fire();
  }

  void _fire() {
    if (_fired) return;
    _fired = true;
    widget.onCollapsed();
  }

  @override
  void dispose() {
    if (widget.collapsed && !_fired) {
      final callback = widget.onCollapsed;
      _fired = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => callback());
    }
    _curved.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizeTransition(
      sizeFactor: _curved,
      alignment: Alignment.topCenter, // oben festhalten, von unten her einklappen
      child: FadeTransition(opacity: _curved, child: widget.child),
    );
  }
}

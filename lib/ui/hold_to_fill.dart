// ═══════════════════════════════════════════════════════════════════════════
// PROTOTYP (A4e, 15.11.) - "Wasserpegel": gedrückt halten -> füllt sich.
// ═══════════════════════════════════════════════════════════════════════════
//
// Erstmal NUR ZUM TESTEN (Meinungen einholen). So wird man es wieder los:
//
//   Schnell ausschalten (A/B-Test):
//     lib/profile/widgets/profile_ranking_section.dart ->
//     `_useHoldToFill = false`  => die alte Tipp-Karte (_RateCardTap) ist
//     sofort wieder da. Nichts sonst ändern.
//
//   Komplett entfernen:
//     1. Diese Datei löschen (lib/ui/hold_to_fill.dart).
//     2. In profile_ranking_section.dart:
//        - Import von '../../ui/hold_to_fill.dart' raus
//        - `_useHoldToFill` + die Klasse `_RateCardHold` raus
//        - im build() nur noch `_RateCardTap(...)` (if-else weg)
//        - in `_openRateScreen` den Parameter `fade` + `_fadeRoute` raus
//     3. l10n-Key `profileRankingHoldHint` aus app_de.arb + app_en.arb
//        löschen, `flutter gen-l10n`.
//     -> Sonst hängt NICHTS daran (kein Provider, kein Package, keine Prefs).
//
// ───────────────────────────────────────────────────────────────────────────
// Ablauf (_fill läuft 0 -> 1 in [holdDuration]):
//
//   0.0 ─────────── 0.5 ─────────────────────── 1.0
//   Wasser steigt     Wasser BRICHT AUS: breitet  voll -> onConfirmed()
//   IN der Karte      sich übers ganze Display    (Screen öffnet sich,
//   (Wellenkante)     aus und steigt nach oben    Wasser blendet danach aus)
//
//   Loslassen vorher -> _fill läuft rückwärts, das Wasser zieht sich in die
//                       Karte zurück und läuft ab.
//   Kurz tippen      -> Wasser schwappt kurz hoch und wieder runter.
//   Scrollen         -> die Scroll-Geste gewinnt, wir bekommen onTapCancel
//                       -> wie Loslassen. Kein Konflikt.
//   Screenreader     -> Doppeltipp (= Semantics-Tap) ruft onConfirmed direkt.
// ═══════════════════════════════════════════════════════════════════════════

import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Baut den Karten-Inhalt. Wird ZWEIMAL gebaut: einmal normal
/// ([onWater] = false) und einmal für den Teil unter Wasser ([onWater] =
/// true, auf dem Gradient -> z. B. weiße Schrift, transparenter Grund).
typedef HoldToFillBuilder = Widget Function(BuildContext context, bool onWater);

class HoldToFill extends StatefulWidget {
  const HoldToFill({
    super.key,
    required this.builder,
    required this.onConfirmed,
    required this.gradient,
    this.borderRadius = 16,
    this.holdDuration = const Duration(milliseconds: 1200),
  });

  final HoldToFillBuilder builder;

  /// Wasser hat den oberen Rand erreicht (oder Screenreader-Tap).
  final VoidCallback onConfirmed;

  /// Farbe des Wassers - in der Karte UND beim Ausbruch.
  final Gradient gradient;

  final double borderRadius;

  /// Wie lange man halten muss, bis es voll ist.
  final Duration holdDuration;

  @override
  State<HoldToFill> createState() => _HoldToFillState();
}

class _HoldToFillState extends State<HoldToFill> with TickerProviderStateMixin {
  /// Ab hier verlässt das Wasser die Karte.
  static const _breakAt = 0.5;

  /// Wie lange die Seite zum Reinblenden braucht (muss zur Route in der
  /// Sektion passen). Erst danach blendet das Wasser aus -> kein Aufblitzen
  /// des Profils dazwischen.
  static const _routeFade = Duration(milliseconds: 300);

  /// Füllstand 0..1 - DIE zentrale Größe, alles andere leitet sich ab.
  late final AnimationController _fill =
      AnimationController(
          vsync: this,
          duration: widget.holdDuration,
          // Ablaufen geht schneller als Füllen.
          reverseDuration: const Duration(milliseconds: 450),
        )
        ..addListener(_onFillTick)
        ..addStatusListener(_onFillStatus);

  /// Bewegt die Wellenkante (läuft endlos, solange Wasser da ist).
  late final AnimationController _wave = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );

  /// Wie lange das Ausbruch-Wasser nach dem Öffnen des Screens ausblendet.
  static const _outroDuration = Duration(milliseconds: 250);

  /// true = Ausbruch-Wasser blendet aus.
  ///
  /// WICHTIG: Das Ausblenden läuft per AnimatedOpacity IM Overlay, nicht über
  /// einen Controller hier im State. Grund: Sobald der neue Screen fertig
  /// eingeblendet ist, versteckt Flutter das Profil darunter und schaltet
  /// dort alle Ticker ab (TickerMode false). Ein Controller von hier würde
  /// einfrieren -> das Wasser bliebe für immer liegen. Das Overlay liegt
  /// ganz oben und tickt weiter.
  final _fadeOut = ValueNotifier<bool>(false);

  /// Das Wasser übers ganze Display: ein OverlayEntry, damit es auch über
  /// Header, NavBar usw. liegt - nicht nur innerhalb der Karte.
  OverlayEntry? _flood;

  /// Wo die Karte auf dem Display liegt (beim Ausbruch gemessen):
  /// Startform des Ausbruch-Wassers.
  Rect? _cardRect;

  bool _holding = false;

  /// Voll und onConfirmed gerufen -> Gesten ignorieren bis zum Reset.
  bool _confirmed = false;

  /// Für die Haptik-Ticks: in welchem Achtel waren wir zuletzt?
  int _lastTick = 0;

  @override
  void dispose() {
    _removeFlood();
    _fill.dispose();
    _wave.dispose();
    _fadeOut.dispose();
    super.dispose();
  }

  // ─── Gesten ──────────────────────────────────────────────────────────────

  void _onDown() {
    if (_confirmed) return;
    _holding = true;
    if (!_wave.isAnimating) _wave.repeat();
    _fill.forward();
  }

  void _onUp() {
    if (_confirmed) return;
    _holding = false;
    // Kaum gefüllt = es war ein Tippen -> kurz schwappen lassen, das
    // erklärt "hier passiert was, wenn du hältst".
    if (_fill.value < 0.15) {
      HapticFeedback.lightImpact();
      _fill
          .animateTo(
            0.16,
            duration: const Duration(milliseconds: 160),
            curve: Curves.easeOut,
          )
          .then((_) {
            if (mounted && !_holding && !_confirmed) _fill.reverse();
          });
    } else {
      _fill.reverse();
    }
  }

  /// Geste abgebrochen (z. B. Scrollen hat gewonnen) -> einfach ablaufen.
  void _onCancel() {
    if (_confirmed) return;
    _holding = false;
    _fill.reverse();
  }

  // ─── Füllstand beobachten ────────────────────────────────────────────────

  void _onFillTick() {
    final v = _fill.value;

    // Haptik: ein leiser Tick pro Achtel, nur beim Füllen.
    final tick = (v * 8).floor();
    if (_fill.status == AnimationStatus.forward && tick > _lastTick) {
      HapticFeedback.selectionClick();
    }
    _lastTick = tick;

    // Über die Bruchkante -> Ausbruch-Wasser einblenden, darunter wieder weg.
    if (v >= _breakAt && _flood == null) {
      _insertFlood();
    } else if (v < _breakAt && _flood != null && !_confirmed) {
      _removeFlood();
    }
  }

  void _onFillStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed && !_confirmed) {
      _confirm();
    } else if (status == AnimationStatus.dismissed) {
      _wave.stop(); // kein Wasser -> keine Welle
    }
  }

  Future<void> _confirm() async {
    _confirmed = true;
    HapticFeedback.heavyImpact();
    widget.onConfirmed();

    // Warten, bis der Screen eingeblendet ist, DANN das Wasser weg.
    // So sieht man nie das nackte Profil dazwischen.
    // (Future.delayed läuft über die Uhr, nicht über einen Ticker -> wird
    // nicht eingefroren.)
    await Future<void>.delayed(_routeFade);
    if (!mounted) return;
    _fadeOut.value = true; // -> AnimatedOpacity im Overlay -> _reset()
  }

  /// Ausblenden fertig: alles auf Anfang, damit die Karte leer ist, wenn man
  /// zurückkommt.
  void _reset() {
    if (!mounted || !_fadeOut.value) return;
    _removeFlood();
    _fadeOut.value = false;
    _fill.value = 0;
    _lastTick = 0;
    _confirmed = false;
  }

  // ─── Ausbruch-Overlay ────────────────────────────────────────────────────

  void _insertFlood() {
    final box = context.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return;
    final overlay = Overlay.of(context, rootOverlay: true);
    final overlayBox = overlay.context.findRenderObject() as RenderBox?;
    _cardRect = box.localToGlobal(Offset.zero, ancestor: overlayBox) & box.size;

    _flood = OverlayEntry(builder: (_) => _buildFlood());
    overlay.insert(_flood!);
    if (_fill.status == AnimationStatus.forward) {
      HapticFeedback.mediumImpact();
    }
  }

  void _removeFlood() {
    _flood
      ?..remove()
      ..dispose();
    _flood = null;
  }

  Widget _buildFlood() {
    return IgnorePointer(
      child: ValueListenableBuilder<bool>(
        valueListenable: _fadeOut,
        builder: (_, fading, child) => AnimatedOpacity(
          opacity: fading ? 0 : 1,
          duration: _outroDuration,
          onEnd: _reset,
          child: child,
        ),
        child: AnimatedBuilder(
          animation: Listenable.merge([_fill, _wave]),
          builder: (_, _) => CustomPaint(
            size: Size.infinite,
            painter: _FloodPainter(
              // 0.5..1 -> 0..1
              progress: ((_fill.value - _breakAt) / (1 - _breakAt)).clamp(
                0.0,
                1.0,
              ),
              phase: _wave.value,
              from: _cardRect!,
              fromRadius: widget.borderRadius,
              gradient: widget.gradient,
            ),
          ),
        ),
      ),
    );
  }

  // ─── Karte ───────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(widget.borderRadius);
    // Screenreader: Halten geht dort nicht -> Doppeltipp öffnet direkt.
    return Semantics(
      button: true,
      onTap: widget.onConfirmed,
      child: GestureDetector(
        excludeFromSemantics: true,
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => _onDown(),
        onTapUp: (_) => _onUp(),
        onTapCancel: _onCancel,
        child: ClipRRect(
          borderRadius: radius,
          child: AnimatedBuilder(
            animation: Listenable.merge([_fill, _wave]),
            builder: (context, _) {
              // 0..0.5 -> Karte 0..1 voll; danach bleibt sie voll.
              final level = (_fill.value / _breakAt).clamp(0.0, 1.0);
              return Stack(
                children: [
                  widget.builder(context, false),
                  if (level > 0)
                    Positioned.fill(
                      // Zweite Kopie nur fürs Auge, nicht vorlesen.
                      child: ExcludeSemantics(
                        child: ClipPath(
                          clipper: _WaveClipper(
                            level: level,
                            phase: _wave.value,
                            // Welle nur unterwegs, leer/voll = glatt.
                            amplitude: 5 * math.sin(math.pi * level),
                          ),
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: widget.gradient,
                            ),
                            child: widget.builder(context, true),
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Wasser IN der Karte: alles unterhalb einer Sinus-Wellenkante.
class _WaveClipper extends CustomClipper<Path> {
  _WaveClipper({
    required this.level,
    required this.phase,
    required this.amplitude,
  });

  final double level; // 0 = leer, 1 = voll
  final double phase; // 0..1, verschiebt die Welle
  final double amplitude;

  @override
  Path getClip(Size size) {
    final top = size.height * (1 - level);
    double y(double x) =>
        top +
        math.sin((x / size.width) * 2 * math.pi + phase * 2 * math.pi) *
            amplitude;

    final path = Path()
      ..moveTo(0, size.height)
      ..lineTo(0, y(0));
    for (double x = 0; x <= size.width; x += 4) {
      path.lineTo(x, y(x));
    }
    return path
      ..lineTo(size.width, y(size.width))
      ..lineTo(size.width, size.height)
      ..close();
  }

  @override
  bool shouldReclip(_WaveClipper old) =>
      old.level != level || old.phase != phase || old.amplitude != amplitude;
}

/// Wasser beim Ausbruch, übers ganze Display.
///
/// Startet EXAKT als volle Karte (progress 0 = Karten-Rechteck, gleiche
/// Ecken, gleiche Farbe) -> kein Sprung beim Übergang. Dann:
///  - Seiten + Unterkante laufen schnell zu den Display-Rändern (erstes
///    Drittel) - das Wasser "läuft aus der Karte raus".
///  - Die Oberkante steigt über die ganze Zeit bis nach oben.
class _FloodPainter extends CustomPainter {
  _FloodPainter({
    required this.progress,
    required this.phase,
    required this.from,
    required this.fromRadius,
    required this.gradient,
  });

  final double progress; // 0..1
  final double phase;
  final Rect from;
  final double fromRadius;
  final Gradient gradient;

  @override
  void paint(Canvas canvas, Size size) {
    final spread = Curves.easeOutCubic.transform(
      (progress / 0.35).clamp(0.0, 1.0),
    );
    final rise = Curves.easeInOutCubic.transform(progress);

    final rect = Rect.fromLTRB(
      lerpDouble(from.left, 0, spread)!,
      lerpDouble(from.top, 0, rise)!,
      lerpDouble(from.right, size.width, spread)!,
      lerpDouble(from.bottom, size.height, spread)!,
    );
    final radius = lerpDouble(fromRadius, 0, spread)!;

    // Welle: startet glatt (passt zur vollen Karte), wird beim Ausbreiten
    // kräftig und beruhigt sich oben wieder.
    final amplitude = 14 * (1 - rise) * math.min(1.0, progress * 6);
    double y(double x) =>
        rect.top +
        math.sin((x / size.width) * 3 * math.pi + phase * 2 * math.pi) *
            amplitude;

    final path = Path()
      ..moveTo(rect.left, rect.bottom)
      ..lineTo(rect.left, y(rect.left));
    for (double x = rect.left; x <= rect.right; x += 6) {
      path.lineTo(x, y(x));
    }
    path
      ..lineTo(rect.right, y(rect.right))
      ..lineTo(rect.right, rect.bottom)
      ..close();

    canvas.save();
    canvas.clipRRect(RRect.fromRectAndRadius(rect, Radius.circular(radius)));
    // Shader über das AKTUELLE Rechteck: am Anfang identisch mit dem
    // Karten-Gradient, dann zieht er sich mit auf.
    canvas.drawPath(path, Paint()..shader = gradient.createShader(rect));
    canvas.restore();
  }

  @override
  bool shouldRepaint(_FloodPainter old) => true; // läuft eh pro Frame
}

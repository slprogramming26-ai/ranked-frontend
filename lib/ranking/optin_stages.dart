// Mini-Animationen für die Bühnen im Ranking-Opt-in (ranking_optin.dart)
// und im Onboarding (welcome_step.dart).
//
// Jede Bühne bekommt `onScreen` vom Abschnitt: nur wenn true, läuft sie.
// Scrollt man weg, pausiert sie -> kein Dauer-Ticker im Hintergrund.
// "Bewegung reduzieren" im System -> sie bleibt stehen.

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ranked/l10n/l10n.dart';

import '../ui/app_colors.dart';

/// 0..1 innerhalb von [a]..[b], außerhalb geklemmt.
double _interval(double t, double a, double b) =>
    ((t - a) / (b - a)).clamp(0.0, 1.0);

/// 0 -> 1 -> 0 innerhalb von [a]..[b] (ein "Hüpfer"), sonst 0.
double _pulse(double t, double a, double b) =>
    math.sin(math.pi * _interval(t, a, b));

/// Ranked-Verlauf + drei "Foto-Stimmungen" für angedeutete Posts. Die drei
/// sind bewusst feste Farben statt AppColors: sie stehen für fremde Posts
/// (Bildinhalt), nicht für die App-Oberfläche -> gleich in Light und Dark.
List<Color> _photoColors(int variant) => switch (variant % 4) {
  0 => [AppColors.primary, AppColors.primaryContainer],
  1 => const [Color(0xFF8E54E9), Color(0xFF4776E6)], // Abendhimmel
  2 => const [Color(0xFFFFB347), Color(0xFFFF5E62)], // Sonnenuntergang
  _ => const [Color(0xFF43CEA2), Color(0xFF185A9D)], // Meer
};

/// Der Hintergrund jeder Bühne. Schneidet ab -> Karten fliegen "raus".
class _StagePanel extends StatelessWidget {
  const _StagePanel({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: ColoredBox(
        color: AppColors.primary.withValues(alpha: 0.06),
        child: Center(child: child),
      ),
    );
  }
}

// ─── Gemeinsame Basis: Runde für Runde ───────────────────────────────────────

/// Basis aller Bühnen: nimmt `onScreen` entgegen.
abstract class _LoopStage extends StatefulWidget {
  const _LoopStage({super.key, required this.onScreen});

  final bool onScreen;
}

/// Ein Controller, der eine Runde (0 -> 1) nach der anderen läuft -
/// aber nur, solange die Bühne sichtbar ist.
///
/// Die Unterklasse gibt nur [roundDuration] an und baut aus `_c.value`
/// ihr Bild. `_round` zählt mit, falls sie pro Runde etwas wechseln will.
abstract class _LoopStageState<T extends _LoopStage> extends State<T>
    with SingleTickerProviderStateMixin<T> {
  Duration get roundDuration;

  /// Zählt die fertigen Runden.
  int _round = 0;

  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: roundDuration,
  )..addStatusListener(_onStatus);

  void _onStatus(AnimationStatus status) {
    if (status != AnimationStatus.completed) return;
    // Runde fertig -> nächste. Kein Sprung, solange das Ende einer Runde
    // genauso aussieht wie ihr Anfang.
    setState(() => _round++);
    _c.forward(from: 0);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  @override
  void didUpdateWidget(T old) {
    super.didUpdateWidget(old);
    if (old.onScreen != widget.onScreen) _sync();
  }

  /// Laufen lassen oder anhalten - je nach Sichtbarkeit + System-Einstellung.
  void _sync() {
    final run = widget.onScreen && !MediaQuery.disableAnimationsOf(context);
    if (run && !_c.isAnimating) {
      _c.forward(); // macht da weiter, wo sie angehalten wurde
    } else if (!run) {
      _c.stop();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }
}

// ─── 01 Bewerten ─────────────────────────────────────────────────────────────

/// Ein Stapel Mini-Posts: die oberste Karte neigt sich, bekommt LIKE oder
/// NOPE und fliegt raus, der Stapel rückt nach. Abwechselnd Like/Nope.
///
/// Eine Runde (_c 0 -> 1):
///   0.00-0.30  Ruhe
///   0.30-0.50  oberste Karte neigt sich, Stempel blendet ein
///   0.50-0.80  sie fliegt raus (Like = rechts, Nope = links)
///   0.55-0.90  Stapel rückt nach, hinten kommt eine neue Karte
///   1.00       _round++ -> nächste Karte oben, Richtung wechselt
class OptinRateStage extends _LoopStage {
  const OptinRateStage({super.key, required super.onScreen});

  @override
  State<OptinRateStage> createState() => _OptinRateStageState();
}

class _OptinRateStageState extends _LoopStageState<OptinRateStage> {
  static const double _cardW = 108;
  static const double _cardH = 135; // 4:5 wie die echten Posts

  /// Wie weit jede Karte im Stapel nach oben rausschaut.
  static const double _lift = 12;

  @override
  Duration get roundDuration => const Duration(milliseconds: 1800);

  @override
  Widget build(BuildContext context) {
    return _StagePanel(
      child: SizedBox(
        width: _cardW,
        height: _cardH + 2 * _lift,
        child: AnimatedBuilder(
          animation: _c,
          builder: (context, _) {
            final t = _c.value;
            final tilt = Curves.easeOut.transform(_interval(t, 0.30, 0.50));
            final fly = Curves.easeIn.transform(_interval(t, 0.50, 0.80));
            final advance = Curves.easeOutCubic.transform(
              _interval(t, 0.55, 0.90),
            );
            final like = _round.isEven;
            final dir = like ? 1.0 : -1.0;

            return Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.bottomCenter,
              children: [
                // Von hinten nach vorne. Tiefe 0 = oben, 2 = ganz hinten.
                // Die neue Karte kommt aus Tiefe 3 (unsichtbar) dazu.
                _atDepth(3 - advance, _round + 3, fadeIn: advance),
                _atDepth(2 - advance, _round + 2),
                _atDepth(1 - advance, _round + 1),
                // Die oberste: neigen -> rausfliegen.
                Transform.translate(
                  offset: Offset(dir * (6 * tilt + 200 * fly), -16 * fly),
                  child: Transform.rotate(
                    angle: dir * (0.06 * tilt + 0.3 * fly),
                    child: Opacity(
                      opacity: 1 - fly,
                      child: _MiniPost(
                        width: _cardW,
                        height: _cardH,
                        variant: _round,
                        stampLike: like,
                        stamp: tilt,
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  /// Karte an Tiefe [depth] (darf krumm sein, das ist das Nachrücken):
  /// weiter hinten = kleiner, höher, blasser.
  ///
  /// Skaliert wird zur OBERKANTE hin: so schaut jede Karte genau [_lift]
  /// pro Stufe oben raus, und der ganze Stapel ist exakt
  /// `_cardH + 2 * _lift` hoch = die SizedBox -> optisch mittig.
  /// (Zur Unterkante hin hätte das Verkleinern den Versatz fast
  /// aufgefressen -> Stapel unsichtbar, Karte saß zu tief.)
  Widget _atDepth(double depth, int variant, {double fadeIn = 1}) {
    return Transform.translate(
      offset: Offset(0, -_lift * depth),
      child: Transform.scale(
        scale: 1 - 0.08 * depth,
        alignment: Alignment.topCenter,
        child: Opacity(
          opacity: ((1 - 0.25 * depth) * fadeIn).clamp(0.0, 1.0),
          child: _MiniPost(width: _cardW, height: _cardH, variant: variant),
        ),
      ),
    );
  }
}

// ─── 02 Bewertet werden ──────────────────────────────────────────────────────

/// Dein eigener Post (mit Kategorie-Chip): drei LIKE-Stempel knallen
/// nacheinander drauf, fliegen in die Punkte-Pille, die zählt hoch.
///
/// Eine Runde (_c 0 -> 1), pro Like i mit Start s = _starts[i]:
///   s       .. s+0.05  Stempel knallt auf die Karte (groß -> normal),
///                      die Karte zuckt kurz
///   s+0.12  .. s+0.20  Stempel fliegt in die Pille und schrumpft
///   s+0.20  .. s+0.26  Zahl zählt +4 hoch, Pille hüpft
///   0.90    .. 1.00    Zahl blendet aus -> nächste Runde startet bei +0
class OptinRatedStage extends _LoopStage {
  const OptinRatedStage({super.key, required super.onScreen});

  @override
  State<OptinRatedStage> createState() => _OptinRatedStageState();
}

class _OptinRatedStageState extends _LoopStageState<OptinRatedStage> {
  static const double _cardW = 100;
  static const double _cardH = 125;

  /// Linke obere Ecke der Karte innerhalb der Bühne.
  static const Offset _cardOrigin = Offset(16, 26);

  /// Ziel der Stempel: ungefähr die Mitte der Pille.
  static const Offset _pillCenter = Offset(188, 88);

  /// Nur Demo: 3 Likes ergeben eine schöne runde "+12".
  static const int _pointsPerLike = 4;

  /// Wann die drei Likes starten.
  static const _starts = [0.10, 0.32, 0.54];

  /// Wo die Stempel auf der Karte landen (Mitte, relativ zur Karte)
  /// und wie schief.
  static const _spots = [
    (Offset(36, 50), -0.25),
    (Offset(66, 74), 0.18),
    (Offset(40, 96), -0.10),
  ];

  /// Ab hier ist der Stempel in der Pille angekommen.
  static double _arrival(int i) => _starts[i] + 0.20;

  @override
  Duration get roundDuration => const Duration(milliseconds: 3200);

  @override
  Widget build(BuildContext context) {
    return _StagePanel(
      child: SizedBox(
        width: 250,
        height: 170,
        child: AnimatedBuilder(
          animation: _c,
          builder: (context, _) {
            final t = _c.value;

            var nudge = 0.0; // Karte zuckt beim Stempeln
            var bump = 0.0; // Pille hüpft beim Ankommen
            var points = 0.0;
            for (var i = 0; i < _starts.length; i++) {
              nudge += _pulse(t, _starts[i], _starts[i] + 0.08);
              bump += _pulse(t, _arrival(i), _arrival(i) + 0.08);
              points +=
                  _pointsPerLike *
                  Curves.easeOut.transform(
                    _interval(t, _arrival(i), _arrival(i) + 0.06),
                  );
            }

            // Zahl: am Rundenanfang ein-, am Ende ausblenden. Bei t = 0 und
            // t = 1 ist sie unsichtbar -> der Sprung von +12 auf +0 fällt
            // nicht auf.
            final numberOpacity = t < 0.5
                ? _interval(t, 0.0, 0.06)
                : 1 - _interval(t, 0.90, 1.0);

            return Stack(
              clipBehavior: Clip.none,
              children: [
                // Dein Post
                Positioned(
                  left: _cardOrigin.dx,
                  top: _cardOrigin.dy,
                  child: Transform.scale(
                    scale: 1 - 0.04 * nudge,
                    child: const _MiniPost(
                      width: _cardW,
                      height: _cardH,
                      variant: 0,
                    ),
                  ),
                ),
                // Kategorie-Chip auf der Oberkante der Karte
                Positioned(
                  left: _cardOrigin.dx - 20,
                  width: _cardW + 40,
                  top: _cardOrigin.dy - 13,
                  child: const Center(child: _CategoryChip()),
                ),
                // Punkte-Pille
                Positioned(
                  left: 140,
                  right: 0,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: Transform.scale(
                      scale: 1 + 0.12 * bump,
                      child: _PointsPill(
                        points: points.round(),
                        numberOpacity: numberOpacity,
                      ),
                    ),
                  ),
                ),
                // Stempel obendrauf
                for (var i = 0; i < _starts.length; i++) _flyingStamp(t, i),
              ],
            );
          },
        ),
      ),
    );
  }

  /// Like-Stempel Nr. [i]: knallt auf die Karte, fliegt in die Pille.
  Widget _flyingStamp(double t, int i) {
    final s = _starts[i];
    final pop = _interval(t, s, s + 0.05);
    final fly = Curves.easeInCubic.transform(_interval(t, s + 0.12, s + 0.20));
    if (pop == 0 || fly == 1) return const SizedBox.shrink();

    final (spot, angle) = _spots[i];
    final pos = Offset.lerp(_cardOrigin + spot, _pillCenter, fly)!;
    // easeOutBack schießt leicht über 1 -> 2 - 1.1 = 0.9: der Stempel
    // "federt" beim Aufkommen kurz nach.
    final scale = (2.0 - Curves.easeOutBack.transform(pop)) * (1 - 0.6 * fly);

    return Positioned(
      left: pos.dx,
      top: pos.dy,
      child: FractionalTranslation(
        translation: const Offset(-0.5, -0.5), // pos = Mitte des Stempels
        child: Transform.rotate(
          angle: angle * (1 - fly),
          child: Transform.scale(
            scale: scale,
            child: Opacity(
              opacity: (pop * (1 - fly)).clamp(0.0, 1.0),
              child: const _Stamp(like: true, fontSize: 11),
            ),
          ),
        ),
      ),
    );
  }
}

/// "🎨 Kreativität" - gleicher Name + Icon wie die Kategorie in Create-Post.
class _CategoryChip extends StatelessWidget {
  const _CategoryChip();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.10),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.palette_outlined, size: 13, color: AppColors.primary),
          const SizedBox(width: 4),
          Text(
            context.l10n.createPostCategoryCreativity,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

/// Ranked-Verlauf mit Stern + "+N". Die Zahl kann ausgeblendet werden.
class _PointsPill extends StatelessWidget {
  const _PointsPill({required this.points, required this.numberOpacity});

  final int points;
  final double numberOpacity;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 16, 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primaryContainer],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.30),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star_rounded, size: 20, color: Colors.white),
          const SizedBox(width: 4),
          Opacity(
            opacity: numberOpacity,
            child: Text(
              '+$points',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                // Ziffern gleich breit -> Pille wackelt beim Zählen nicht.
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── 03 Aufsteigen ───────────────────────────────────────────────────────────

/// Mini-Leaderboard: deine Zeile startet auf Platz 4, deine Punkte steigen,
/// du überholst eine Zeile nach der anderen. Oben wird aus "DU" der Pokal.
/// Darunter füllt sich der XP-Balken.
///
/// Eine Runde (_c 0 -> 1), pro Überholen k mit Start s = _starts[k]:
///   s-0.04 .. s+0.04   deine Punkte steigen über die der nächsten Zeile
///   s      .. s+0.14   du rutschst eine Zeile hoch, die andere runter
///   0.12   .. 0.74     XP-Balken füllt sich
///   0.72   .. 0.80     "DU" -> Pokal
///   0.90   .. 0.98     alles blendet aus -> nächste Runde von vorn
class OptinClimbStage extends _LoopStage {
  const OptinClimbStage({super.key, required super.onScreen});

  @override
  State<OptinClimbStage> createState() => _OptinClimbStageState();
}

class _OptinClimbStageState extends _LoopStageState<OptinClimbStage> {
  static const double _rowH = 28;

  /// Zeilenhöhe + Abstand: Platz n liegt bei n * _rowStep.
  static const double _rowStep = 34;

  /// Wann du die Zeilen auf Platz 3, 2 und 1 überholst.
  static const _starts = [0.16, 0.36, 0.56];
  static const double _stepLen = 0.14;

  /// Punkte der anderen, von oben nach unten (Platz 1-3 am Anfang).
  static const _otherPoints = [21, 17, 12];

  /// Deine Punkte: Start, dann nach jedem Überholen.
  static const _myPoints = [8, 14, 19, 24];

  @override
  Duration get roundDuration => const Duration(milliseconds: 4000);

  @override
  Widget build(BuildContext context) {
    return _StagePanel(
      child: SizedBox(
        width: 230,
        height: 4 * _rowStep + 16,
        child: AnimatedBuilder(
          animation: _c,
          builder: (context, _) {
            final t = _c.value;

            // Fortschritt jedes Überhol-Schritts, 0..1.
            final steps = [
              for (final s in _starts)
                Curves.easeInOutCubic.transform(_interval(t, s, s + _stepLen)),
            ];

            // Deine Position: 3 (unten) minus alle Schritte bisher.
            final myPos = 3 - steps.fold(0.0, (a, b) => a + b);

            var myPoints = _myPoints[0].toDouble();
            var lift = 0.0; // Zeile hebt sich beim Überholen leicht an
            for (var k = 0; k < _starts.length; k++) {
              final s = _starts[k];
              myPoints +=
                  (_myPoints[k + 1] - _myPoints[k]) *
                  Curves.easeOut.transform(_interval(t, s - 0.04, s + 0.04));
              lift += _pulse(t, s, s + _stepLen);
            }

            final crown = _interval(t, 0.72, 0.80);
            final xp =
                0.15 +
                0.7 * Curves.easeOutCubic.transform(_interval(t, 0.12, 0.74));
            // Bei t = 0 und t = 1 unsichtbar -> der Sprung zurück fällt
            // nicht auf (wie die Zahl in Bühne 02).
            final fade = t < 0.5
                ? _interval(t, 0.0, 0.06)
                : 1 - _interval(t, 0.90, 0.98);

            return Opacity(
              opacity: fade,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // Platz-Nummern: fest, die Zeilen wandern daran vorbei.
                  for (var i = 0; i < 4; i++)
                    Positioned(
                      left: 0,
                      width: 16,
                      top: i * _rowStep,
                      height: _rowH,
                      child: Center(
                        child: Text(
                          '${i + 1}',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: i == 0
                                ? AppColors.primary
                                : AppColors.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ),
                  // Die anderen. Zeile j wird beim Schritt 2 - j überholt
                  // und rutscht dabei einen Platz runter.
                  for (var j = 0; j < 3; j++)
                    _row(
                      pos: j + steps[2 - j],
                      child: _BoardRow(variant: j + 1, points: _otherPoints[j]),
                    ),
                  // Du - zuletzt gezeichnet, also obendrauf.
                  _row(
                    pos: myPos.toDouble(),
                    child: Transform.scale(
                      scale: 1 + 0.04 * lift,
                      child: _BoardRow(
                        variant: 0,
                        points: myPoints.round(),
                        me: true,
                        crown: crown,
                      ),
                    ),
                  ),
                  // XP-Balken
                  Positioned(
                    left: 0,
                    right: 0,
                    top: 4 * _rowStep + 4,
                    child: _XpBar(fill: xp),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  /// Eine Zeile an Position [pos] (0 = Platz 1, darf krumm sein).
  Widget _row({required double pos, required Widget child}) => Positioned(
    left: 22,
    right: 0,
    top: pos * _rowStep,
    height: _rowH,
    child: child,
  );
}

/// Eine Leaderboard-Zeile: Avatar, Namensbalken, Punkte.
/// [me] = deine Zeile im Ranked-Verlauf mit "DU" bzw. Pokal.
class _BoardRow extends StatelessWidget {
  const _BoardRow({
    required this.variant,
    required this.points,
    this.me = false,
    this.crown = 0,
  });

  final int variant;
  final int points;
  final bool me;

  /// 0 = "DU", 1 = Pokal (nur bei [me]).
  final double crown;

  /// Avatar-Farben der anderen = die "Foto-Stimmungen" aus _MiniPost.
  static const _avatarColors = [
    Color(0xFF8E54E9),
    Color(0xFFFFB347),
    Color(0xFF43CEA2),
  ];

  @override
  Widget build(BuildContext context) {
    final textColor = me ? Colors.white : AppColors.onSurfaceVariant;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: me ? null : AppColors.surface,
        gradient: me
            ? LinearGradient(
                colors: [AppColors.primary, AppColors.primaryContainer],
              )
            : null,
        boxShadow: [
          BoxShadow(
            color: (me ? AppColors.primary : Colors.black).withValues(
              alpha: me ? 0.30 : 0.05,
            ),
            blurRadius: me ? 10 : 4,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: me
                  ? Colors.white.withValues(alpha: 0.25)
                  : _avatarColors[(variant - 1) % _avatarColors.length],
            ),
            child: me ? _meBadge(context) : null,
          ),
          const SizedBox(width: 8),
          Container(
            width: me ? 34.0 : 30.0 + 8 * (variant % 3),
            height: 6,
            decoration: BoxDecoration(
              color: me
                  ? Colors.white.withValues(alpha: 0.7)
                  : AppColors.onSurface.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const Spacer(),
          Text(
            '$points',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: textColor,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }

  /// "DU" blendet aus, der Pokal ploppt rein.
  Widget _meBadge(BuildContext context) {
    final pop = Curves.easeOutBack.transform(crown);
    return Stack(
      alignment: Alignment.center,
      children: [
        Opacity(
          opacity: 1 - crown,
          child: Text(
            context.l10n.rankingYourBadge,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 7,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
        ),
        if (crown > 0)
          Transform.scale(
            scale: 0.4 + 0.6 * pop,
            child: Opacity(
              opacity: crown,
              child: const Icon(
                Icons.workspace_premium_rounded,
                size: 13,
                color: Colors.white,
              ),
            ),
          ),
      ],
    );
  }
}

/// "XP" + Balken im Ranked-Verlauf, [fill] 0..1.
class _XpBar extends StatelessWidget {
  const _XpBar({required this.fill});

  final double fill;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 22,
          child: Text(
            'XP',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              color: AppColors.primary,
            ),
          ),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: SizedBox(
              height: 8,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: ColoredBox(
                      color: AppColors.primary.withValues(alpha: 0.12),
                    ),
                  ),
                  FractionallySizedBox(
                    widthFactor: fill,
                    heightFactor: 1,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.primary,
                            AppColors.primaryContainer,
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── 00 Social Media (Onboarding) ────────────────────────────────────────────

/// Ein Mini-Feed: oben eine feste Story-Reihe, darunter Post-Karten, die
/// Karte für Karte nach oben scrollen. Auf der obersten Karte springt die
/// ⚡-Hype-Pille an (wie im echten Feed: rot gefüllt + Zahl +1).
///
/// Bewusst KEIN ♥ (gehört dem Voting) und keine Stempel (gehören dem
/// Ranking) -> diese Bühne steht nur für "ganz normale Social-Media-App".
///
/// Eine Runde (_c 0 -> 1):
///   0.12-0.30  Hype auf der obersten Karte (Füllung + Hüpfer)
///   0.30-0.55  Ruhe
///   0.55-0.92  Feed scrollt um genau eine Karte nach oben
///   1.00       _round++ -> Karten rücken im Index nach, Offset wieder 0.
///              Sieht exakt aus wie das Rundenende -> kein Sprung.
class OptinFeedStage extends _LoopStage {
  const OptinFeedStage({super.key, required super.onScreen});

  @override
  State<OptinFeedStage> createState() => _OptinFeedStageState();
}

class _OptinFeedStageState extends _LoopStageState<OptinFeedStage> {
  @override
  Duration get roundDuration => const Duration(milliseconds: 2600);

  static const _cardWidth = 210.0;
  static const _cardHeight = 122.0;
  static const _gap = 10.0;
  static const _extent = _cardHeight + _gap; // Scrollweg pro Runde

  // Hype-Zahlen pro "Post" (variant), damit die Karten verschieden wirken.
  static const _hypes = [24, 57, 13, 38];

  @override
  Widget build(BuildContext context) {
    return _StagePanel(
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) {
          final t = _c.value;
          final scroll =
              Curves.easeInOutCubic.transform(_interval(t, 0.55, 0.92));
          final hype = _interval(t, 0.12, 0.22);
          final pop = _pulse(t, 0.12, 0.30);

          return SizedBox(
            width: _cardWidth,
            child: Column(
              children: [
                const SizedBox(height: 14),
                const _StoryRow(),
                const SizedBox(height: 10),
                // Viewport: was nach oben rausscrollt, wird abgeschnitten.
                Expanded(
                  child: ClipRect(
                    child: OverflowBox(
                      alignment: Alignment.topCenter,
                      maxHeight: double.infinity,
                      child: Transform.translate(
                        offset: Offset(0, -scroll * _extent),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            for (var i = 0; i < 3; i++) ...[
                              _MiniFeedCard(
                                width: _cardWidth,
                                height: _cardHeight,
                                variant: _round + i,
                                hypeCount: _hypes[(_round + i) % 4],
                                // Nur die oberste Karte wird gehypt.
                                hype: i == 0 ? hype : 0,
                                pop: i == 0 ? pop : 0,
                              ),
                              const SizedBox(height: _gap),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Feste Story-Reihe: abgerundete Kacheln wie die echten Story-Avatare.
/// Die ersten drei mit Verlaufsring (neue Story), die übrigen grau (gesehen).
class _StoryRow extends StatelessWidget {
  const _StoryRow();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        for (var i = 0; i < 5; i++)
          Container(
            width: 34,
            height: 34,
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(11),
              gradient: i < 3
                  ? LinearGradient(
                      colors: [AppColors.primary, AppColors.primaryContainer],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : null,
              color: i < 3 ? null : AppColors.outlineVariant,
            ),
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(9),
              ),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(7),
                  gradient: LinearGradient(
                    colors: _photoColors(i + 1),
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Eine Post-Karte wie im echten Feed, nur klein: Kopfzeile (Avatar + Name),
/// "Foto", Aktionsleiste (⚡ Hype-Pille, Kommentar, Teilen).
class _MiniFeedCard extends StatelessWidget {
  const _MiniFeedCard({
    required this.width,
    required this.height,
    required this.variant,
    required this.hypeCount,
    required this.hype,
    required this.pop,
  });

  final double width;
  final double height;
  final int variant;
  final int hypeCount;

  /// 0 = neutral, 1 = gehypt (rot gefüllt, Zahl +1).
  final double hype;

  /// Hüpfer der Pille, 0..1..0.
  final double pop;

  @override
  Widget build(BuildContext context) {
    final muted = AppColors.onSurfaceVariant;
    final liked = hype >= 0.5;
    final pillFg = Color.lerp(muted, Colors.white, hype)!;

    return Container(
      width: width,
      height: height,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Kopfzeile
          Row(
            children: [
              Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(colors: _photoColors(variant + 2)),
                ),
              ),
              const SizedBox(width: 6),
              Container(
                width: 46,
                height: 6,
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          // "Foto"
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                gradient: LinearGradient(
                  colors: _photoColors(variant),
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Icon(
                _MiniPost._icons[variant % _MiniPost._icons.length],
                size: 26,
                color: Colors.white.withValues(alpha: 0.35),
              ),
            ),
          ),
          const SizedBox(height: 6),
          // Aktionsleiste: ⚡-Pille wie _buildHypeButton im echten Feed.
          Row(
            children: [
              Transform.scale(
                scale: 1 + 0.25 * pop,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: hype),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Color.lerp(
                        AppColors.outlineVariant,
                        AppColors.primary,
                        hype,
                      )!,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.bolt, size: 11, color: pillFg),
                      const SizedBox(width: 2),
                      Text(
                        '${hypeCount + (liked ? 1 : 0)}',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: pillFg,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.chat_bubble_outline, size: 12, color: muted),
              const Spacer(),
              Icon(Icons.share_outlined, size: 12, color: muted),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Voting ──────────────────────────────────────────────────────────────────

/// Deine Follower voten deinen Post: links drei Follower, rechts dein Post
/// mit "7 Tage"-Chip und ♥-Zähler. Nacheinander HÄLT jeder Follower seine
/// Pille (Wasser steigt wie beim echten Voting, siehe lib/ui/hold_to_fill.dart),
/// ist sie voll, fliegt ein ♥ im Bogen zum Post und der Zähler hüpft.
///
/// Zeichen bewusst getrennt: ♥ + Wasser = Voting. Keine Stempel/Punkte.
///
/// Eine Runde (_c 0 -> 1), Follower i hat sein Zeitfenster ab s = 0.08 + i*0.26:
///   s .. s+0.13   Halten: Wasser steigt in seiner Pille (Finger sichtbar)
///   s+0.13..+0.23 ♥ fliegt zum Post
///   s+0.23        Ankunft: Zähler +1, Pille hüpft
///   0.00-0.05     Einblenden, 0.92-1.00 Ausblenden -> nahtlose Schleife
class OptinVotingStage extends _LoopStage {
  const OptinVotingStage({super.key, required super.onScreen});

  @override
  State<OptinVotingStage> createState() => _OptinVotingStageState();
}

class _OptinVotingStageState extends _LoopStageState<OptinVotingStage> {
  @override
  Duration get roundDuration => const Duration(milliseconds: 4400);

  // Feste Bühnengröße -> Flugbahn in festen Koordinaten.
  static const _w = 250.0;
  static const _h = 170.0;
  static const _rowTop = 14.0; // y der ersten Follower-Zeile
  static const _rowStep = 52.0; // Abstand der Zeilen
  static const _pillLeft = 38.0; // x der Halte-Pille
  static const _pillW = 40.0;
  static const _pillH = 28.0;
  static const _postW = 124.0;
  static const _likesBase = 9;

  static double _slot(int i) => 0.08 + i * 0.26;

  /// Mittelpunkt der ♥-Pille unten rechts im Post (Ziel der Flugbahn).
  static const _target = Offset(_w - 10 - 24, _h - 10 - 12);

  @override
  Widget build(BuildContext context) {
    return _StagePanel(
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) {
          final t = _c.value;
          final fade = math.min(
            _interval(t, 0.0, 0.05),
            1 - _interval(t, 0.92, 1.0),
          );

          // Wie viele ♥ sind schon angekommen? -> Zählerstand.
          var arrived = 0;
          var hop = 0.0;
          for (var i = 0; i < 3; i++) {
            final s = _slot(i);
            if (t >= s + 0.23) arrived++;
            hop = math.max(hop, _pulse(t, s + 0.23, s + 0.31));
          }

          return Opacity(
            opacity: fade,
            child: SizedBox(
              width: _w,
              height: _h,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // ── Dein Post ────────────────────────────────────────
                  Positioned(
                    right: 0,
                    top: 0,
                    child: _MiniPost(width: _postW, height: _h, variant: 0),
                  ),
                  const Positioned(right: 8, top: 8, child: _DaysChip()),
                  Positioned(
                    right: 10,
                    bottom: 10,
                    child: Transform.scale(
                      scale: 1 + 0.3 * hop,
                      child: _HeartCount(count: _likesBase + arrived),
                    ),
                  ),

                  // ── Follower + Halte-Pillen ──────────────────────────
                  for (var i = 0; i < 3; i++) ..._follower(i, t),

                  // ── Fliegende Herzen (oben drauf) ────────────────────
                  for (var i = 0; i < 3; i++) _flyingHeart(i, t),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  List<Widget> _follower(int i, double t) {
    final s = _slot(i);
    final y = _rowTop + i * _rowStep;
    final level = Curves.easeInOut.transform(_interval(t, s, s + 0.13));
    // Finger nur während des Haltens sichtbar.
    final holding = t >= s && t < s + 0.15;

    return [
      Positioned(
        left: 0,
        top: y,
        child: Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.surface, width: 2),
            gradient: LinearGradient(
              colors: _photoColors(i + 1),
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      Positioned(
        left: _pillLeft,
        top: y,
        child: _HoldPill(
          width: _pillW,
          height: _pillH,
          level: level,
          // Welle wandert, solange das Wasser steigt.
          phase: t * 8,
        ),
      ),
      if (holding)
        Positioned(
          left: _pillLeft + _pillW - 12,
          top: y + _pillH - 10,
          child: Icon(
            Icons.touch_app_rounded,
            size: 20,
            color: AppColors.onSurface.withValues(alpha: 0.75),
          ),
        ),
    ];
  }

  Widget _flyingHeart(int i, double t) {
    final s = _slot(i);
    final p = _interval(t, s + 0.13, s + 0.23);
    if (p <= 0 || p >= 1) return const SizedBox.shrink();

    final from = Offset(
      _pillLeft + _pillW / 2,
      _rowTop + i * _rowStep + _pillH / 2,
    );
    final e = Curves.easeInOut.transform(p);
    // Gerade Linie + Bogen nach oben (sin) -> wirkt "geworfen".
    final pos = Offset.lerp(from, _target, e)! -
        Offset(0, math.sin(math.pi * e) * 34);
    final size = 14 + 6 * math.sin(math.pi * e);

    return Positioned(
      left: pos.dx - size / 2,
      top: pos.dy - size / 2,
      child: Icon(Icons.favorite_rounded, size: size, color: AppColors.primary),
    );
  }
}

/// Die kleine Halte-Pille: leer = Umriss-♥ auf grauem Grund, beim Halten
/// steigt Wasser (Ranked-Verlauf, Wellenkante) und das ♥ wird weiß.
/// Gleiches Prinzip wie HoldToFill: Inhalt einmal normal, einmal "unter
/// Wasser" gebaut und per Clip übereinandergelegt.
class _HoldPill extends StatelessWidget {
  const _HoldPill({
    required this.width,
    required this.height,
    required this.level,
    required this.phase,
  });

  final double width;
  final double height;
  final double level; // 0 = leer, 1 = voll
  final double phase;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(height / 2);

    return ClipRRect(
      borderRadius: radius,
      child: SizedBox(
        width: width,
        height: height,
        child: Stack(
          fit: StackFit.expand,
          children: [
            ColoredBox(
              color: AppColors.surfaceContainerHigh,
              child: Icon(
                Icons.favorite_border_rounded,
                size: 15,
                color: AppColors.onSurfaceVariant,
              ),
            ),
            if (level > 0)
              ClipPath(
                clipper: _MiniWaveClipper(
                  level: level,
                  phase: phase,
                  // Welle nur unterwegs, leer/voll = glatte Kante.
                  amplitude: 2.5 * math.sin(math.pi * level),
                ),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.primary, AppColors.primaryContainer],
                      begin: Alignment.bottomLeft,
                      end: Alignment.topRight,
                    ),
                  ),
                  child: const Icon(
                    Icons.favorite_rounded,
                    size: 15,
                    color: Colors.white,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Wasser bis [level] mit Sinus-Kante (wie _WaveClipper in hold_to_fill.dart).
class _MiniWaveClipper extends CustomClipper<Path> {
  _MiniWaveClipper({
    required this.level,
    required this.phase,
    required this.amplitude,
  });

  final double level;
  final double phase;
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
    for (double x = 0; x <= size.width; x += 2) {
      path.lineTo(x, y(x));
    }
    return path
      ..lineTo(size.width, y(size.width))
      ..lineTo(size.width, size.height)
      ..close();
  }

  @override
  bool shouldReclip(_MiniWaveClipper old) =>
      old.level != level || old.phase != phase || old.amplitude != amplitude;
}

/// "⏱ 7 TAGE" oben auf dem Post: so lange läuft das Voting.
class _DaysChip extends StatelessWidget {
  const _DaysChip();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.timer_outlined, size: 11, color: AppColors.primary),
          const SizedBox(width: 3),
          Text(
            context.l10n.votingStageDays,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 9,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}

/// "♥ 12" unten rechts auf dem Post.
class _HeartCount extends StatelessWidget {
  const _HeartCount({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.favorite_rounded, size: 13, color: AppColors.primary),
          const SizedBox(width: 3),
          Text(
            '$count',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: AppColors.primary,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Bausteine ───────────────────────────────────────────────────────────────

/// Ein angedeuteter Post: Farbverlauf als "Bild", Motiv-Icon, unten Avatar
/// + Namensbalken. Optional der LIKE/NOPE-Stempel wie im echten Ranking.
class _MiniPost extends StatelessWidget {
  const _MiniPost({
    required this.width,
    required this.height,
    required this.variant,
    this.stampLike = true,
    this.stamp = 0,
  });

  final double width;
  final double height;
  final int variant;
  final bool stampLike;

  /// 0 = kein Stempel, 1 = voll sichtbar.
  final double stamp;

  static const _icons = [
    Icons.landscape_rounded,
    Icons.brush_rounded,
    Icons.fitness_center_rounded,
    Icons.menu_book_rounded,
  ];

  List<Color> get _colors => _photoColors(variant);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: LinearGradient(
          colors: _colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Stack(
        children: [
          Center(
            child: Icon(
              _icons[variant % _icons.length],
              size: 40,
              color: Colors.white.withValues(alpha: 0.35),
            ),
          ),
          // Avatar + Name
          Positioned(
            left: 10,
            right: 10,
            bottom: 10,
            child: Row(
              children: [
                Container(
                  width: 16,
                  height: 16,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  width: 40,
                  height: 6,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ],
            ),
          ),
          // Stempel: Like links oben, Nope rechts oben - wie im Ranking.
          if (stamp > 0)
            Positioned(
              top: 12,
              left: stampLike ? 8 : null,
              right: stampLike ? null : 8,
              child: Opacity(
                opacity: stamp,
                child: Transform.rotate(
                  angle: stampLike ? -0.3 : 0.3,
                  child: _Stamp(like: stampLike),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Der LIKE/NOPE-Stempel wie im echten Ranking (ranking_pages.dart).
class _Stamp extends StatelessWidget {
  const _Stamp({required this.like, this.fontSize = 13});

  final bool like;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final color = like ? AppColors.primary : AppColors.secondary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      // Weißer Grund: auf den bunten Karten sonst unlesbar.
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: color, width: 2),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        like ? context.l10n.rankingSwipeLike : context.l10n.rankingSwipeNope,
        style: GoogleFonts.plusJakartaSans(
          fontSize: fontSize,
          fontWeight: FontWeight.w900,
          color: color,
        ),
      ),
    );
  }
}

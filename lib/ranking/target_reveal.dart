import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ranked/l10n/l10n.dart';

import '../ui/app_colors.dart';
import '../ui/net_image.dart';
import '../post/widgets/feed_skeleton.dart' show SkeletonPulse;

/// Tagesranking: verdeckte Target-Karte, die man per TAP aufdeckt
/// (nicht halten — Halten gehoert dem Voting/Wasserpegel).
///
/// Wird schon waehrend des Ladens gezeigt (ready=false): Lichtstreifen laeuft,
/// Tippen geht noch nicht. Sobald ready, blendet der Hinweis ein und die
/// Karte "atmet" leicht.
///
/// Tap -> Wackeln -> 3D-Flip -> Vorderseite (Profilbild unscharf->scharf,
/// Texte) -> kurz stehen lassen -> onDone.
class TargetRevealCard extends StatefulWidget {
  final bool ready;

  /// Feuert EINMAL, sobald die Vorderseite sichtbar wird (Flip-Mitte bzw.
  /// beim Ueberspringen). Ab hier gilt das Target als aufgedeckt -> speichern.
  final VoidCallback onRevealed;

  /// Feuert am Ende der Enthuellung -> Wechsel zum Stapel.
  final VoidCallback onDone;

  /// Erst bei ready gesetzt (TargetFound). Vorher null bzw. 0.
  final Map<String, dynamic>? targetUser;
  final int postCount;

  const TargetRevealCard({
    super.key,
    required this.ready,
    required this.onRevealed,
    required this.onDone,
    this.targetUser,
    this.postCount = 0,
  });

  @override
  State<TargetRevealCard> createState() => _TargetRevealState();
}

// Zeitleiste der Enthuellung in MILLISEKUNDEN. _at() rechnet in den
// Controller-Wert 0..1 um -> Lesezeit aendern verschiebt nichts anderes.
//      0-312   Wackeln + leicht anheben
//    312-1040  Flip (ab der Haelfte sieht man die Vorderseite)
//    884-1664  Profilbild wird scharf, Texte gleiten nacheinander rein
//   1820       alles sichtbar -> Lesezeit
//   3600-3950  Abgang: Karte tritt zurueck + blendet aus -> Stapel kommt
const _kTotalMs = 3950;
double _at(int ms) => ms / _kTotalMs;

final _kWobbleEnd = _at(312);
final _kFlipEnd = _at(1040);
// Flip-Mitte (312 + 728/2): ab hier zeigt die Karte das Profil.
final _kFrontVisible = _at(676);
final _kSettled = _at(1820);
final _kOutro = _at(3600);

class _TargetRevealState extends State<TargetRevealCard>
    with TickerProviderStateMixin {
  // Idle-Schleife fuer Lichtstreifen + Atmen. Eine Runde = 2,4 s.
  late final AnimationController _idle = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
  );

  // Die eigentliche Enthuellung, laeuft genau einmal 0 -> 1.
  late final AnimationController _reveal = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: _kTotalMs),
  )
    ..addListener(_onRevealTick)
    ..addStatusListener(_onRevealStatus);

  bool _reduceMotion = false;

  // Schutz: "Vorderseite sichtbar" (Haptik + onRevealed) nur EINMAL.
  bool _frontShown = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduceMotion = MediaQuery.disableAnimationsOf(context);
    // "Bewegung reduzieren" -> keine Dauerschleife, Karte steht still.
    if (_reduceMotion) {
      _idle.stop();
    } else if (!_idle.isAnimating && !_reveal.isAnimating) {
      _idle.repeat();
    }
  }

  @override
  void dispose() {
    _idle.dispose();
    _reveal.dispose();
    super.dispose();
  }

  // Status statt `await forward()`: wird der Controller per value= ans Ende
  // gesetzt (Tap zum Ueberspringen), kommt das Future von forward() NIE an.
  // completed feuert aber in beiden Faellen.
  void _onRevealStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed) widget.onDone();
  }

  // Laeuft bei jedem Tick. Prueft per Schwelle statt per exaktem Wert:
  // Ueberspringen (value = _kSettled) springt UEBER die Flip-Mitte hinweg,
  // die Schwelle erwischt das trotzdem.
  void _onRevealTick() {
    if (_frontShown || _reveal.value < _kFrontVisible) return;
    _frontShown = true;
    HapticFeedback.mediumImpact(); // "Da ist er!"
    widget.onRevealed();
  }

  void _onTap() {
    if (!widget.ready) return;

    if (_reveal.isDismissed) {
      // Erster Tap: Enthuellung starten. Idle stoppen, sonst laeuft der
      // Lichtstreifen ueber die Vorderseite weiter.
      _idle.stop();
      HapticFeedback.lightImpact(); // leichter Impuls zum Wackeln
      if (_reduceMotion) {
        // Kein Wackeln/Flip: direkt zur fertigen Vorderseite springen,
        // die Lesezeit laeuft trotzdem normal ab.
        _reveal.value = _kSettled;
      }
      _reveal.forward();
    } else if (_reveal.value < _kSettled) {
      // Tap waehrend der Animation: zur fertigen Vorderseite springen.
      _reveal.value = _kSettled;
      _reveal.forward();
    } else if (_reveal.value < _kOutro) {
      // Tap waehrend der Lesezeit: Lesezeit abkuerzen, Abgang laeuft normal.
      _reveal.value = _kOutro;
      _reveal.forward();
    }
    // Tap waehrend des Abgangs: nichts tun, ist gleich vorbei.
  }

  @override
  Widget build(BuildContext context) {
    // Zurueck (Pfeil ODER System-Geste) mitten in der Enthuellung: sofort
    // anhalten. Sonst laeuft die Animation waehrend der ~300 ms Pop-Animation
    // weiter, ueberschreitet die Flip-Mitte und speichert "aufgedeckt",
    // obwohl man den Namen nie gesehen hat.
    return PopScope(
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) _reveal.stop();
      },
      child: Scaffold(
        backgroundColor: AppColors.surface,
        body: SafeArea(
          child: Column(
            children: [
              const _HeaderSpacer(),
              Expanded(
                child: Padding(
                  // Gleiches Padding wie der CardSwiper -> exakt dieselbe
                  // Kartengroesse wie die Post-Karten im Stapel.
                  padding: const EdgeInsets.all(20),
                  child: GestureDetector(
                    onTap: _onTap,
                    // expand: die Column oben gibt nur LOCKERE Breite weiter.
                    // Die Rueckseite (Stack fit.expand) fuellt trotzdem, die
                    // Vorderseite (Container + Column) wuerde aber auf
                    // Inhaltsbreite schrumpfen -> beide Seiten fest auf volle
                    // Flaeche zwingen.
                    child: SizedBox.expand(
                      child: AnimatedBuilder(
                        animation: Listenable.merge([_idle, _reveal]),
                        builder: (context, _) => _buildCard(),
                      ),
                    ),
                  ),
                ),
              ),
              // Platzhalter fuer die Like/Nope-Leiste (8 + 72 + 24).
              const SizedBox(height: 104),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCard() {
    final r = _reveal.value;

    // ── Vor dem Tap: Rueckseite mit Lichtstreifen + Atmen ────────────────
    if (r == 0) {
      final t = _idle.value;
      // Atmen nur wenn tippbar: 1.0 -> 1.015 -> 1.0.
      final breathe = widget.ready
          ? 1 +
                0.015 *
                    Curves.easeInOut.transform(t < 0.5 ? t * 2 : (1 - t) * 2)
          : 1.0;
      return Transform.scale(
        scale: breathe,
        child: _CardBack(shine: t, showHint: widget.ready),
      );
    }

    // ── Wackeln: abklingende Sinus-Schwingung um die Z-Achse ─────────────
    final w = _interval(r, 0, _kWobbleEnd);
    final wobble = w < 1 ? math.sin(w * math.pi * 4) * 0.05 * (1 - w) : 0.0;

    // ── Flip: 0 -> pi um die Y-Achse ────────────────────────────────────
    final f = Curves.easeInOutCubic.transform(
      _interval(r, _kWobbleEnd, _kFlipEnd),
    );
    final angle = f * math.pi;
    // Anheben: beim Wackeln hoch auf 1.05, waehrend des Flips zurueck auf 1.
    final lift = 1 + 0.05 * Curves.easeOut.transform(w) * (1 - f);

    // ── Abgang: tritt zurueck (wie eine hintere Stapelkarte) + blendet aus.
    // Danach baut RankingPages den Stapel, der per DealIn hereinkommt.
    final o = Curves.easeInCubic.transform(_interval(r, _kOutro, 1));
    final outroScale = _reduceMotion ? 1.0 : 1 - 0.08 * o;

    final showFront = angle > math.pi / 2;
    final transform = Matrix4.identity()
      ..setEntry(3, 2, 0.0012) // Perspektive: nahe Kante wirkt groesser
      ..rotateZ(wobble)
      ..rotateY(angle)
      ..scaleByDouble(lift * outroScale, lift * outroScale, 1, 1);

    return Opacity(
      opacity: 1 - o,
      child: Transform(
        alignment: Alignment.center,
        transform: transform,
        child: showFront
            // Vorderseite um pi gegendrehen, sonst steht sie spiegelverkehrt.
            ? Transform(
                alignment: Alignment.center,
                transform: Matrix4.rotationY(math.pi),
                child: _CardFront(
                  progress: r,
                  targetUser: widget.targetUser,
                  postCount: widget.postCount,
                ),
              )
            : _CardBack(shine: 0, showHint: false),
      ),
    );
  }
}

/// Bildet t im Fenster [begin, end] auf 0..1 ab (davor 0, danach 1).
double _interval(double t, double begin, double end) =>
    ((t - begin) / (end - begin)).clamp(0.0, 1.0);

/// Gleiche Hoehe wie _SessionHeader (Padding 12/4 + Segmente 5 + Abstand 10 +
/// BackButton-Zeile 48), damit die Karte exakt dort sitzt, wo spaeter der
/// Stapel liegt. Fortschritt + Target bleiben bewusst leer -> nichts verraten.
class _HeaderSpacer extends StatelessWidget {
  const _HeaderSpacer();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Column(
        children: [
          const SizedBox(height: 5),
          const SizedBox(height: 10),
          Row(children: [BackButton(color: AppColors.primary)]),
        ],
      ),
    );
  }
}

/// Vorderseite: Profilbild (unscharf -> scharf), "Heute bewertest du",
/// @name, Post-Anzahl. progress = _reveal.value (0..1).
class _CardFront extends StatelessWidget {
  final double progress;
  final Map<String, dynamic>? targetUser;
  final int postCount;

  const _CardFront({
    required this.progress,
    required this.targetUser,
    required this.postCount,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final username = targetUser?['username']?.toString() ?? '';
    final picUrl = targetUser?['profile_picture_url']?.toString();
    final hasPic = picUrl != null && picUrl.isNotEmpty;

    // Unschaerfe 14 -> 0 zwischen 884 und 1508 ms.
    final sharp = Curves.easeOut.transform(
      _interval(progress, _at(884), _at(1508)),
    );
    final blur = 14 * (1 - sharp);

    // Gestaffeltes Reingleiten: Label, Name, Chip je 156 ms versetzt.
    Widget slideIn(int beginMs, Widget child) {
      final t = Curves.easeOutCubic.transform(
        _interval(progress, _at(beginMs), _at(beginMs + 260)),
      );
      return Opacity(
        opacity: t,
        child: Transform.translate(
          offset: Offset(0, 16 * (1 - t)),
          child: child,
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        color: AppColors.surfaceContainerLow,
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.25),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Avatar mit Ranked-Verlauf als Ring
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [AppColors.primary, AppColors.primaryContainer],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: ClipOval(
              child: SizedBox(
                width: 136,
                height: 136,
                child: ImageFiltered(
                  imageFilter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
                  child: hasPic
                      ? Image(
                          image: netImage(context, picUrl, logicalWidth: 136),
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => _avatarFallback(),
                        )
                      : _avatarFallback(),
                ),
              ),
            ),
          ),
          const SizedBox(height: 28),
          slideIn(
            1092,
            Text(
              l10n.rankingRevealToday.toUpperCase(),
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 2,
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(height: 8),
          slideIn(
            1248,
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                username.isEmpty ? '—' : '@$username',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 30,
                  fontWeight: FontWeight.w900,
                  fontStyle: FontStyle.italic,
                  color: AppColors.onSurface,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          slideIn(
            1404,
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainer,
                borderRadius: BorderRadius.circular(50),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.style_rounded, size: 16, color: AppColors.primary),
                  const SizedBox(width: 6),
                  Text(
                    l10n.rankingRevealPosts(postCount),
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _avatarFallback() => Container(
    color: AppColors.surfaceContainerHighest,
    child: Icon(Icons.person, size: 64, color: AppColors.onSurfaceVariant),
  );
}

/// Rueckseite: Ranked-Verlauf, duenner Innenrahmen wie bei einer Spielkarte,
/// Silhouette in der Mitte, Lichtstreifen wandert diagonal drueber.
class _CardBack extends StatelessWidget {
  /// 0..1 aus der Idle-Schleife. Streifen laeuft nur in 0..0.55, danach Pause.
  final double shine;
  final bool showHint;

  const _CardBack({required this.shine, required this.showHint});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primaryContainer],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.30),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Stack(
          fit: StackFit.expand,
          children: [
            _ShineStreak(progress: (shine / 0.55).clamp(0.0, 1.0)),
            // Innenrahmen
            Padding(
              padding: const EdgeInsets.all(12),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.28),
                    width: 1.5,
                  ),
                ),
              ),
            ),
            // Silhouette: "hier steckt jemand drin"
            Center(
              child: Container(
                width: 112,
                height: 112,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.14),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.35),
                    width: 1.5,
                  ),
                ),
                child: Icon(
                  Icons.person_rounded,
                  size: 64,
                  color: Colors.white.withValues(alpha: 0.75),
                ),
              ),
            ),
            // Hinweis unten, blendet ein sobald tippbar.
            Positioned(
              left: 0,
              right: 0,
              bottom: 48,
              child: AnimatedOpacity(
                opacity: showHint ? 1 : 0,
                duration: const Duration(milliseconds: 350),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.touch_app_rounded,
                      size: 18,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      context.l10n.rankingRevealTap,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Diagonaler, weicher Lichtstreifen. progress 0 = links ausserhalb,
/// 1 = rechts ausserhalb.
class _ShineStreak extends StatelessWidget {
  final double progress;

  const _ShineStreak({required this.progress});

  @override
  Widget build(BuildContext context) {
    if (progress <= 0 || progress >= 1) return const SizedBox.shrink();
    return LayoutBuilder(
      builder: (context, box) {
        final w = box.maxWidth;
        final h = box.maxHeight;
        final streakW = w * 0.45;
        // Startet links ausserhalb, endet rechts ausserhalb. Extra-Rand
        // (1.5x streakW), weil der gedrehte Streifen breiter wirkt.
        final x =
            -streakW * 1.5 +
            (w + streakW * 2.5) * Curves.easeInOut.transform(progress);
        return Stack(
          children: [
            Positioned(
              left: x,
              // Hoeher als die Karte, damit die Drehung keine Ecken freilegt.
              top: -h * 0.3,
              width: streakW,
              height: h * 1.6,
              child: Transform.rotate(
                angle: 0.35,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.white.withValues(alpha: 0),
                        Colors.white.withValues(alpha: 0.22),
                        Colors.white.withValues(alpha: 0),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Einzug der Session: Header, Kartenstapel und Like/Nope-Leiste kommen
/// EINMAL beim ersten Aufbau gestaffelt herein (Stapel "wird ausgeteilt").
/// Laeuft nach der Enthuellung UND wenn das Target schon aufgedeckt war.
///
/// Baut selbst die Column (header / Expanded(cards) / footer), damit alle
/// drei an EINEM Controller haengen. Spaetere Rebuilds (z. B. _submitting)
/// behalten den State -> der Einzug spielt nicht nochmal.
class StackDealIn extends StatefulWidget {
  final Widget header;
  final Widget cards;
  final Widget footer;

  const StackDealIn({
    super.key,
    required this.header,
    required this.cards,
    required this.footer,
  });

  @override
  State<StackDealIn> createState() => _StackDealInState();
}

class _StackDealInState extends State<StackDealIn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _c.value = 1; // Bewegung reduzieren -> sofort fertig
    } else if (_c.isDismissed) {
      _c.forward();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        final t = _c.value;
        final h = Curves.easeOutCubic.transform(_interval(t, 0, 0.5));
        final k = Curves.easeOutCubic.transform(_interval(t, 0.1, 0.85));
        final f = Curves.easeOutBack.transform(_interval(t, 0.45, 1));
        return Column(
          children: [
            Opacity(
              opacity: h,
              child: Transform.translate(
                offset: Offset(0, -12 * (1 - h)),
                child: widget.header,
              ),
            ),
            Expanded(
              child: Opacity(
                opacity: k,
                // Von unten rein, wie vom Stapel ausgeteilt.
                child: FractionalTranslation(
                  translation: Offset(0, 0.12 * (1 - k)),
                  child: widget.cards,
                ),
              ),
            ),
            Opacity(
              opacity: f.clamp(0.0, 1.0),
              child: Transform.scale(
                scale: 0.8 + 0.2 * f,
                child: widget.footer,
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Lade-Platzhalter, wenn heute SCHON aufgedeckt wurde: statt der verdeckten
/// Karte (die "neu" suggerieren wuerde) ein pulsierender Stapel in exakt dem
/// Raster der Session (Header 16/12/16/4, Karte mit Padding 20, Leiste
/// 40/8/40/24 mit 60er + 72er Kreis). So sitzt der echte Stapel danach
/// genau an derselben Stelle, wenn StackDealIn ihn hereinholt.
class StackSkeleton extends StatelessWidget {
  const StackSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final fill = AppColors.surfaceContainerHigh;

    Widget bar(double w, double h) => Container(
          width: w,
          height: h,
          decoration: BoxDecoration(
            color: fill,
            borderRadius: BorderRadius.circular(h / 2),
          ),
        );

    Widget circle(double d) => Container(
          width: d,
          height: d,
          decoration: BoxDecoration(color: fill, shape: BoxShape.circle),
        );

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Column(
          children: [
            // ── Header: gleiche Hoehen wie _SessionHeader ──────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Column(
                children: [
                  SkeletonPulse(
                    child: Container(
                      height: 5,
                      decoration: BoxDecoration(
                        color: fill,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      // BackButton bleibt echt + pulsiert nicht: man soll
                      // auch waehrend des Ladens raus koennen.
                      BackButton(color: AppColors.primary),
                      const Spacer(),
                      SkeletonPulse(
                        child: Row(
                          children: [
                            circle(36),
                            const SizedBox(width: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                bar(64, 8),
                                const SizedBox(height: 6),
                                bar(104, 14),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      SkeletonPulse(child: bar(46, 30)),
                      // Platz des ⋮-Buttons (IconButton = 48 x 48).
                      const SizedBox(width: 48),
                    ],
                  ),
                ],
              ),
            ),
            // ── Karte: selbes Padding wie CardSwiper ───────────────────────
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: SkeletonPulse(
                  child: Container(
                    decoration: BoxDecoration(
                      color: fill,
                      borderRadius: BorderRadius.circular(28),
                    ),
                    padding: const EdgeInsets.all(24),
                    // Andeutung von Titel + Text unten, wie auf der Post-Karte.
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _SkeletonLine(widthFactor: 0.6, height: 20),
                        const SizedBox(height: 10),
                        _SkeletonLine(widthFactor: 0.85, height: 12),
                        const SizedBox(height: 6),
                        _SkeletonLine(widthFactor: 0.5, height: 12),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            // ── Like/Nope-Leiste ───────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(40, 8, 40, 24),
              child: SkeletonPulse(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [circle(60), circle(72)],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Helle Linie auf der Skeleton-Karte (Breite relativ zur Karte).
class _SkeletonLine extends StatelessWidget {
  final double widthFactor;
  final double height;

  const _SkeletonLine({required this.widthFactor, required this.height});

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      widthFactor: widthFactor,
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(height / 2),
        ),
      ),
    );
  }
}

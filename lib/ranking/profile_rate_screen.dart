import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../l10n/l10n.dart';
import '../ui/app_colors.dart';
import '../ui/net_image.dart';
import 'profile_ranking_api_service.dart';
import 'profile_ranking_result.dart';

/// Profil-Ranking bewerten: die offenen Posts EINES Users, einer nach dem
/// anderen. Kommt aus der Bewerten-Karte im fremden Profil.
///
///   ‹ (o) @max                                  2/3
///   ━━━━━━━━━━━━━━━━━━━━━──────────────────────────
///   ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░  <- dasselbe Post-Bild,
///   ░░░░░░┌────────────────────────────┐░░░░░░░░░░     verschwommen
///   ░░░░░░│                            │░░░░░░░░░░
///   ░░░░░░│        Post-Karte 4:5      │░░░░░░░░░░  <- in jede Richtung
///   ░░░░░░│                            │░░░░░░░░░░     wegwerfbar
///   ░░░░░░└────────────────────────────┘░░░░░░░░░░
///     [ 👆 Doppeltipp = Gefällt mir ] [ ✥ Wegwerfen = Weiter ]  <- nur bis
///                                                        zur 1. Geste
///
/// Gibt beim Schließen `true` zurück, wenn mindestens ein Post bewertet
/// wurde -> das Profil lädt dann neu (onRated). Sonst `false`.
///
/// Bewusst KEIN Kartenstapel / Like-Nope-Stempel / Farbschimmer beim Ziehen
/// wie im Tagesranking: eine einzelne Karte, kein Wort "Swipe" im UI.
class ProfileRateScreen extends StatefulWidget {
  const ProfileRateScreen({super.key, required this.posts});

  /// Nackte Post-Objekte aus GET /profile_ranking/users/{id}/open
  /// (id, title, content, image_url, created_at, owner, ...).
  /// Älteste zuerst - genau in dieser Reihenfolge zeigen wir sie.
  final List<Map<String, dynamic>> posts;

  @override
  State<ProfileRateScreen> createState() => _ProfileRateScreenState();
}

class _ProfileRateScreenState extends State<ProfileRateScreen> {
  /// Was noch zu bewerten ist. Vorne = die Karte, die gerade zu sehen ist.
  /// Eine Warteschlange statt Index, weil RateFailed einen Post wieder
  /// hinten anhängt (siehe [_send]).
  late final List<Map<String, dynamic>> _queue = [...widget.posts];

  /// Wie viele schon erledigt sind (für "2/3" und die Fortschrittslinie).
  int _done = 0;

  /// Wurde mindestens einer bewertet? -> Rückgabewert beim Schließen.
  bool _ratedAny = false;

  /// Läuft gerade ein Like (Herz-Burst + Wurf nach oben)? Dann sind alle
  /// Gesten gesperrt: kein zweiter Doppeltipp (Doppel-Like) und kein
  /// Wegwerfen mittendrin. Erst wenn die Karte weg ist, wieder false.
  bool _liking = false;

  /// Gesten-Hinweis unten: nur bis zur ersten Geste, danach blendet er aus.
  bool _hintVisible = true;

  /// Steuert den Swiper von außen: nach dem Herz-Burst die Karte per Code
  /// nach oben werfen. Ein Controller für alle Karten reicht - jede neue
  /// Karte (neuer Swiper) meldet sich beim selben Controller an.
  final CardSwiperController _swiper = CardSwiperController();

  /// Besitzer steht in jedem Post - alle gehören demselben User.
  Map<String, dynamic>? get _owner => widget.posts.isEmpty
      ? null
      : widget.posts.first['owner'] as Map<String, dynamic>?;

  /// Gesamtzahl für den Zähler. Rechnet sich aus, statt fest
  /// widget.posts.length: RateFailed ändert die Schlange.
  int get _total => _done + _queue.length;

  @override
  void dispose() {
    _swiper.dispose();
    super.dispose();
  }

  /// Vorderste Karte aus der Schlange nehmen - NUR die Anzeige.
  /// Der Server-Request läuft getrennt davon über [_send].
  void _next() {
    if (_queue.isEmpty) return;
    setState(() {
      _queue.removeAt(0);
      _done++;
    });
  }

  /// Bewertung für [post] an den Server schicken. Optimistisch: die Karte
  /// ist schon weg (bzw. gleich), wir warten NICHT auf die Antwort.
  ///
  /// Bewusst ohne `await` aufgerufen (fire & forget) - die Antwort kommt
  /// irgendwann, auch wenn längst die nächste Karte zu sehen ist.
  Future<void> _send(Map<String, dynamic> post, {required bool liked}) async {
    // Schon VOR der Antwort: wer direkt nach dem letzten Post "Fertig"
    // tippt, soll trotzdem das Neuladen im Profil auslösen. Schlägt der
    // Request fehl, lädt das Profil eben umsonst neu - harmlos.
    _ratedAny = true;

    // Vor dem await holen: danach ist `context` evtl. nicht mehr gültig.
    final messenger = ScaffoldMessenger.of(context);
    final l10n = context.l10n;

    final result = await ProfileRankingApiService.ratePost(
      post['id'] as int,
      liked: liked,
    );
    // Screen schon zu? Dann ist die Antwort egal - der Request ist ja raus.
    if (!mounted) return;

    // Wichtig: Die Karte ist hier SCHON aus _queue raus (_next lief direkt
    // nach dem Senden, nicht erst nach der Antwort = optimistisch).
    switch (result) {
      // Gespeichert -> genau das, was wir angenommen haben. Nichts zu tun.
      case RateDone():
        break;

      // Abgelaufen / gesperrt / geblockt -> soll laut Vertrag lokal raus
      // und weiter. Ist er schon. Nichts zu tun.
      case RateGone():
        break;

      // Fehlgeschlagen -> unsere Annahme war falsch, also zurückdrehen:
      // Post hinten wieder dran, Zähler eins zurück.
      // War schon die End-Ansicht offen (_queue leer), ist _queue danach
      // nicht mehr leer -> build() zeigt automatisch wieder die Karte.
      case RateFailed():
        setState(() {
          _queue.add(post);
          _done--;
        });
        messenger.showSnackBar(SnackBar(content: Text(l10n.profileRateFailed)));
    }
  }

  /// Doppeltipp: Request sofort raus, dann Herz-Burst. Danach wirft
  /// [_onBurstDone] die Karte nach oben weg. Request VOR dem Burst: wer in
  /// den 700 ms rausgeht, verliert den Like sonst.
  void _onLike() {
    if (_liking || _queue.isEmpty) return;
    HapticFeedback.mediumImpact();
    _send(_queue.first, liked: true);
    setState(() {
      _liking = true;
      _hintVisible = false;
    });
  }

  /// Herz ist durch -> Karte per Code nach oben werfen ("hoch damit").
  /// _liking bleibt true, bis sie weg ist ([_onSwiped]).
  void _onBurstDone() {
    if (!mounted) return;
    _swiper.swipe(CardSwiperDirection.top);
  }

  /// Der Swiper meldet: Karte ist rausgeflogen (Animation fertig).
  /// Zwei Wege hierher:
  ///  - _liking == true  -> das war unser Like-Wurf nach oben, Request ist
  ///                        schon raus -> nur weiterschalten.
  ///  - sonst            -> der User hat sie weggeworfen = Weiter.
  bool _onSwiped(int previous, int? current, CardSwiperDirection direction) {
    if (_liking) {
      setState(() => _liking = false);
      _next();
    } else {
      _onSkip();
    }
    return true;
  }

  /// Wegwerfen (egal welche Richtung) oder Screenreader-Aktion "Weiter".
  void _onSkip() {
    // Screenreader-Aktion während eines Likes: sonst würde der Like-Wurf
    // danach noch eine zweite Karte überspringen.
    if (_liking || _queue.isEmpty) return;
    HapticFeedback.selectionClick();
    // Reihenfolge: erst senden (braucht _queue.first), dann rausnehmen.
    _send(_queue.first, liked: false);
    if (_hintVisible) setState(() => _hintVisible = false);
    _next();
  }

  /// Schließen mit Ergebnis - vom Zurück-Pfeil, vom "Fertig"-Button und
  /// (über PopScope) von der System-Zurück-Geste.
  void _close() => Navigator.pop(context, _ratedAny);

  @override
  Widget build(BuildContext context) {
    final current = _queue.isEmpty ? null : _queue.first;

    // PopScope: die System-Zurück-Geste würde sonst mit `null` poppen und
    // das Profil wüsste nicht, dass bewertet wurde. canPop:false fängt sie
    // ab, wir poppen selbst mit _ratedAny. (Navigator.pop selbst wird von
    // PopScope NICHT blockiert.)
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _close();
      },
      // Immer dunkler Hintergrund (wie ein Foto-Viewer) -> helle
      // Statusleisten-Icons, egal ob die App im Hell- oder Dunkelmodus ist.
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: Scaffold(
          backgroundColor: Colors.black,
          body: Stack(
            fit: StackFit.expand,
            children: [
              // Hintergrund blendet mit jeder Karte weich über.
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 450),
                child: _Backdrop(
                  key: ValueKey(current?['id'] ?? 'done'),
                  post: current,
                ),
              ),
              SafeArea(
                child: Column(
                  children: [
                    _RateHeader(
                      owner: _owner,
                      total: _total,
                      done: _done,
                      onBack: _close,
                    ),
                    Expanded(
                      child: current == null
                          ? _DoneView(onDone: _close)
                          : _cardArea(current),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _cardArea(Map<String, dynamic> post) {
    return Column(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
            // Feste Form 4:5 (wie ein Hochkant-Post), mittig. Ohne das würde
            // die Karte den ganzen freien Platz füllen -> je nach Handy ein
            // komisch hoher Streifen.
            child: Center(
              child: AspectRatio(
                aspectRatio: 4 / 5,
                // Neue Karte blendet weich ein. Key = Post-id (am Swiper),
                // sonst merkt der AnimatedSwitcher nicht, dass es eine
                // ANDERE Karte ist.
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  switchInCurve: Curves.easeOutCubic,
                  transitionBuilder: (child, anim) => FadeTransition(
                    opacity: anim,
                    child: ScaleTransition(
                      scale: Tween(begin: 0.94, end: 1.0).animate(anim),
                      child: child,
                    ),
                  ),
                  // Nur die NEUE Karte zeigen: die alte ist schon
                  // rausgeflogen, sie soll nicht nochmal ausblenden.
                  layoutBuilder: (current, _) => current ?? const SizedBox(),
                  // Trick: Der Swiper bekommt immer nur EINE Karte. Pro Post
                  // ein neuer Swiper (Key = Post-id). So bleibt unsere
                  // Warteschlange (RateFailed -> hinten dran) die Wahrheit,
                  // der Swiper liefert nur die Wurf-Physik.
                  child: CardSwiper(
                    key: ValueKey(post['id']),
                    controller: _swiper,
                    cardsCount: 1,
                    numberOfCardsDisplayed: 1,
                    isLoop: false,
                    padding: EdgeInsets.zero,
                    allowedSwipeDirection: const AllowedSwipeDirection.all(),
                    // Etwas Drehung, damit es sich nach "Werfen" anfühlt -
                    // aber deutlich weniger als die 30° Standard.
                    maxAngle: 12,
                    duration: const Duration(milliseconds: 260),
                    // Während des Likes gesperrt. swipe() per Controller
                    // geht trotzdem (der Swiper prüft isDisabled dort nicht).
                    isDisabled: _liking,
                    onSwipe: _onSwiped,
                    cardBuilder: (context, _, _, _) => _cardWithGestures(post),
                  ),
                ),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          child: IgnorePointer(
            child: AnimatedOpacity(
              opacity: _hintVisible ? 1 : 0,
              duration: const Duration(milliseconds: 300),
              child: const _HintChips(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _cardWithGestures(Map<String, dynamic> post) {
    // Screenreader: Werfen/Doppeltippen sind dort schwer bis unmöglich ->
    // beide Aktionen als Menü-Aktionen anbieten.
    return Semantics(
      customSemanticsActions: {
        CustomSemanticsAction(label: context.l10n.profileRateActionLike):
            _onLike,
        CustomSemanticsAction(label: context.l10n.profileRateActionSkip):
            _onSkip,
      },
      child: GestureDetector(
        onDoubleTap: _liking ? null : _onLike,
        child: Stack(
          fit: StackFit.expand,
          children: [
            _RatePostCard(post: post),
            if (_liking) _HeartBurst(onDone: _onBurstDone),
          ],
        ),
      ),
    );
  }
}

// ─── Hintergrund: das aktuelle Post-Bild, stark verschwommen ────────────────
// Füllt die Fläche um die Karte mit der Stimmung des Posts (wie Spotify /
// Apple Music beim Cover). Text-Posts ohne Bild: Ranked-Verlauf.
// Darüber ein dunkler Schleier, damit Header + Hinweise weiß lesbar sind.
class _Backdrop extends StatelessWidget {
  const _Backdrop({super.key, required this.post});

  /// null = End-Ansicht -> Verlauf.
  final Map<String, dynamic>? post;

  @override
  Widget build(BuildContext context) {
    final imageUrl = post?['image_url'] as String?;
    final hasImage = imageUrl != null && imageUrl.isNotEmpty;

    final gradient = DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primaryContainer],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
    );

    return SizedBox.expand(
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (hasImage)
            ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
              child: Image(
                // Wird eh verschwommen -> winzige Dekodier-Breite reicht,
                // spart Speicher und Zeit.
                image: netImage(context, imageUrl, logicalWidth: 120),
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => gradient,
              ),
            )
          else
            gradient,
          ColoredBox(color: Colors.black.withValues(alpha: 0.55)),
        ],
      ),
    );
  }
}

// ─── Kopfzeile: Zurück + Besitzer + Zähler + Fortschrittslinie ──────────────
// Schlanker als _SessionHeader im Tagesranking: eine dünne Linie statt
// Segmenten, weiß auf dem dunklen Hintergrund. Kein ⋮-Menü (Melden/Blocken
// gibt es hier bewusst nicht).
class _RateHeader extends StatelessWidget {
  const _RateHeader({
    required this.owner,
    required this.total,
    required this.done,
    required this.onBack,
  });

  final Map<String, dynamic>? owner;
  final int total;
  final int done;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final username = owner?['username']?.toString() ?? '';
    final picUrl = owner?['profile_picture_url']?.toString();
    final hasPic = picUrl != null && picUrl.isNotEmpty;
    // Aktuelle Karte = eins nach den erledigten, aber nie über total
    // (End-Ansicht zeigt "3/3", nicht "4/3").
    final current = (done + 1).clamp(1, total == 0 ? 1 : total);
    final progress = total == 0 ? 1.0 : done / total;

    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 20, 0),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                onPressed: onBack,
                icon: const Icon(Icons.arrow_back_ios_new_rounded),
                iconSize: 20,
                color: Colors.white,
                tooltip: MaterialLocalizations.of(context).backButtonTooltip,
              ),
              CircleAvatar(
                radius: 16,
                backgroundColor: Colors.white.withValues(alpha: 0.2),
                backgroundImage: hasPic
                    ? netImage(context, picUrl, logicalWidth: 32)
                    : null,
                child: hasPic
                    ? null
                    : const Icon(Icons.person, size: 16, color: Colors.white),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  username.isEmpty ? '—' : '@$username',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
              Text(
                '$current/$total',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: Colors.white.withValues(alpha: 0.75),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          // Dünne Fortschrittslinie, gleitet beim Weiterschalten.
          Padding(
            padding: const EdgeInsets.only(left: 16),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: SizedBox(
                height: 3,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    ColoredBox(color: Colors.white.withValues(alpha: 0.2)),
                    TweenAnimationBuilder<double>(
                      tween: Tween(end: progress),
                      duration: const Duration(milliseconds: 350),
                      curve: Curves.easeOutCubic,
                      builder: (_, value, _) => FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: value,
                        child: const ColoredBox(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Gesten-Hinweis als zwei kleine Glas-Chips ──────────────────────────────
class _HintChips extends StatelessWidget {
  const _HintChips();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    // Wrap statt Row: auf schmalen Handys / langen Übersetzungen bricht der
    // zweite Chip in die nächste Zeile statt überzulaufen.
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 10,
      runSpacing: 8,
      children: [
        _chip(Icons.touch_app_rounded, l10n.profileRateHintLike),
        _chip(Icons.open_with_rounded, l10n.profileRateHintSkip),
      ],
    );
  }

  Widget _chip(IconData icon, String text) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.14),
      borderRadius: BorderRadius.circular(999),
      border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: Colors.white),
        const SizedBox(width: 6),
        Text(
          text,
          style: GoogleFonts.inter(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ],
    ),
  );
}

// ─── Eine Post-Karte ────────────────────────────────────────────────────────
// Eigene Karte statt TextPost: TextPost hat einen eigenen onDoubleTap für
// den normalen Feed-Like -> Doppeltipp hier wäre sonst ein Doppel-Like.
//
// Mit Bild:  Foto bildfüllend, Titel/Text/Datum unten auf dunklem Verlauf.
// Ohne Bild: Ranked-Gradient, Titel/Text groß in der Mitte.
class _RatePostCard extends StatelessWidget {
  const _RatePostCard({required this.post});

  final Map<String, dynamic> post;

  @override
  Widget build(BuildContext context) {
    final imageUrl = post['image_url'] as String?;
    final hasImage = imageUrl != null && imageUrl.isNotEmpty;
    final title = (post['title'] as String? ?? '').trim();
    final content = (post['content'] as String? ?? '').trim();
    final created = DateTime.tryParse(post['created_at'] as String? ?? '');
    final dateText = created != null
        ? DateFormat.yMd(context.l10n.localeName).format(created.toLocal())
        : '';

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 30,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: hasImage
            ? _withImage(context, imageUrl, title, content, dateText)
            : _textOnly(title, content, dateText),
      ),
    );
  }

  Widget _withImage(
    BuildContext context,
    String imageUrl,
    String title,
    String content,
    String dateText,
  ) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image(
          image: netImage(
            context,
            imageUrl,
            logicalWidth: MediaQuery.sizeOf(context).width,
          ),
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => Container(
            color: AppColors.surfaceContainerHigh,
            child: Icon(
              Icons.image_not_supported_outlined,
              color: AppColors.onSurfaceVariant,
            ),
          ),
        ),
        // Unten abdunkeln, damit weiße Schrift auf jedem Foto lesbar ist.
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.transparent,
                Colors.transparent,
                Colors.black.withValues(alpha: 0.8),
              ],
              stops: const [0.0, 0.5, 1.0],
            ),
          ),
        ),
        Positioned(
          left: 24,
          right: 24,
          bottom: 24,
          child: _texts(title, content, dateText, centered: false),
        ),
      ],
    );
  }

  Widget _textOnly(String title, String content, String dateText) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primaryContainer],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Center(child: _texts(title, content, dateText, centered: true)),
      ),
    );
  }

  /// Titel / Text / Datum - Titel und Text sind optional (ein Post braucht
  /// nur Titel ODER Text ODER Bild) -> leer = samt Abstand weglassen.
  Widget _texts(
    String title,
    String content,
    String dateText, {
    required bool centered,
  }) {
    final align = centered ? TextAlign.center : TextAlign.start;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: centered
          ? CrossAxisAlignment.center
          : CrossAxisAlignment.start,
      children: [
        if (title.isNotEmpty) ...[
          Text(
            title.toUpperCase(),
            textAlign: align,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 26,
              fontWeight: FontWeight.w900,
              fontStyle: FontStyle.italic,
              color: Colors.white,
              height: 1.05,
            ),
          ),
          const SizedBox(height: 10),
        ],
        if (content.isNotEmpty) ...[
          Text(
            content,
            textAlign: align,
            // Ohne Bild ist Platz -> mehr Zeilen.
            maxLines: centered ? 8 : 3,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              fontSize: centered ? 16 : 14,
              color: Colors.white.withValues(alpha: 0.92),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
        ],
        if (dateText.isNotEmpty)
          Text(
            dateText,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: Colors.white70,
            ),
          ),
      ],
    );
  }
}

// ─── Herz-Burst beim Doppeltipp ─────────────────────────────────────────────
// Spielt EINMAL ab, sobald er im Baum auftaucht, und meldet sich dann über
// [onDone]. Der Screen blendet ihn per `if (_liking)` ein.
//
//   0 ms ──── 260 ──── 420 ──────── 560 ──── 700 ms
//   Herz wächst  federt    steht       blendet aus
//   0 -> 1.25    -> 1.0               (+ leichter Lila-Schleier)
class _HeartBurst extends StatefulWidget {
  const _HeartBurst({required this.onDone});

  final VoidCallback onDone;

  @override
  State<_HeartBurst> createState() => _HeartBurstState();
}

class _HeartBurstState extends State<_HeartBurst>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  );

  // Gewichte = Anteil an den 700 ms (37 % / 23 % / 40 %).
  late final Animation<double> _scale = TweenSequence([
    TweenSequenceItem(
      tween: Tween(
        begin: 0.0,
        end: 1.25,
      ).chain(CurveTween(curve: Curves.easeOutCubic)),
      weight: 37,
    ),
    TweenSequenceItem(
      tween: Tween(
        begin: 1.25,
        end: 1.0,
      ).chain(CurveTween(curve: Curves.easeInOut)),
      weight: 23,
    ),
    TweenSequenceItem(tween: ConstantTween(1.0), weight: 40),
  ]).animate(_c);

  // Sichtbar bis 80 %, dann ausblenden.
  late final Animation<double> _opacity = Tween(
    begin: 1.0,
    end: 0.0,
  ).animate(CurvedAnimation(parent: _c, curve: const Interval(0.8, 1.0)));

  @override
  void initState() {
    super.initState();
    _c.forward().whenComplete(() {
      if (mounted) widget.onDone();
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // IgnorePointer: der Burst liegt ÜBER der Karte und soll keine Taps
    // schlucken (die sind während _liking eh gesperrt, aber sauber ist sauber).
    return IgnorePointer(
      child: FadeTransition(
        opacity: _opacity,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            color: AppColors.primary.withValues(alpha: 0.18),
          ),
          child: Center(
            child: ScaleTransition(
              scale: _scale,
              child: Icon(
                Icons.favorite_rounded,
                size: 120,
                color: Colors.white,
                shadows: [
                  Shadow(
                    color: AppColors.primary.withValues(alpha: 0.6),
                    blurRadius: 32,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── End-Ansicht: alles bewertet ────────────────────────────────────────────
// Weiß auf dem dunklen Hintergrund (Verlauf + Schleier aus _Backdrop).
class _DoneView extends StatelessWidget {
  const _DoneView({required this.onDone});

  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          const Spacer(),
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.14),
              border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
            ),
            child: const Icon(
              Icons.check_rounded,
              size: 44,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            l10n.profileRateDoneTitle,
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              fontStyle: FontStyle.italic,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.profileRateDoneMessage,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: Colors.white.withValues(alpha: 0.75),
              height: 1.4,
            ),
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: onDone,
              style: FilledButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              child: Text(
                l10n.profileRateDoneButton,
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

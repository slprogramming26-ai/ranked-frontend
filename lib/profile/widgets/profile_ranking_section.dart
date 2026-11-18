import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../l10n/l10n.dart';
import '../../ranking/profile_ranking_api_service.dart';
import '../../ranking/profile_rate_screen.dart';
import '../../ranking/voting_explainer_sheet.dart';
import '../../ui/app_colors.dart';
// PROTOTYP A4e (Wasserpegel) - Entfern-Anleitung oben in hold_to_fill.dart.
import '../../ui/hold_to_fill.dart';
import '../../ui/net_image.dart';

/// PROTOTYP A4e: true = dezente Karte, gedrückt halten füllt sie mit Wasser
/// (bricht dann übers Profil aus). false = alte Gradient-Karte mit Tippen.
/// Zum Vergleichen / Meinungen einholen einfach umschalten.
const _useHoldToFill = true;

/// Sektion "RANKING" im Profil: die Profil-Ranking-Posts von [userId],
/// meiste Likes zuerst (Reihenfolge kommt vom Server).
///
/// Verwaltet Laden / Fehler / Nachladen selbst. Neu laden macht das Profil:
/// es baut die Sektion mit `key: ValueKey((userId, gen))` ein. Anderes
/// Profil ODER hochgezählter gen -> anderer Key -> frischer State.
class ProfileRankingSection extends StatefulWidget {
  const ProfileRankingSection({
    super.key,
    required this.userId,
    required this.isOwn,
    this.onRated,
  });

  final int userId;
  final bool isOwn;

  /// Wird gerufen, wenn im Bewerten-Screen bewertet wurde. Das Profil lädt
  /// dann still neu (LIKES-Zelle) und tauscht den Key dieser Sektion.
  final VoidCallback? onRated;

  @override
  State<ProfileRankingSection> createState() => _ProfileRankingSectionState();
}

class _ProfileRankingSectionState extends State<ProfileRankingSection> {
  static const _pageSize = 10;

  /// Alle bisher geladenen Einträge (Seite 1 + nachgeladene).
  final List<RankedPost> _posts = [];

  /// Läuft gerade ein Request? (Schutz gegen doppeltes Laden.)
  bool _loading = false;

  /// Ist der letzte Request fehlgeschlagen (getRankedPosts -> null)?
  bool _error = false;

  /// Kann es noch weitere Seiten geben? Startet mit true, solange wir es
  /// nicht besser wissen. Kam eine Seite mit weniger als [_pageSize]
  /// Einträgen zurück, ist das Ende erreicht -> false.
  bool _hasMore = true;

  /// Posts, die ICH bei [widget.userId] gerade bewerten kann (nur fremdes
  /// Profil). null = noch nicht geladen ODER Fehler -> dann gibt es einfach
  /// keine Bewerten-Karte. Die Ranking-Liste darunter funktioniert trotzdem.
  OpenPosts? _open;

  @override
  void initState() {
    super.initState();
    // Nach dem ersten Frame: setState direkt in initState ist verboten.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadMore();
      // Eigenes Profil: der Server sagt eh can_swipe=false -> Request sparen.
      if (!widget.isOwn) _loadOpen();
    });
  }

  // - Läuft schon ein Request oder gibt es nichts mehr -> nichts tun.
  // - ProfileRankingApiService.getRankedPosts(widget.userId,
  //       skip: ..., limit: _pageSize)
  // - null = Fehler, sonst Einträge anhängen und _hasMore neu setzen.
  // - Nach dem await an `mounted` denken.
  Future<void> _loadMore() async {
    if (!_hasMore || _loading) return;
    setState(() {
      _loading = true;
    }); // hilft gegen zu häufiges feuern
    final newPosts = await ProfileRankingApiService.getRankedPosts(
      widget.userId,
      skip: _posts.length,
      limit: _pageSize,
    );
    if (!mounted) return;
    if (newPosts == null) {
      setState(() {
        _error = true;
        _loading = false;
      });
      return;
    }
    setState(() {
      if (newPosts.length < _pageSize) _hasMore = false;
      _posts.addAll(newPosts);
      _loading = false;
    });
  }

  void _retry() {
    setState(() => _error = false);
    _loadMore();
  }

  /// Läuft parallel zu [_loadMore], unabhängig davon. Kein Fehler-UI:
  /// klappt es nicht, bleibt [_open] null und die Karte fehlt.
  Future<void> _loadOpen() async {
    final open = await ProfileRankingApiService.getOpenPosts(widget.userId);
    if (!mounted) return;
    setState(() => _open = open);
  }

  /// Bewerten-Screen öffnen. Kommt er mit `true` zurück (es wurde bewertet),
  /// stimmen Like-Zahlen, Herzen und offene Posts nicht mehr ->
  /// [ProfileRankingSection.onRated].
  ///
  /// [fade] (PROTOTYP A4e): nach dem Wasserpegel blendet der Screen über
  /// das Wasser ein statt reinzuschieben.
  Future<void> _openRateScreen(
    List<Map<String, dynamic>> posts, {
    bool fade = false,
  }) async {
    final screen = ProfileRateScreen(posts: posts);
    final rated = await Navigator.push<bool>(
      context,
      fade ? _fadeRoute(screen) : MaterialPageRoute(builder: (_) => screen),
    );
    if (rated == true) widget.onRated?.call();
  }

  /// PROTOTYP A4e: 300 ms = HoldToFill._routeFade (danach läuft dort das
  /// Wasser ab). Ändert man das eine, das andere mit.
  Route<bool> _fadeRoute(Widget screen) => PageRouteBuilder<bool>(
    transitionDuration: const Duration(milliseconds: 300),
    reverseTransitionDuration: const Duration(milliseconds: 250),
    pageBuilder: (_, _, _) => screen,
    transitionsBuilder: (_, anim, _, child) =>
        FadeTransition(opacity: anim, child: child),
  );

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              l10n.profileRankingTitle,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.5,
                color: AppColors.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: 2),
            const VotingInfoButton(size: 16),
          ],
        ),
        // 11 statt 20: die Zeile ist durch die 32er-Tippfläche vom ⓘ
        // schon ~18 px höher als der Text allein.
        const SizedBox(height: 11),
        // Record-Pattern: nur wenn der Server "darf bewerten" sagt UND
        // überhaupt Posts offen sind. Im eigenen Profil bleibt _open null.
        if (_open case (canRate: true, :final posts) when posts.isNotEmpty) ...[
          if (_useHoldToFill)
            _RateCardHold(
              count: posts.length,
              onConfirmed: () => _openRateScreen(posts, fade: true),
            )
          else
            _RateCardTap(
              count: posts.length,
              onTap: () => _openRateScreen(posts),
            ),
          const SizedBox(height: 16),
        ],
        ..._buildBody(),
      ],
    );
  }

  /// Liste leer -> einer der Zustände Fehler / Spinner / Leer-Text.
  /// Liste da   -> Einträge + Footer (Nachladen).
  List<Widget> _buildBody() {
    final l10n = context.l10n;
    if (_posts.isEmpty) {
      if (_error) return _errorWithRetry();
      // Noch nicht geladen ODER lädt gerade: wir wissen noch nicht, ob leer.
      if (_hasMore) return [_spinner()];
      return [
        _hint(
          widget.isOwn
              ? l10n.profileRankingEmptyOwn
              : l10n.profileRankingEmptyForeign,
        ),
      ];
    }

    return [for (final p in _posts) _RankedPostTile(entry: p), ..._footer()];
  }

  /// Unter der Liste: Spinner / Fehler + Retry / "Mehr anzeigen" / nichts.
  List<Widget> _footer() {
    // Request läuft -> Spinner statt Button (kein Doppel-Tippen).
    if (_loading) {
      return [const SizedBox(height: 6), _spinner()];
    }
    // Nachladen fehlgeschlagen -> die geladenen Einträge bleiben stehen,
    // darunter Fehler + Retry.
    if (_error) return [const SizedBox(height: 6), ..._errorWithRetry()];
    // Ende erreicht -> nichts mehr.
    if (!_hasMore) return const [];
    return [
      Center(
        child: TextButton(
          onPressed: _loadMore,
          child: Text(
            context.l10n.profileRankingShowMore,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            ),
          ),
        ),
      ),
    ];
  }

  Widget _spinner() => Center(
    child: SizedBox(
      width: 22,
      height: 22,
      child: CircularProgressIndicator(
        strokeWidth: 2,
        color: AppColors.primary,
      ),
    ),
  );

  List<Widget> _errorWithRetry() => [
    _hint(context.l10n.profileRankingError),
    TextButton(
      onPressed: _retry,
      style: TextButton.styleFrom(padding: EdgeInsets.zero),
      child: Text(
        context.l10n.profileRankingRetry,
        style: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppColors.primary,
        ),
      ),
    ),
  ];

  Widget _hint(String text) => Text(
    text,
    style: GoogleFonts.inter(
      fontSize: 13,
      color: AppColors.onSurfaceVariant,
      height: 1.4,
    ),
  );
}

/// Einstieg ins Bewerten (nur fremdes Profil):
///
///   ( ♥ )  3 Posts warten auf deine Bewertung   [Bewerten]
///
/// Ganze Karte tippbar. Ranked-Gradient wie das Badge in ranking_home.
/// Variante "Tippen" - aktiv, wenn `_useHoldToFill = false`.
class _RateCardTap extends StatelessWidget {
  const _RateCardTap({required this.count, required this.onTap});

  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final radius = BorderRadius.circular(20);
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: radius,
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primaryContainer],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.25),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      // Material + InkWell auf transparentem Grund: Ripple über dem Gradient.
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          borderRadius: radius,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 12, 14),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.favorite_rounded,
                    size: 20,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    l10n.profileRankingRateCardTitle(count),
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      height: 1.3,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    l10n.profileRankingRateButton,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// PROTOTYP A4e - Variante "Gedrückt halten" (`_useHoldToFill = true`):
///
///   ( ♥ )  3 Posts warten auf deine Bewertung
///          Zum Bewerten gedrückt halten
///
/// In Ruhe dezent (gleicher Grund wie die Ranking-Einträge darunter). Die
/// Farbe kommt erst durchs Halten: der Gradient steigt als Wasser hoch,
/// alles darunter wird weiß. Entfern-Anleitung: lib/ui/hold_to_fill.dart.
class _RateCardHold extends StatelessWidget {
  const _RateCardHold({required this.count, required this.onConfirmed});

  final int count;
  final VoidCallback onConfirmed;

  static const double _radius = 16;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return HoldToFill(
      borderRadius: _radius,
      onConfirmed: onConfirmed,
      gradient: LinearGradient(
        colors: [AppColors.primary, AppColors.primaryContainer],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      // Zweimal gebaut: normal + "unter Wasser" (weiß, transparent).
      builder: (context, onWater) => Container(
        padding: const EdgeInsets.fromLTRB(12, 12, 14, 12),
        color: onWater ? Colors.transparent : AppColors.surfaceContainerLow,
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: onWater
                    ? Colors.white.withValues(alpha: 0.2)
                    : AppColors.primary.withValues(alpha: 0.12),
              ),
              child: Icon(
                Icons.favorite_rounded,
                size: 20,
                color: onWater ? Colors.white : AppColors.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.profileRankingRateCardTitle(count),
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: onWater ? Colors.white : AppColors.onSurface,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    l10n.profileRankingHoldHint,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: onWater
                          ? Colors.white.withValues(alpha: 0.85)
                          : AppColors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.touch_app_rounded,
              size: 20,
              color: onWater ? Colors.white : AppColors.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}

/// Ein Eintrag der Ranking-Liste:
///
///   [Bild]  Titel oder Textanfang…          ♥ 24
///           12. Nov. · läuft noch
///
/// Kein onTap: es gibt (noch) keinen Post-Detail-Screen.
class _RankedPostTile extends StatelessWidget {
  const _RankedPostTile({required this.entry});

  final RankedPost entry;

  static const double _thumbSize = 52;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final post = entry.post;
    final imageUrl = post['image_url'] as String?;
    final hasImage = imageUrl != null && imageUrl.isNotEmpty;

    // Titel, sonst Textanfang. Ein Post braucht nur Titel ODER Text ODER
    // Bild -> reiner Bild-Post bekommt "Foto" statt einer leeren Zeile.
    final title = (post['title'] as String? ?? '').trim();
    final content = (post['content'] as String? ?? '').trim();
    final preview = title.isNotEmpty
        ? title
        : content.isNotEmpty
        ? content
        : l10n.profileRankingPhotoPost;

    // "2026-11-12" -> "12. Nov." / "Nov 12". Reines Datum, kein toLocal:
    // der Server meint den UTC-Tag, genau den zeigen wir.
    final entered = DateTime.tryParse(entry.enteredOn);
    final dateText = entered != null
        ? DateFormat.MMMd(l10n.localeName).format(entered)
        : '';

    // Gefülltes Herz = ICH habe "Gefällt mir" gegeben. Im eigenen Profil
    // immer null (eigene Posts kann man nicht bewerten) -> Umriss.
    final likedByMe = entry.myLike == true;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          // ── Vorschau ────────────────────────────────────────────
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              width: _thumbSize,
              height: _thumbSize,
              child: hasImage
                  ? Image(
                      image: netImage(
                        context,
                        imageUrl,
                        logicalWidth: _thumbSize,
                      ),
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => _thumbFallback(),
                    )
                  : _thumbFallback(),
            ),
          ),
          const SizedBox(width: 12),

          // ── Text + Datum/Status ─────────────────────────────────
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  preview,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.onSurface,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 4),
                Text.rich(
                  TextSpan(
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppColors.onSurfaceVariant,
                    ),
                    children: [
                      if (dateText.isNotEmpty) TextSpan(text: '$dateText · '),
                      // is_active kommt vom Server - nie selbst rechnen.
                      TextSpan(
                        text: entry.isActive
                            ? l10n.profileRankingActive
                            : l10n.profileRankingEnded,
                        style: entry.isActive
                            ? TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                              )
                            : null,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),

          // ── Likes ───────────────────────────────────────────────
          Icon(
            likedByMe ? Icons.favorite : Icons.favorite_border,
            size: 18,
            color: likedByMe ? AppColors.primary : AppColors.onSurfaceVariant,
          ),
          const SizedBox(width: 4),
          Text(
            '${entry.likeCount}',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: AppColors.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  /// Text-Post (oder Bild lädt nicht): Icon statt Bild.
  Widget _thumbFallback() => Container(
    color: AppColors.surfaceContainerHigh,
    child: Icon(
      Icons.notes_rounded,
      size: 22,
      color: AppColors.onSurfaceVariant,
    ),
  );
}

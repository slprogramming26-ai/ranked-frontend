import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../app_colors.dart';
import '../l10n/l10n.dart';
import '../post/widgets/collapse_out.dart';
import '../confirm_dialog.dart';
import 'action_sheet.dart';
import 'ban_sheet.dart';
import 'moderation_api_service.dart';
import 'remove_sheet.dart';
import 'report_card.dart';
import 'report_queue_item.dart';
import 'report_reason.dart';
import 'report_target.dart';
import 'user_role.dart';

/// Der Bereich "Meldungen" in ModerationHome: Status-Filter + Queue-Liste.
/// Kein eigenes Scaffold, Header und Admin-Umschalter liegen in ModerationHome.
class ReportQueueView extends StatefulWidget {
  /// Meine Rolle: Admin darf laenger/dauerhaft sperren, und die Rangregel
  /// entscheidet, ob Entfernen/Sperren ueberhaupt angeboten wird.
  final UserRole role;

  const ReportQueueView({super.key, required this.role});

  @override
  State<ReportQueueView> createState() => _ReportQueueViewState();
}

class _ReportQueueViewState extends State<ReportQueueView> {
  static const _limit = 20;

  final _scroll = ScrollController();

  ReportStatus _status = ReportStatus.pending;
  List<ReportQueueItem> _items = [];

  // Erste Seite: Spinner bzw. Fehler-Ansicht ueber den ganzen Bereich.
  bool _loading = true;
  bool _failed = false;

  // Nachladen: Spinner bzw. Retry-Link im Footer, die Liste bleibt stehen.
  bool _loadingMore = false;
  bool _moreFailed = false;
  bool _hasMore = true;

  // Laeuft gerade eine erste Seite (auch Pull-to-refresh)? Dann nicht
  // nachladen, sonst haengen wir an eine Liste an, die gleich ersetzt wird.
  // Ohne setState: rein intern, nichts davon ist sichtbar.
  bool _fetchingFirst = false;

  // Zaehlt jeden Neu-Lade-Vorgang hoch. Eine Antwort, deren Nummer nicht
  // mehr aktuell ist (Filter inzwischen gewechselt), wird verworfen.
  int _loadGen = 0;

  // Karten, bei denen gerade ein Request laeuft: key -> welcher Button (Spinner).
  final Map<String, ReportCardAction> _busy = {};

  // Karten, die auf dem Server schon erledigt sind und gerade wegklappen.
  // Sie stecken noch in _items, bis CollapseOut fertig ist.
  final Set<String> _removing = {};

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
    _fetchFirstPage(); // Startwerte (_loading = true) passen schon
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _onScroll() {
    // extentAfter = Pixel, die noch unter dem sichtbaren Bereich liegen.
    // Unabhaengig von der Listenlaenge (anders als "80 % von maxScrollExtent").
    if (_scroll.position.extentAfter < 400) _loadMore();
  }

  /// Alles auf "frisch laden": Liste weg, Spinner an.
  /// Fuer Filterwechsel und "Erneut versuchen", NICHT fuer Pull-to-refresh.
  void _resetAndLoad() {
    setState(() {
      _items = [];
      _removing.clear(); // gehoerte zur alten Liste
      _loading = true;
      _failed = false;
      _hasMore = true;
    });
    _fetchFirstPage();
  }

  /// Holt Seite 1 (skip 0) und ersetzt damit die Liste.
  /// [fromRefresh] = Pull-to-refresh: Schlaegt das fehl, bleibt die alte
  /// Liste stehen und es gibt nur eine Snackbar.
  Future<void> _fetchFirstPage({bool fromRefresh = false}) async {
    final gen = ++_loadGen;
    _fetchingFirst = true;

    final page = await ModerationApiService.getReports(
      status: _status,
      limit: _limit,
    );
    // Ueberholt? Dann gehoert der State schon dem neueren Aufruf,
    // hier nichts anfassen (auch _fetchingFirst nicht).
    if (!mounted || gen != _loadGen) return;
    _fetchingFirst = false;

    final keepOldList = page == null && fromRefresh && _items.isNotEmpty;
    setState(() {
      _loading = false;
      // Ein evtl. noch laufendes _loadMore ist durch ++_loadGen veraltet,
      // seine Antwort wird verworfen. Den Footer deshalb hier aufraeumen,
      // sonst bliebe _loadingMore fuer immer true.
      _loadingMore = false;
      _moreFailed = false;
      if (page != null) {
        _items = page;
        // Die neue Seite kommt frisch vom Server, erledigte Ziele sind dort
        // schon raus. Wegklappende Karten der alten Liste gibt es nicht mehr.
        _removing.clear();
        _hasMore = page.isNotEmpty;
      } else if (!keepOldList) {
        _failed = true;
      }
    });
    if (keepOldList) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.moderationLoadFailed)),
      );
    }
  }

  /// Naechste Seite anhaengen. Ausgeloest vom Scroll-Listener.
  Future<void> _loadMore() async {
    if (_fetchingFirst ||
        _loadingMore ||
        _moreFailed || // nach Fehler nur per Retry-Link, nicht bei jedem Scroll-Pixel
        !_hasMore ||
        _items.isEmpty) {
      return;
    }

    final gen = _loadGen; // KEIN ++: Nachladen gehoert zum aktuellen Durchgang
    setState(() => _loadingMore = true);

    final page = await ModerationApiService.getReports(
      status: _status,
      // Erledigte Eintraege sind auf dem Server raus aus "Offen". Bei uns
      // haengen die wegklappenden noch in _items -> die abziehen, sonst
      // ueberspringen wir genau so viele Eintraege.
      skip: _items.length - _removing.length,
      limit: _limit,
    );
    if (!mounted || gen != _loadGen) return;

    setState(() {
      _loadingMore = false;
      if (page == null) {
        _moreFailed = true;
        return;
      }
      // Dedupe: Die Queue ist nach Anzahl sortiert. Bekommt ein Ziel neue
      // Meldungen, kann es nach oben rutschen und doppelt auftauchen.
      final known = {for (final item in _items) item.key};
      _items.addAll(page.where((item) => !known.contains(item.key)));
      // Nicht "== _limit": Seiten koennen durch nonNulls/Dedupe kuerzer sein,
      // obwohl der Server noch mehr hat. Erst eine LEERE Seite heisst Ende.
      _hasMore = page.isNotEmpty;
    });
  }

  /// Footer-Link "Erneut versuchen" nach fehlgeschlagenem Nachladen.
  void _retryMore() {
    setState(() => _moreFailed = false);
    _loadMore();
  }

  /// "Ablehnen" / "Erledigt" auf einer Karte. Erst nach Server-OK klappt sie
  /// weg, bei Fehler bleibt sie stehen und es gibt eine Snackbar.
  Future<void> _resolve(ReportQueueItem item, ReportStatus status) async {
    final key = item.key;
    if (_busy.containsKey(key)) return; // Doppeltipp

    setState(() => _busy[key] = status == ReportStatus.dismissed
        ? ReportCardAction.dismiss
        : ReportCardAction.act);
    final ok = await ModerationApiService.resolve(item, status);
    if (!mounted) return;

    // Steht die Karte noch in der Liste? Nach einem Filterwechsel waehrend
    // des Requests nicht mehr. Dann darf der key NICHT nach _removing, er
    // laege dort fuer immer und wuerde skip in _loadMore verfaelschen.
    final stillShown = _items.any((i) => i.key == key);

    setState(() {
      _busy.remove(key);
      if (ok && stillShown) _removing.add(key);
    });
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.moderationResolveFailed)),
      );
    }
  }

  /// "Massnahme ergreifen": Sheet mit Stufe 2 -> je nach Wahl weiter an
  /// _remove / _ban / _unban / _resolve. Angeboten wird nur, was geht.
  Future<void> _takeAction(ReportQueueItem item) async {
    if (_busy.containsKey(item.key)) return;

    // Rangregel: Das Backend zeigt Meldungen gegen gleich-/hoeherrangige
    // gar nicht erst. Greift nur, wenn sich die Rolle nach dem Laden aendert.
    final mayAct = _outranks(item);
    final banned = item.user.isBanned;
    final action = await showActionSheet(
      context,
      target: item.target,
      username: item.user.username,
      restricted: !mayAct,
      available: {
        if (mayAct && _canRemove(item)) ModerationAction.remove,
        // Gesperrt -> nur Entsperren (zum Verlaengern erst entsperren).
        if (mayAct && !banned) ModerationAction.ban,
        if (mayAct && banned) ModerationAction.unban,
        ModerationAction.markDone,
      },
    );
    if (action == null || !mounted) return; // abgebrochen

    switch (action) {
      case ModerationAction.remove:
        await _remove(item);
      case ModerationAction.ban:
        await _ban(item);
      case ModerationAction.unban:
        await _unban(item);
      case ModerationAction.markDone:
        await _resolve(item, ReportStatus.actionTaken);
    }
  }

  /// "Sperren": Sheet (Dauer + Begruendung) -> banUser -> Badge aktualisieren.
  /// Die Karte bleibt stehen, Sperren erledigt keine Meldungen.
  Future<void> _ban(ReportQueueItem item) async {
    final key = item.key;
    if (_busy.containsKey(key)) return;

    final selection = await showBanSheet(
      context,
      username: item.user.username,
      isAdmin: widget.role.isAdmin,
      isBanned: item.user.isBanned,
    );
    if (selection == null || !mounted) return; // abgebrochen

    setState(() => _busy[key] = ReportCardAction.act);
    final result = await ModerationApiService.banUser(
      item.user.id,
      days: selection.days,
      reason: selection.reason,
    );
    if (!mounted) return;

    // Lokal nachrechnen, was der Server gesetzt hat (Jahr 9999 = dauerhaft).
    final days = selection.days;
    final until = days == null
        ? DateTime(9999, 12, 31)
        : DateTime.now().add(Duration(days: days));

    setState(() {
      _busy.remove(key);
      if (result == ModerationResult.ok) _setBan(item.user.id, until);
    });
    _showResult(
      result,
      okText: context.l10n.moderationUserBanned(item.user.username),
    );
  }

  /// ALLE Karten dieses Users anpassen, nicht nur die angetippte:
  /// derselbe User kann mit Post + Kommentar + Profil in der Queue stehen.
  /// until == null = entsperrt. Nur innerhalb von setState aufrufen.
  void _setBan(int userId, DateTime? until) {
    _items = [
      for (final i in _items)
        i.user.id == userId ? i.copyWith(user: i.user.withBan(until)) : i,
    ];
  }

  /// "Entsperren": Bestaetigen -> unbanUser -> Badge auf allen Karten weg.
  /// Wie beim Sperren bleiben die Meldungen offen (kein resolve).
  Future<void> _unban(ReportQueueItem item) async {
    final key = item.key;
    if (_busy.containsKey(key)) return;

    final l = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => ConfirmDialog(
        icon: Icons.lock_open_rounded,
        title: l.moderationUnbanTitle(item.user.username),
        message: l.moderationUnbanMessage,
        confirmLabel: l.moderationUnban,
      ),
    );
    // null (weggetippt) oder false (Abbrechen) -> nichts tun.
    if (confirmed != true || !mounted) return;

    setState(() => _busy[key] = ReportCardAction.act);
    final result = await ModerationApiService.unbanUser(item.user.id);
    if (!mounted) return;

    setState(() {
      _busy.remove(key);
      // null = entsperrt, deshalb nimmt _setBan ein DateTime?.
      if (result == ModerationResult.ok) _setBan(item.user.id, null);
    });
    _showResult(
      result,
      okText: context.l10n.moderationUserUnbanned(item.user.username),
    );
  }

  /// "Entfernen": Sheet (Grund + optionale Begruendung) -> removeContent.
  /// Post/Kommentar/Story: Das Backend setzt die Meldungen selbst auf
  /// action_taken -> Karte klappt weg. Profilbild: Meldungen bleiben offen
  /// (koennen auch Name/Bio betreffen) -> Karte bleibt, nur das Bild geht.
  Future<void> _remove(ReportQueueItem item) async {
    final key = item.key;
    if (_busy.containsKey(key)) return;

    final selection = await showRemoveSheet(
      context,
      target: item.target,
      initialReason: _topReason(item),
    );
    if (selection == null || !mounted) return; // abgebrochen

    setState(() => _busy[key] = ReportCardAction.act);
    final result = await ModerationApiService.removeContent(
      item,
      selection.reason,
      details: selection.details,
    );
    if (!mounted) return;

    final isPicture = item.target == ReportTarget.user;
    // Wie bei _resolve: nach einem Filterwechsel nicht mehr in der Liste
    // -> dann NICHT nach _removing (laege dort fuer immer, skip falsch).
    final index = _items.indexWhere((i) => i.key == key);

    setState(() {
      _busy.remove(key);
      if (result != ModerationResult.ok || index == -1) return;
      if (isPicture) {
        final current = _items[index];
        final preview = current.preview;
        if (preview != null) {
          _items[index] = current.copyWith(preview: preview.withoutImage());
        }
      } else {
        _removing.add(key);
      }
    });
    final l = context.l10n;
    _showResult(
      result,
      okText: isPicture ? l.moderationPictureRemoved : l.moderationContentRemoved,
    );
  }

  /// Haeufigster Meldegrund als Vorauswahl im Entfernen-Sheet.
  ReportReason? _topReason(ReportQueueItem item) {
    if (item.reasons.isEmpty) return null;
    return item.reasons.entries
        .reduce((a, b) => b.value > a.value ? b : a)
        .key;
  }

  /// Gibt es ueberhaupt etwas zu entfernen? Vom User geloescht -> 404,
  /// User ohne Profilbild -> 400. Beides gar nicht erst anbieten.
  bool _canRemove(ReportQueueItem item) {
    if (item.contentDeleted) return false;
    if (item.target != ReportTarget.user) return true;
    final image = item.preview?.imageUrl;
    return image != null && image.isNotEmpty;
  }

  /// Snackbar nach Entfernen/Sperren/Entsperren, je nach Ergebnis.
  void _showResult(ModerationResult result, {required String okText}) {
    final l = context.l10n;
    final text = switch (result) {
      ModerationResult.ok => okText,
      ModerationResult.forbidden => l.moderationForbidden,
      ModerationResult.failed => l.moderationActionFailed,
    };
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text)),
    );
  }

  /// Rangregel wie im Backend: nur gegen niedrigere Rollen vorgehen.
  /// Sonst gaebe es garantiert ein 403, also gar nicht erst anbieten.
  bool _outranks(ReportQueueItem item) =>
      item.user.role.index < widget.role.index;

  /// CollapseOut ist fertig: jetzt wirklich aus der Liste nehmen.
  void _onCollapsed(String key) {
    if (!mounted) return;
    setState(() {
      _items.removeWhere((i) => i.key == key);
      _removing.remove(key);
    });

    // Nachladen haengt sonst am Scroll-Listener. Arbeitet der Mod die Karten
    // ab, ohne zu scrollen, kaeme nie ein Scroll-Event:
    if (_items.isEmpty) {
      // Alles weg -> sonst stuende "Keine offenen Meldungen", obwohl der
      // Server evtl. noch mehr hat. Einfach frisch laden.
      if (_hasMore) _resetAndLoad();
    } else {
      // Liste wurde kuerzer -> nach dem Layout pruefen, ob das Ende schon
      // in Sicht ist (gleiche Regel wie beim Scrollen).
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _scroll.hasClients) _onScroll();
      });
    }
  }

  void _changeFilter(ReportStatus status) {
    if (status == _status) return;
    _status = status; // _resetAndLoad baut per setState ohnehin neu
    _resetAndLoad();
  }

  // ── UI ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Horizontal scrollbar, falls die Chips in einer Sprache mal zu breit
        // werden (EN "Action taken").
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            children: [
              for (final status in ReportStatus.values) ...[
                _FilterChip(
                  label: switch (status) {
                    ReportStatus.pending => l.moderationFilterPending,
                    ReportStatus.dismissed => l.moderationFilterDismissed,
                    ReportStatus.actionTaken => l.moderationFilterActionTaken,
                  },
                  selected: status == _status,
                  onTap: () => _changeFilter(status),
                ),
                const SizedBox(width: 8),
              ],
            ],
          ),
        ),
        const SizedBox(height: 12),
        Expanded(child: _buildBody()),
      ],
    );
  }

  /// Vier Zustaende per fruehem Return, wie in BlockedAccountsScreen.
  Widget _buildBody() {
    final l = context.l10n;

    if (_loading) {
      return Center(child: CircularProgressIndicator(color: AppColors.primary));
    }

    if (_failed) {
      return _CenteredMessage(
        icon: Icons.wifi_off_rounded,
        text: l.moderationLoadFailed,
        action: _RetryButton(onPressed: _resetAndLoad),
      );
    }

    if (_items.isEmpty) {
      return _CenteredMessage(
        icon: _status == ReportStatus.pending
            ? Icons.verified_outlined
            : Icons.inbox_outlined,
        text: switch (_status) {
          ReportStatus.pending => l.moderationEmptyPending,
          ReportStatus.dismissed => l.moderationEmptyDismissed,
          ReportStatus.actionTaken => l.moderationEmptyActionTaken,
        },
      );
    }

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () => _fetchFirstPage(fromRefresh: true),
      child: ListView.builder(
        controller: _scroll,
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 40),
        itemCount: _items.length + 1, // +1 = Footer
        itemBuilder: (_, i) {
          if (i == _items.length) return _buildFooter();
          final item = _items[i];
          final key = item.key;
          // Buttons nur bei "Offen": Abgelehnte/Erledigte sind schon entschieden.
          final actionable = _status == ReportStatus.pending;
          // ValueKey: Klappt eine Karte weg, ruecken die anderen nach, ohne
          // dass ihr State (Spinner, aufgeklappte Details) verrutscht.
          return CollapseOut(
            key: ValueKey(key),
            collapsed: _removing.contains(key),
            onCollapsed: () => _onCollapsed(key),
            child: ReportCard(
              item: item,
              busyAction: _busy[key],
              onDismiss: actionable
                  ? () => _resolve(item, ReportStatus.dismissed)
                  : null,
              onTakeAction: actionable ? () => _takeAction(item) : null,
            ),
          );
        },
      ),
    );
  }

  /// Unter der Liste: Spinner beim Nachladen, Retry-Link nach Fehler, sonst nichts.
  Widget _buildFooter() {
    if (_loadingMore) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Center(
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.primary,
            ),
          ),
        ),
      );
    }
    if (_moreFailed) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Center(child: _RetryButton(onPressed: _retryMore)),
      );
    }
    return const SizedBox.shrink();
  }
}

// ── Kleine Bausteine ─────────────────────────────────────────────────────

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        height: 34,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary.withValues(alpha: 0.12)
              : AppColors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(17),
          border: Border.all(
            color: AppColors.primary.withValues(alpha: selected ? 0.35 : 0.07),
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: selected ? AppColors.primary : AppColors.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

class _RetryButton extends StatelessWidget {
  final VoidCallback onPressed;
  const _RetryButton({required this.onPressed});

  @override
  Widget build(BuildContext context) => TextButton(
        onPressed: onPressed,
        child: Text(
          context.l10n.moderationRetry,
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
          ),
        ),
      );
}

/// Icon + Text (+ optionaler Button) mittig. Gleicher Look wie in
/// BlockedAccountsScreen (dort privat, deshalb eine eigene Kopie).
class _CenteredMessage extends StatelessWidget {
  final IconData icon;
  final String text;
  final Widget? action;

  const _CenteredMessage({required this.icon, required this.text, this.action});

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 40, color: AppColors.onSurfaceVariant),
              const SizedBox(height: 12),
              Text(
                text,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: AppColors.onSurfaceVariant,
                ),
              ),
              if (action != null) ...[
                const SizedBox(height: 8),
                action!,
              ],
            ],
          ),
        ),
      );
}

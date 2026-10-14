import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../app_colors.dart';
import '../confirm_dialog.dart';
import '../l10n/l10n.dart';
import 'log_card.dart';
import 'moderation_api_service.dart';
import 'moderation_log_entry.dart';
import 'report_queue_item.dart';

/// Der Bereich "Protokoll" in ModerationHome (nur Admin): alle Moderations-
/// Aktionen, neueste zuerst, mit Nachladen beim Scrollen.
/// Kein eigenes Scaffold, Header und Umschalter liegen in ModerationHome.
class AuditLogView extends StatefulWidget {
  const AuditLogView({super.key});

  @override
  State<AuditLogView> createState() => _AuditLogViewState();
}

class _AuditLogViewState extends State<AuditLogView> {
  static const _limit = 30;

  final _scroll = ScrollController();

  List<ModerationLogEntry> _entries = [];

  // Filter, alle kombinierbar. Die Namens-Filter kommen per Tipp auf einen
  // Namen in einer Karte; ReportedUser statt nur id, damit der Chip den
  // Namen zeigen kann.
  AuditFilter _filter = AuditFilter.all;
  ReportedUser? _moderator;
  ReportedUser? _target;

  bool get _isFiltered =>
      _filter != AuditFilter.all || _moderator != null || _target != null;

  // Erste Seite: Spinner bzw. Fehler-Ansicht ueber den ganzen Bereich.
  bool _loading = true;
  bool _failed = false;

  // Nachladen: Spinner bzw. Retry-Link im Footer, die Liste bleibt stehen.
  bool _loadingMore = false;
  bool _moreFailed = false;
  bool _hasMore = true;

  // Wie in der Queue: laeuft gerade Seite 1, nicht nachladen.
  bool _fetchingFirst = false;

  // Wie in der Queue: veraltete Antworten (Filter gewechselt) verwerfen.
  int _loadGen = 0;

  // Log-IDs, deren Restore gerade laeuft (Spinner im Button, Doppeltipp).
  final Set<int> _restoring = {};

  // Hier wiederhergestellt -> gruenes Badge statt Button. Nach 404 kommt die
  // id NICHT hier rein: dann wissen wir nicht, ob restored oder abgelaufen.
  final Set<int> _restoredHere = {};

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
    _fetchFirstPage();
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scroll.position.extentAfter < 400) _loadMore();
  }

  /// Liste weg, Spinner an, Seite 1 holen. Fuer Filterwechsel und Retry.
  void _resetAndLoad() {
    setState(() {
      _entries = [];
      _loading = true;
      _failed = false;
      _hasMore = true;
    });
    _fetchFirstPage();
  }

  /// Seite 1 ersetzt die Liste. Bei Pull-to-refresh bleibt die alte Liste
  /// stehen, wenn es fehlschlaegt (nur Snackbar).
  Future<void> _fetchFirstPage({bool fromRefresh = false}) async {
    final gen = ++_loadGen;
    _fetchingFirst = true;

    final page = await ModerationApiService.getActions(
      filter: _filter,
      moderatorId: _moderator?.id,
      targetUserId: _target?.id,
      limit: _limit,
    );
    if (!mounted || gen != _loadGen) return;
    _fetchingFirst = false;

    final keepOldList = page == null && fromRefresh && _entries.isNotEmpty;
    setState(() {
      _loading = false;
      _loadingMore = false; // laufendes _loadMore ist jetzt veraltet
      _moreFailed = false;
      if (page != null) {
        _entries = page;
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

  Future<void> _loadMore() async {
    if (_fetchingFirst ||
        _loadingMore ||
        _moreFailed ||
        !_hasMore ||
        _entries.isEmpty) {
      return;
    }

    final gen = _loadGen;
    setState(() => _loadingMore = true);

    final page = await ModerationApiService.getActions(
      filter: _filter,
      moderatorId: _moderator?.id,
      targetUserId: _target?.id,
      skip: _entries.length,
      limit: _limit,
    );
    if (!mounted || gen != _loadGen) return;

    setState(() {
      _loadingMore = false;
      if (page == null) {
        _moreFailed = true;
        return;
      }
      // Dedupe per id: Kommt oben ein neuer Eintrag dazu (anderer Admin),
      // rutscht alles eins nach hinten -> der letzte Eintrag unserer Liste
      // steckt dann nochmal vorne in der neuen Seite.
      final known = {for (final e in _entries) e.id};
      _entries.addAll(page.where((e) => !known.contains(e.id)));
      _hasMore = page.isNotEmpty;
    });
  }

  void _retryMore() {
    setState(() => _moreFailed = false);
    _loadMore();
  }

  /// Entfernten Inhalt zurueckholen. Erst Dialog, dann Request; die Liste
  /// wird lokal angepasst statt neu geladen (Scroll-Position bleibt).
  Future<void> _restore(ModerationLogEntry entry) async {
    if (_restoring.contains(entry.id)) return;

    final l = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => ConfirmDialog(
        icon: Icons.restore_rounded,
        title: l.auditRestoreTitle,
        message: l.auditRestoreMessage,
        confirmLabel: l.auditRestore,
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _restoring.add(entry.id));
    final result = await ModerationApiService.restoreContent(entry.id);
    if (!mounted) return;

    setState(() {
      _restoring.remove(entry.id);
      switch (result) {
        case RestoreOk(entry: final restored):
          _replace(entry.id, entry.markRestored());
          _restoredHere.add(entry.id);
          // Nur einfuegen, wenn der Server ihn bei diesem Filter auch
          // liefern wuerde. Sonst waere _entries.length um 1 groesser als
          // die Server-Liste und skip in _loadMore uebersprange einen Eintrag.
          if (_matchesFilter(restored)) _entries.insert(0, restored);
        case RestoreGone():
          // Endgueltig: Button weg (sonst tippt man immer wieder ins 404).
          _replace(entry.id, entry.markRestored());
        case RestoreConflict() || RestoreForbidden() || RestoreFailed():
          // Button bleibt: bei 409 kann es spaeter gehen (Post erst
          // wiederherstellen), bei Failed ist es ein Netzproblem.
          break;
      }
    });

    final text = switch (result) {
      RestoreOk(entry: final restored) =>
        restored.extra['location_dropped'] == true
            ? l.auditRestoredNoLocation
            : l.auditRestored,
      RestoreGone() => l.auditRestoreGone,
      RestoreConflict() => switch (entry.type) {
        ModerationActionType.deleteComment => l.auditRestoreConflictComment,
        ModerationActionType.deleteStory => l.auditRestoreConflictStory,
        ModerationActionType.deleteProfilePicture =>
          l.auditRestoreConflictPicture,
        _ => l.auditRestoreConflict,
      },
      RestoreForbidden() => l.auditRestoreForbidden,
      RestoreFailed() => l.auditRestoreFailed,
    };
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  /// Eintrag per id ersetzen. Nach einem Filterwechsel waehrend des
  /// Requests ist er evtl. nicht mehr in der Liste -> dann nichts tun.
  void _replace(int id, ModerationLogEntry updated) {
    final i = _entries.indexWhere((e) => e.id == id);
    if (i != -1) _entries[i] = updated;
  }

  /// Wuerde GET /admin/actions diesen Eintrag mit den aktiven Filtern liefern?
  bool _matchesFilter(ModerationLogEntry e) {
    if (_filter.types.isNotEmpty && !_filter.types.contains(e.type)) {
      return false;
    }
    if (_moderator != null && e.moderator?.id != _moderator!.id) return false;
    if (_target != null && e.targetUser?.id != _target!.id) return false;
    return true;
  }

  // Alle drei setzen nur das Feld und laden neu; _resetAndLoad baut per
  // setState ohnehin neu. Gleicher Wert -> nichts tun (kein Flackern).

  void _setFilter(AuditFilter filter) {
    if (filter == _filter) return;
    _filter = filter;
    _resetAndLoad();
  }

  /// null = Filter aufheben (✕ am Chip).
  void _setModerator(ReportedUser? user) {
    if (user?.id == _moderator?.id) return;
    _moderator = user;
    _resetAndLoad();
  }

  void _setTarget(ReportedUser? user) {
    if (user?.id == _target?.id) return;
    _target = user;
    _resetAndLoad();
  }

  // ── UI ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Horizontal scrollbar: 6 Chips passen nicht auf jedes Handy.
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            children: [
              for (final filter in AuditFilter.values) ...[
                _FilterChip(
                  label: switch (filter) {
                    AuditFilter.all => l.auditFilterAll,
                    AuditFilter.bans => l.auditFilterBans,
                    AuditFilter.removals => l.auditFilterRemovals,
                    AuditFilter.resolved => l.auditFilterResolved,
                    AuditFilter.roles => l.auditFilterRoles,
                    AuditFilter.restored => l.auditFilterRestored,
                  },
                  selected: filter == _filter,
                  onTap: () => _setFilter(filter),
                ),
                const SizedBox(width: 8),
              ],
            ],
          ),
        ),
        // Aktive Namens-Filter als eigene Zeile, jeweils mit ✕.
        if (_moderator != null || _target != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (_moderator case final mod?)
                  _UserFilterChip(
                    label: l.userDetailLogBy(mod.username),
                    onClear: () => _setModerator(null),
                  ),
                if (_target case final target?)
                  _UserFilterChip(
                    label: l.auditLogAgainst(target.username),
                    onClear: () => _setTarget(null),
                  ),
              ],
            ),
          ),
        const SizedBox(height: 12),
        Expanded(child: _buildBody()),
      ],
    );
  }

  /// Vier Zustaende per fruehem Return, wie in der Queue.
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

    if (_entries.isEmpty) {
      return _CenteredMessage(
        icon: _isFiltered ? Icons.filter_alt_off_outlined : Icons.history_rounded,
        text: _isFiltered ? l.auditEmptyFiltered : l.auditEmpty,
      );
    }

    // Welche Loeschungen wurden schon wiederhergestellt? Steht im
    // restore_content-Eintrag (extra.restored_action_id), sofern der geladen
    // ist, plus alles, was in dieser Sitzung hier passiert ist.
    final restoredIds = {
      ..._restoredHere,
      for (final e in _entries)
        if (e.type == ModerationActionType.restoreContent)
          ?(e.extra['restored_action_id'] as num?)?.toInt(),
    };

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () => _fetchFirstPage(fromRefresh: true),
      child: ListView.builder(
        controller: _scroll,
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 40),
        itemCount: _entries.length + 1, // +1 = Footer
        itemBuilder: (_, i) {
          if (i == _entries.length) return _buildFooter();
          final entry = _entries[i];
          return LogCard(
            key: ValueKey(entry.id),
            entry: entry,
            showTarget: true,
            onModeratorTap: _setModerator,
            onTargetTap: _setTarget,
            footer: _footerFor(entry, restoredIds),
          );
        },
      ),
    );
  }

  /// Unten in der Karte: Restore-Button, "Wiederhergestellt"-Badge oder nichts.
  Widget? _footerFor(ModerationLogEntry entry, Set<int> restoredIds) {
    if (entry.type?.isRemoval != true) return null;
    if (entry.restorable) {
      return _RestoreButton(
        busy: _restoring.contains(entry.id),
        onPressed: () => _restore(entry),
      );
    }
    if (restoredIds.contains(entry.id)) {
      return _RestoredBadge(label: context.l10n.auditRestored);
    }
    return null; // Frist abgelaufen o.ae. -> einfach kein Button
  }

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

// ── Kleine Bausteine (gleicher Look wie in ReportQueueView) ──────────────

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

/// Aktiver Namens-Filter: immer "ausgewaehlt"-Look, ✕ hebt ihn auf.
/// Der ganze Chip ist die Trefferflaeche, nicht nur das kleine ✕.
class _UserFilterChip extends StatelessWidget {
  final String label;
  final VoidCallback onClear;

  const _UserFilterChip({required this.label, required this.onClear});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onClear,
      child: Container(
        height: 32,
        padding: const EdgeInsets.only(left: 12, right: 8),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.35)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 4),
            Icon(Icons.close_rounded, size: 16, color: AppColors.primary),
          ],
        ),
      ),
    );
  }
}

final _green = Colors.green.shade700;

/// Volle Breite, gruen umrandet (Wiederherstellen ist die "gute" Aktion).
/// Waehrend des Requests Spinner statt Text, Breite bleibt gleich.
class _RestoreButton extends StatelessWidget {
  final bool busy;
  final VoidCallback onPressed;

  const _RestoreButton({required this.busy, required this.onPressed});

  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    height: 42,
    child: OutlinedButton.icon(
      onPressed: busy ? null : onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: _green,
        side: BorderSide(color: _green.withValues(alpha: 0.4)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(21)),
      ),
      icon: busy
          ? SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2, color: _green),
            )
          : const Icon(Icons.restore_rounded, size: 18),
      label: Text(
        context.l10n.auditRestore,
        style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700),
      ),
    ),
  );
}

class _RestoredBadge extends StatelessWidget {
  final String label;
  const _RestoredBadge({required this.label});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: _green.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.check_rounded, size: 14, color: _green),
        const SizedBox(width: 4),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: _green,
          ),
        ),
      ],
    ),
  );
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
          if (action != null) ...[const SizedBox(height: 8), action!],
        ],
      ),
    ),
  );
}

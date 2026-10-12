import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:ranked/moderation/role_sheet.dart';

import '../app_colors.dart';
import '../confirm_dialog.dart';
import '../l10n/app_localizations.dart';
import '../l10n/l10n.dart';
import '../net_image.dart';
import 'admin_user_detail.dart';
import 'moderation_api_service.dart';
import 'moderation_log_entry.dart';
import 'moderation_sheet_parts.dart';
import 'ban_sheet.dart';
import 'report_reason.dart';
import 'user_role.dart';

/// Moderations-Detail zu einem User (GET /admin/users/{id}): Profil,
/// Sperrstatus, Meldezahlen, letzte Massnahmen. Erreichbar aus der Queue
/// und ueber das Profil-Menue.
class UserDetailScreen extends StatefulWidget {
  final int userId;

  /// Schon bekannt (Queue/Profil) -> steht sofort im Header, auch beim Laden.
  final String? username;

  /// Rolle des Mods, der hier schaut (Ban-Sheet: 365/dauerhaft nur Admin).
  final UserRole myRole;

  const UserDetailScreen({
    super.key,
    required this.userId,
    required this.myRole,
    this.username,
  });

  @override
  State<UserDetailScreen> createState() => _UserDetailScreenState();
}

/// Was der Screen beim Zurueckgehen zurueckgibt, wenn sich der Sperrstatus
/// geaendert hat (sonst pop ohne Wert = null). bannedUntil null = entsperrt.
typedef BanChange = ({DateTime? bannedUntil});

class _UserDetailScreenState extends State<UserDetailScreen> {
  /// null = laedt gerade (Startwert -> erstes Frame zeigt den Spinner).
  UserDetailResult? _result;

  /// Sperren/Entsperren laeuft -> Buttons gesperrt.
  bool _busy = false;

  /// Wurde hier gesperrt/entsperrt? Dann bekommt die Queue beim Zurueckgehen
  /// den neuen Stand (siehe [_popResult]).
  bool _banChanged = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  /// Erst-Laden, "Erneut versuchen" und Pull-to-refresh.
  /// Schlaegt ein Refresh fehl, bleiben vorhandene Daten stehen (+ Snackbar).
  /// Forbidden/NotFound ersetzen sie dagegen: dann stimmen sie nicht mehr.
  Future<void> _load() async {
    // Retry nach Fehler -> Spinner statt Fehlermeldung.
    if (_result is UserDetailFailed) {
      setState(() {
        _result = null;
      });
    }

    final data = await ModerationApiService.getUserDetail(widget.userId);
    if (!mounted) return;

    if (data is UserDetailFailed && _result is UserDetailOk) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.userDetailLoadFailed)),
      );
    } else {
      setState(() {
        _result = data;
      });
    }
  }

  /// "Sperren": Ban-Sheet -> banUser -> bei Erfolg neu laden.
  /// Anders als in der Queue wird nichts lokal nachgerechnet: _load() holt
  /// den echten Stand, inkl. neuem Eintrag unter "Letzte Massnahmen".
  Future<void> _ban(AdminUserDetail detail) async {
    if (_busy) return; // Doppeltipp

    final selection = await showBanSheet(
      context,
      username: detail.username,
      isAdmin: widget.myRole.isAdmin,
      isBanned: detail.isBanned,
    );
    // Abgebrochen -> nichts tun. Danach ist selection nicht mehr nullable.
    if (selection == null || !mounted) return;

    setState(() => _busy = true);
    final result = await ModerationApiService.banUser(
      detail.id,
      days: selection.days,
      reason: selection.reason,
    );
    if (!mounted) return;

    if (result == ModerationResult.ok) {
      _banChanged = true;
      await _load();
      if (!mounted) return; // neues await -> neu pruefen
    }
    // Ausserhalb des if: auch nach Fehler wieder freigeben.
    setState(() => _busy = false);
    _showResult(
      result,
      okText: context.l10n.moderationUserBanned(detail.username),
    );
  }

  /// "Entsperren": Bestaetigen -> unbanUser -> bei Erfolg neu laden.
  Future<void> _unban(AdminUserDetail detail) async {
    if (_busy) return;

    final l = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => ConfirmDialog(
        icon: Icons.lock_open_rounded,
        title: l.moderationUnbanTitle(detail.username),
        message: l.moderationUnbanMessage,
        confirmLabel: l.moderationUnban,
      ),
    );
    // null (weggetippt) oder false (Abbrechen) -> nichts tun.
    if (confirmed != true || !mounted) return;

    setState(() => _busy = true);
    final result = await ModerationApiService.unbanUser(detail.id);
    if (!mounted) return;

    if (result == ModerationResult.ok) {
      _banChanged = true;
      await _load();
      if (!mounted) return;
    }
    setState(() => _busy = false);
    _showResult(
      result,
      okText: context.l10n.moderationUserUnbanned(detail.username),
    );
  }

  /// "Rolle aendern" (nur Admin): Rollen-Sheet -> changeRole -> neu laden.
  Future<void> _changeRole(AdminUserDetail detail) async {
    if (_busy) return; // Doppeltipp

    final selection = await showRoleSheet(
      context,
      username: detail.username,
      current: detail.role,
      isBanned: detail.isBanned,
    );
    if (!mounted || selection == null) return;

    setState(() => _busy = true);
    final result = await ModerationApiService.changeRole(
      detail.id,
      selection.role,
      reason: selection.reason,
    );
    if (!mounted) return;

    // Kein _banChanged: die Sperre bleibt, wie sie ist.
    if (result == ModerationResult.ok) {
      await _load();
      if (!mounted) return;
    }
    setState(() => _busy = false);
    final l = context.l10n;
    _showResult(
      result,
      okText: l.userDetailRoleChanged(detail.username, selection.role.label(l)),
    );
  }

  /// Snackbar je Ergebnis (gleiche Texte wie in der Queue).
  void _showResult(ModerationResult result, {required String okText}) {
    final l = context.l10n;
    final text = switch (result) {
      ModerationResult.ok => okText,
      ModerationResult.forbidden => l.moderationForbidden,
      ModerationResult.failed => l.moderationActionFailed,
    };
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  /// Rueckgabe an die Queue: null = nichts geaendert, sonst der Sperrstand
  /// aus den zuletzt geladenen Daten. Schlug das Neuladen nach dem Sperren
  /// fehl, ist das der alte Stand. Selten, und die Queue korrigiert sich
  /// beim naechsten Laden selbst.
  BanChange? _popResult() {
    final result = _result;
    if (!_banChanged || result is! UserDetailOk) return null;
    return (bannedUntil: result.detail.bannedUntil);
  }

  @override
  Widget build(BuildContext context) {
    // Header: bekannter Name > Name aus den Daten > "Account".
    final result = _result;
    final title =
        widget.username ??
        (result is UserDetailOk ? result.detail.username : null) ??
        context.l10n.userDetailTitle;

    // PopScope faengt JEDES Zurueck ab (Pfeil, System-Geste, Back-Taste)
    // und schickt das Ergebnis mit. canPop: false -> wir poppen selbst.
    return PopScope<BanChange>(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return; // war schon unser eigener pop unten
        Navigator.of(context).pop(_popResult());
      },
      child: Scaffold(
        backgroundColor: AppColors.surface,
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header (wie MyModerationScreen) ────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
                child: Row(
                  children: [
                    GestureDetector(
                      // maybePop -> laeuft durch PopScope, wie die System-Geste
                      onTap: () => Navigator.of(context).maybePop(),
                      behavior: HitTestBehavior.opaque,
                      child: Icon(
                        Icons.arrow_back,
                        color: AppColors.primary,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: AppColors.onSurface,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              Expanded(child: _buildBody()),
            ],
          ),
        ),
      ),
    );
  }

  /// Ein Zustand pro Fall von [UserDetailResult]. Der switch ist exhaustive:
  /// kommt ein neuer Fall dazu, meckert der Compiler hier.
  Widget _buildBody() {
    final l = context.l10n;

    return switch (_result) {
      null => Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
      UserDetailOk(:final detail) => RefreshIndicator(
        color: AppColors.primary,
        onRefresh: _load,
        child: ListView(
          // auch bei wenig Inhalt ziehbar, sonst kein Pull-to-refresh
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 40),
          children: [
            _Header(detail: detail),
            if (detail.isBanned) ...[
              const SizedBox(height: 16),
              _BanCard(
                detail: detail,
                onUnban: _busy ? null : () => _unban(detail),
              ),
            ],
            const SizedBox(height: 16),
            _StatsRow(detail: detail),
            // Gesperrt -> nur Entsperren (in der Karte), wie in der Queue.
            if (!detail.isBanned) ...[
              const SizedBox(height: 16),
              ModerationDangerButton(
                label: l.moderationBanConfirm,
                icon: Icons.block_rounded,
                onPressed: _busy ? null : () => _ban(detail),
              ),
            ],
            if (widget.myRole.isAdmin) ...[
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                height: 46,
                child: OutlinedButton.icon(
                  onPressed: _busy ? null : () => _changeRole(detail),
                  icon: const Icon(Icons.manage_accounts_outlined, size: 18),
                  label: Text(
                    l.userDetailChangeRole,
                    style: GoogleFonts.inter(fontWeight: FontWeight.w700),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: BorderSide(
                      color: AppColors.primary.withValues(alpha: 0.3),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 28),
            Text(
              l.userDetailRecentActions,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppColors.onSurface,
              ),
            ),
            const SizedBox(height: 12),
            if (detail.recentActions.isEmpty)
              Text(
                l.userDetailNoActions,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: AppColors.onSurfaceVariant,
                ),
              ),
            for (final entry in detail.recentActions) _LogCard(entry: entry),
          ],
        ),
      ),
      UserDetailForbidden() => _CenteredMessage(
        icon: Icons.lock_outline_rounded,
        text: l.userDetailForbidden,
      ),
      UserDetailNotFound() => _CenteredMessage(
        icon: Icons.person_off_outlined,
        text: l.userDetailNotFound,
      ),
      UserDetailFailed() => _CenteredMessage(
        icon: Icons.wifi_off_rounded,
        text: l.userDetailLoadFailed,
        action: TextButton(
          onPressed: _load,
          child: Text(
            l.moderationRetry,
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
        ),
      ),
    };
  }
}

// ── Ok-Zustand ───────────────────────────────────────────────────────────

/// Avatar, Name, Rolle, "Mitglied seit" und (falls vorhanden) die Bio.
class _Header extends StatelessWidget {
  final AdminUserDetail detail;
  const _Header({required this.detail});

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final url = detail.avatarUrl;
    final hasUrl = url != null && url.isNotEmpty;
    final bio = detail.biography?.trim();
    final roleLabel = detail.role.label(l);
    final since = DateFormat.yMMMd(l.localeName).format(detail.createdAt);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 64,
              height: 64,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.surfaceContainerHighest,
              ),
              child: hasUrl
                  ? Image(
                      image: netImage(context, url, logicalWidth: 64),
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => const _AvatarFallback(),
                    )
                  : const _AvatarFallback(),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    detail.username,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.onSurface,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      _Badge(roleLabel, color: AppColors.primary),
                      Text(
                        l.userDetailMemberSince(since),
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        if (bio != null && bio.isNotEmpty) ...[
          const SizedBox(height: 14),
          _TextBox(bio),
        ],
      ],
    );
  }
}

/// Rote Karte, nur wenn die Sperre gerade laeuft ([AdminUserDetail.isBanned]).
/// Unten "Entsperren"; onUnban null = gesperrt (laeuft gerade etwas).
class _BanCard extends StatelessWidget {
  final AdminUserDetail detail;
  final VoidCallback? onUnban;
  const _BanCard({required this.detail, required this.onUnban});

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final red = Colors.red.shade700;
    final reason = detail.banReason?.trim();
    final title = detail.isPermanentlyBanned
        ? l.moderationBannedPermanent
        : l.userDetailBannedUntil(
            DateFormat.yMMMd(l.localeName).add_jm().format(detail.bannedUntil!),
          );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: red.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: red.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.block_rounded, size: 20, color: red),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: red,
                  ),
                ),
              ),
            ],
          ),
          if (reason != null && reason.isNotEmpty) ...[
            const SizedBox(height: 12),
            _Label(l.accountStatusReasonLabel),
            const SizedBox(height: 6),
            _TextBox(reason),
          ],
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: OutlinedButton.icon(
              onPressed: onUnban,
              icon: const Icon(Icons.lock_open_rounded, size: 18),
              label: Text(
                l.moderationUnban,
                style: GoogleFonts.inter(fontWeight: FontWeight.w700),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: red,
                side: BorderSide(color: red.withValues(alpha: 0.4)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Zwei Kacheln: offene Meldungen (getoent, wenn > 0) und gesamt.
class _StatsRow extends StatelessWidget {
  final AdminUserDetail detail;
  const _StatsRow({required this.detail});

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Row(
      children: [
        Expanded(
          child: _StatTile(
            value: detail.reportsPending,
            label: l.userDetailReportsPending,
            highlight: detail.reportsPending > 0,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatTile(
            value: detail.reportsTotal,
            label: l.userDetailReportsTotal,
          ),
        ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  final int value;
  final String label;
  final bool highlight;
  const _StatTile({
    required this.value,
    required this.label,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    final accent = highlight ? Colors.orange.shade800 : AppColors.onSurface;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: highlight
            ? Colors.orange.shade800.withValues(alpha: 0.10)
            : AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.07)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$value',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: accent,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Letzte Massnahmen ────────────────────────────────────────────────────

/// Eine Zeile Audit-Log: was, wann, von wem, warum (+ Inhalt, falls noch da).
/// Unbekannter Typ -> "Unbekannte Aktion" statt wegfiltern.
class _LogCard extends StatelessWidget {
  final ModerationLogEntry entry;
  const _LogCard({required this.entry});

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final e = entry;
    final red = Colors.red.shade700;

    final (IconData icon, Color color, String title) = switch (e.type) {
      ModerationActionType.ban => (Icons.block_rounded, red, _banTitle(l, e)),
      ModerationActionType.unban => (
        Icons.lock_open_rounded,
        _green,
        l.userDetailLogUnban,
      ),
      ModerationActionType.resolve =>
        e.extra['status'] == 'dismissed'
            ? (
                Icons.do_not_disturb_alt_rounded,
                AppColors.primary,
                l.userDetailLogDismissed,
              )
            : (
                Icons.task_alt_rounded,
                AppColors.primary,
                l.userDetailLogResolved,
              ),
      ModerationActionType.roleChange => (
        Icons.manage_accounts_outlined,
        AppColors.primary,
        l.userDetailLogRoleChange(
          UserRole.fromApi(e.extra['old_role']).label(l),
          UserRole.fromApi(e.extra['new_role']).label(l),
        ),
      ),
      ModerationActionType.restoreContent => (
        Icons.restore_rounded,
        _green,
        l.userDetailLogRestored,
      ),
      ModerationActionType.deletePost => (
        Icons.article_outlined,
        red,
        l.accountStatusRemovedPost,
      ),
      ModerationActionType.deleteComment => (
        Icons.chat_bubble_outline_rounded,
        red,
        l.accountStatusRemovedComment,
      ),
      ModerationActionType.deleteStory => (
        Icons.amp_stories_outlined,
        red,
        l.accountStatusRemovedStory,
      ),
      ModerationActionType.deleteProfilePicture => (
        Icons.hide_image_outlined,
        red,
        l.accountStatusRemovedPicture,
      ),
      null => (
        Icons.help_outline_rounded,
        AppColors.onSurfaceVariant,
        l.userDetailLogUnknown,
      ),
    };

    final date = DateFormat.yMMMd(l.localeName).add_jm().format(e.createdAt);
    final mod = e.moderator;
    final by = mod == null
        ? l.userDetailLogDeletedModerator
        : l.userDetailLogBy(mod.username);

    // Grund: bei delete_* eine Kategorie -> Chip, sonst (Ban) Freitext.
    final reason = _nonEmpty(e.reason);
    final category = ReportReason.fromApi(e.reason);
    final details = _nonEmpty(e.extra['details'] as String?);
    final snapshot = _nonEmpty(e.contentSnapshot);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.07)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withValues(alpha: 0.12),
                ),
                child: Icon(icon, size: 20, color: color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$date · $by',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (category != null) ...[
            const SizedBox(height: 14),
            _Label(l.accountStatusReasonLabel),
            const SizedBox(height: 6),
            _Badge(category.label(l), color: AppColors.primary),
          ] else if (reason != null) ...[
            const SizedBox(height: 14),
            _Label(l.accountStatusReasonLabel),
            const SizedBox(height: 6),
            _TextBox(reason),
          ],
          if (details != null) ...[
            const SizedBox(height: 14),
            _Label(l.accountStatusNoteLabel),
            const SizedBox(height: 6),
            _TextBox(details),
          ],
          if (snapshot != null) ...[
            const SizedBox(height: 14),
            _Label(l.userDetailLogSnapshotLabel),
            const SizedBox(height: 6),
            _TextBox(snapshot, maxLines: 4),
          ],
        ],
      ),
    );
  }

  /// "Konto fuer 7 Tage gesperrt" / "dauerhaft". Fehlt `days` ganz (alte
  /// Eintraege), neutral "Konto gesperrt" statt faelschlich "dauerhaft".
  static String _banTitle(AppLocalizations l, ModerationLogEntry e) {
    if (!e.extra.containsKey('days')) return l.userDetailLogBan;
    final days = (e.extra['days'] as num?)?.toInt();
    return days == null
        ? l.accountStatusBannedPermanent
        : l.accountStatusBanned(days);
  }
}

// Gleiches Gruen wie im Kontostatus. AppColors hat keine Erfolgsfarbe.
final _green = Colors.green.shade700;

String? _nonEmpty(String? s) => (s == null || s.trim().isEmpty) ? null : s;

// ── Kleinteile (gleicher Look wie in MyModerationScreen) ─────────────────

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: GoogleFonts.inter(
      fontSize: 12,
      fontWeight: FontWeight.w700,
      color: AppColors.onSurfaceVariant,
    ),
  );
}

class _Badge extends StatelessWidget {
  final String text;
  final Color color;
  const _Badge(this.text, {required this.color});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Text(
      text,
      style: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: color,
      ),
    ),
  );
}

class _TextBox extends StatelessWidget {
  final String text;
  final int? maxLines;
  const _TextBox(this.text, {this.maxLines});

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: AppColors.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(14),
    ),
    child: Text(
      text,
      maxLines: maxLines,
      overflow: maxLines == null ? null : TextOverflow.ellipsis,
      style: GoogleFonts.inter(
        fontSize: 14,
        height: 1.4,
        color: AppColors.onSurface,
      ),
    ),
  );
}

class _AvatarFallback extends StatelessWidget {
  const _AvatarFallback();

  @override
  Widget build(BuildContext context) => Center(
    child: Icon(
      Icons.person_rounded,
      size: 30,
      color: AppColors.onSurfaceVariant,
    ),
  );
}

/// Icon + Text (+ optionaler Button) mittig. Gleicher Look wie in
/// MyModerationScreen (dort privat, deshalb eine eigene Kopie).
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

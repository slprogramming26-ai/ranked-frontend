import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../app_colors.dart';
import '../confirm_dialog.dart';
import '../l10n/l10n.dart';
import '../net_image.dart';
import '../post/widgets/collapse_out.dart';
import '../user_api_service.dart';

/// Ein Eintrag aus GET /users/blocked.
/// Backend-Felder: id, username, profile_picture_url (nullable),
/// blocked_at (ISO mit Zeitzone).
class BlockedUser {
  final int id;
  final String username;
  final String? pictureUrl; // Backend kann null liefern
  final DateTime blockedAt;

  const BlockedUser({
    required this.id,
    required this.username,
    required this.pictureUrl,
    required this.blockedAt,
  });

  factory BlockedUser.fromJson(Map<String, dynamic> json) => BlockedUser(
        id: json['id'] as int,
        username: json['username'] as String,
        pictureUrl: json['profile_picture_url'] as String?,
        // Server schickt UTC -> fuer "Blockiert am ..." in Ortszeit umrechnen.
        blockedAt: DateTime.parse(json['blocked_at'] as String).toLocal(),
      );
}

/// Settings -> Privatsphaere -> "Blockierte Konten".
/// Laedt GET /users/blocked und erlaubt das Aufheben pro Zeile.
class BlockedAccountsScreen extends StatefulWidget {
  const BlockedAccountsScreen({super.key});

  @override
  State<BlockedAccountsScreen> createState() => _BlockedAccountsScreenState();
}

class _BlockedAccountsScreenState extends State<BlockedAccountsScreen> {
  // Startwert true: schon das erste Frame zeigt den Spinner.
  bool _loading = true;
  bool _failed = false;
  List<BlockedUser>? _users;

  // ids, deren DELETE gerade laeuft -> Spinner im Button, Button gesperrt.
  final Set<int> _pending = {};
  // ids, die der Server schon entblockt hat -> CollapseOut klappt sie weg.
  final Set<int> _removing = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  /// getBlocks(): null = Fehler, [] = leer, sonst Liste.
  /// Wird auch vom "Erneut versuchen"-Button und Pull-to-refresh benutzt.
  Future<void> _load() async {
    // Beim ersten Aufruf aus initState ist das schon so; beim Retry setzt
    // es den Fehler-Zustand zurueck.
    if (_failed) {
      setState(() {
        _loading = true;
        _failed = false;
      });
    }

    final data = await UserApiService.getBlocks();
    if (!mounted) return;

    setState(() {
      _loading = false;
      if (data == null) {
        _failed = true;
      } else {
        _users = data.map(BlockedUser.fromJson).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header (wie _DsgvoScreen) ─────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    behavior: HitTestBehavior.opaque,
                    child: Icon(
                      Icons.arrow_back,
                      color: AppColors.primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    context.l10n.blockedTitle,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: AppColors.onSurface,
                      letterSpacing: -0.5,
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
    );
  }

  /// Vier Zustaende per fruehem Return, von oben nach unten.
  /// Wer unten ankommt, hat sicher Daten -> `_users!` ist dort sicher.
  Widget _buildBody() {
    if (_loading) {
      return Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    if (_failed) {
      return _CenteredMessage(
        icon: Icons.wifi_off_rounded,
        text: context.l10n.blockedLoadFailed,
        action: TextButton(
          onPressed: _load,
          child: Text(
            context.l10n.blockedRetry,
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
        ),
      );
    }

    final users = _users!;
    if (users.isEmpty) {
      return _CenteredMessage(
        icon: Icons.block_rounded,
        text: context.l10n.blockedEmpty,
      );
    }

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 40),
        itemCount: users.length,
        itemBuilder: (_, i) {
          final user = users[i];
          // ValueKey(id): Beim Entfernen rutscht die naechste Zeile auf
          // diesen Index. Ohne Key wuerde sie den State (die laufende
          // Collapse-Animation) der alten Zeile erben.
          return CollapseOut(
            key: ValueKey(user.id),
            collapsed: _removing.contains(user.id),
            onCollapsed: () {
              // Kann einen Frame spaeter aus dispose() kommen (siehe
              // CollapseOut-Doku) -> Screen evtl. schon weg.
              if (!mounted) return;
              setState(() {
                _users!.remove(user);
                _removing.remove(user.id);
              });
            },
            child: _BlockedRow(
              user: user,
              busy: _pending.contains(user.id),
              onUnblock: () => _unblock(user),
            ),
          );
        },
      ),
    );
  }

  /// "Aufheben" angetippt: erst fragen, dann DELETE, erst nach Server-OK
  /// wegklappen.
  Future<void> _unblock(BlockedUser user) async {
    final l = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => ConfirmDialog(
        icon: Icons.block_rounded,
        title: l.blockedUnblockTitle(user.username),
        message: l.blockedUnblockMessage(user.username),
        confirmLabel: l.blockedUnblock,
      ),
    );
    // null (Dialog weggetippt) oder false (Abbrechen) -> nichts tun.
    if (confirmed != true || !mounted) return;

    setState(() => _pending.add(user.id));
    final ok = await UserApiService.deleteBlock(user.id);
    if (!mounted) return;

    setState(() {
      _pending.remove(user.id);
      if (ok) _removing.add(user.id); // CollapseOut startet
    });
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(
        ok ? l.blockedUnblocked(user.username) : l.blockedUnblockFailed,
      ),
    ));
  }
}

/// Eine Zeile: Avatar, Username, "Blockiert am ...", Pill-Button "Aufheben".
/// Rein darstellend. Den Zustand (busy) und die Aktion bekommt sie von aussen.
class _BlockedRow extends StatelessWidget {
  final BlockedUser user;
  final bool busy;
  final VoidCallback onUnblock;

  const _BlockedRow({
    required this.user,
    required this.busy,
    required this.onUnblock,
  });

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    // Datum im Format der App-Sprache: "6. Okt. 2026" / "Oct 6, 2026".
    final date = DateFormat.yMMMd(l.localeName).format(user.blockedAt);
    final url = user.pictureUrl;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.surfaceContainerHighest,
            ),
            child: (url != null && url.isNotEmpty)
                ? Image(
                    image: netImage(context, url, logicalWidth: 44),
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => const _AvatarFallback(),
                  )
                : const _AvatarFallback(),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.username,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  l.blockedSince(date),
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Pill-Button. Waehrend busy: Spinner statt Text und kein onTap.
          // Die feste Mindestbreite verhindert, dass der Button beim
          // Umschalten auf den Spinner schrumpft.
          GestureDetector(
            onTap: busy ? null : onUnblock,
            child: Container(
              constraints: const BoxConstraints(minWidth: 92),
              height: 34,
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(17),
              ),
              child: busy
                  ? SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.primary,
                      ),
                    )
                  : Text(
                      l.blockedUnblock,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.onSurface,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AvatarFallback extends StatelessWidget {
  const _AvatarFallback();

  @override
  Widget build(BuildContext context) => Center(
        child: Icon(
          Icons.person_rounded,
          size: 24,
          color: AppColors.onSurfaceVariant,
        ),
      );
}

/// Icon + Text (+ optionaler Button) mittig — fuer Fehler- und Leer-Ansicht.
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

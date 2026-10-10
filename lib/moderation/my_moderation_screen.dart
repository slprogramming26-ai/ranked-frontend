import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../app_colors.dart';
import '../l10n/l10n.dart';
import 'moderation_api_service.dart';
import 'my_moderation_action.dart';
import 'report_reason.dart';

/// Settings -> Account -> "Kontostatus": Massnahmen gegen mich
/// (GET /users/moderation). Nur lesen, keine Aktionen (Widerspruch kommt spaeter).
class MyModerationScreen extends StatefulWidget {
  const MyModerationScreen({super.key});

  @override
  State<MyModerationScreen> createState() => _MyModerationScreenState();
}

class _MyModerationScreenState extends State<MyModerationScreen> {
  // Startwert true: schon das erste Frame zeigt den Spinner.
  bool _loading = true;
  bool _failed = false;
  List<MyModerationAction>? _actions;

  @override
  void initState() {
    super.initState();
    _load();
  }

  /// Erst-Laden, "Erneut versuchen" und Pull-to-refresh.
  /// Schlaegt ein Refresh fehl, bleibt die alte Liste stehen (+ Snackbar).
  Future<void> _load() async {
    if (_failed) {
      setState(() {
        _loading = true;
        _failed = false;
      });
    }

    final data = await ModerationApiService.getMyActions();
    if (!mounted) return;

    final keepOldList = data == null && _actions != null;
    setState(() {
      _loading = false;
      if (data != null) {
        _actions = data;
      } else if (!keepOldList) {
        _failed = true;
      }
    });
    if (keepOldList) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.accountStatusLoadFailed)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header (wie BlockedAccountsScreen) ─────────────────────────
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
                    context.l10n.accountStatusTitle,
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

  /// Vier Zustaende per fruehem Return, wie in BlockedAccountsScreen.
  Widget _buildBody() {
    final l = context.l10n;

    if (_loading) {
      return Center(child: CircularProgressIndicator(color: AppColors.primary));
    }

    if (_failed) {
      return _CenteredMessage(
        icon: Icons.wifi_off_rounded,
        text: l.accountStatusLoadFailed,
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
      );
    }

    final actions = _actions!;
    if (actions.isEmpty) {
      return _CenteredMessage(
        icon: Icons.verified_user_outlined,
        text: l.accountStatusEmpty,
      );
    }

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 40),
        itemCount: actions.length,
        itemBuilder: (_, i) => _ActionCard(action: actions[i]),
      ),
    );
  }
}

// ── Karte ────────────────────────────────────────────────────────────────

/// Ein Eintrag: was, wann, warum, und (falls noch da) wie der Inhalt aussah.
class _ActionCard extends StatelessWidget {
  final MyModerationAction action;
  const _ActionCard({required this.action});

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final a = action;
    final days = a.banDays;

    final (IconData icon, String title) = switch (a.kind) {
      MyActionKind.ban => (
          Icons.block_rounded,
          days == null
              ? l.accountStatusBannedPermanent
              : l.accountStatusBanned(days),
        ),
      MyActionKind.deletePost => (
          Icons.article_outlined,
          l.accountStatusRemovedPost
        ),
      MyActionKind.deleteComment => (
          Icons.chat_bubble_outline_rounded,
          l.accountStatusRemovedComment
        ),
      MyActionKind.deleteStory => (
          Icons.amp_stories_outlined,
          l.accountStatusRemovedStory
        ),
      MyActionKind.deleteProfilePicture => (
          Icons.hide_image_outlined,
          l.accountStatusRemovedPicture
        ),
    };
    // Wiederhergestellt = gruen, sonst rot (wie Sperren/Entfernen in der Queue).
    final color = a.restored ? _green : Colors.red.shade700;
    // "10. Okt. 2026" / "Oct 10, 2026"
    final date = DateFormat.yMMMd(l.localeName).format(a.createdAt);

    // Leere Strings wie null behandeln (dann faellt der Abschnitt weg).
    final reason = _nonEmpty(a.reason);
    final details = _nonEmpty(a.details);
    final snapshot = _nonEmpty(a.contentSnapshot);
    final category = a.reasonCategory;

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
          // ── Kopf: Icon, Titel, Datum (+ Badge) ──
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
                    Row(
                      children: [
                        Text(
                          date,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                        if (a.restored) ...[
                          const SizedBox(width: 8),
                          _Badge(l.accountStatusRestored, color: _green),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          // ── Grund: Kategorie-Chip (Entfernen) bzw. Freitext (Sperre) ──
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
            _Label(l.accountStatusSnapshotLabel),
            const SizedBox(height: 6),
            _TextBox(snapshot, maxLines: 4),
          ],
        ],
      ),
    );
  }
}

// Gleiches Gruen fuer Icon + Badge. AppColors hat keine Erfolgsfarbe.
final _green = Colors.green.shade700;

String? _nonEmpty(String? s) => (s == null || s.trim().isEmpty) ? null : s;

/// Kleine Ueberschrift ueber einem Abschnitt der Karte.
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

/// Getoente Pille: Grund-Kategorie oder "Wiederhergestellt".
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

/// Grauer Kasten fuer Freitexte (Begruendung, Hinweis, Inhalt).
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

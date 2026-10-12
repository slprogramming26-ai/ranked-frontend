import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../app_colors.dart';
import '../l10n/l10n.dart';
import '../net_image.dart';
import 'report_queue_item.dart';
import 'report_reason.dart';
import 'report_target.dart';

/// Die zwei Buttons einer Karte. Die Queue merkt sich pro Karte, welcher
/// davon gerade auf den Server wartet (Spinner). act = alles, was ueber das
/// Massnahmen-Sheet laeuft (Entfernen, Sperren, Entsperren, Erledigt).
enum ReportCardAction { dismiss, act }

/// Eine Karte in der Report-Queue: wer, was, wie oft gemeldet.
/// Rein darstellend: Was beim Tippen passiert, entscheidet die Queue-View.
/// Sind beide Callbacks null, gibt es keine Button-Zeile.
class ReportCard extends StatelessWidget {
  final ReportQueueItem item;

  /// Stufe 1: "Keine Massnahme" (= Ablehnen) bzw. "Massnahme ergreifen"
  /// (oeffnet in der Queue das Sheet mit Stufe 2).
  final VoidCallback? onDismiss;
  final VoidCallback? onTakeAction;

  /// Welcher Button gerade auf den Server wartet (Spinner), sonst null.
  /// Solange etwas laeuft, sind BEIDE Buttons gesperrt.
  final ReportCardAction? busyAction;

  /// Tipp auf den Kopf (Avatar + Name) -> User-Detail. null = nicht tippbar.
  final VoidCallback? onOpenUser;

  const ReportCard({
    super.key,
    required this.item,
    this.onDismiss,
    this.onTakeAction,
    this.busyAction,
    this.onOpenUser,
  });

  /// Ein Button der Karte. Laeuft irgendeine Aktion, ist er gesperrt (onTap
  /// null), der laufende zeigt den Spinner.
  Widget _button(
    String label,
    ReportCardAction action,
    VoidCallback onTap,
    _ButtonStyle style,
  ) =>
      Expanded(
        child: _ActionButton(
          label: label,
          style: style,
          loading: busyAction == action,
          onTap: busyAction == null ? onTap : null,
        ),
      );

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    // Lokale Kopien: Felder promoten nicht, lokale finals schon.
    final dismiss = onDismiss, act = onTakeAction;

    final buttons = [
      if (dismiss != null)
        _button(l.moderationDismiss, ReportCardAction.dismiss, dismiss,
            _ButtonStyle.neutral),
      if (act != null)
        _button(l.moderationTakeAction, ReportCardAction.act, act,
            _ButtonStyle.primary),
    ];

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
          _Header(item: item, onTap: onOpenUser),
          const SizedBox(height: 14),
          _PreviewSection(item: item),
          if (item.reasons.isNotEmpty) ...[
            const SizedBox(height: 14),
            _ReasonChips(reasons: item.reasons),
          ],
          if (item.details.isNotEmpty) ...[
            const SizedBox(height: 6),
            _DetailsSection(details: item.details),
          ],
          if (buttons.isNotEmpty) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                for (var i = 0; i < buttons.length; i++) ...[
                  if (i > 0) const SizedBox(width: 10),
                  buttons[i],
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// ── Kopf: Avatar mit Typ-Badge, Username, Gesperrt-Badge, Anzahl + Datum ──

class _Header extends StatelessWidget {
  final ReportQueueItem item;
  final VoidCallback? onTap;
  const _Header({required this.item, this.onTap});

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final user = item.user;
    // "8. Okt., 14:02" / "Oct 8, 2:02 PM"
    final last =
        DateFormat.MMMd(l.localeName).add_jm().format(item.lastReportedAt);

    final row = Row(
      children: [
        _AvatarWithType(url: user.avatarUrl, target: item.target),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      user.username,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.onSurface,
                      ),
                    ),
                  ),
                  if (user.isBanned) ...[
                    const SizedBox(width: 8),
                    _BannedBadge(permanent: user.isPermanentlyBanned),
                  ],
                ],
              ),
              const SizedBox(height: 2),
              Text(
                '${l.moderationReportCount(item.count)} · '
                '${l.moderationLastReported(last)}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: AppColors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        // Pfeil zeigt: der Kopf fuehrt zum User-Detail.
        if (onTap != null)
          Icon(
            Icons.chevron_right_rounded,
            color: AppColors.onSurfaceVariant,
          ),
      ],
    );

    if (onTap == null) return row;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: row,
    );
  }
}

class _AvatarWithType extends StatelessWidget {
  final String? url;
  final ReportTarget target;
  const _AvatarWithType({required this.url, required this.target});

  @override
  Widget build(BuildContext context) {
    final icon = switch (target) {
      ReportTarget.post => Icons.article_outlined,
      ReportTarget.comment => Icons.chat_bubble_outline_rounded,
      ReportTarget.story => Icons.amp_stories_outlined,
      ReportTarget.user => Icons.person_outline_rounded,
    };
    final hasUrl = url != null && url!.isNotEmpty;

    return SizedBox(
      width: 46,
      height: 46,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 42,
            height: 42,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.surfaceContainerHighest,
            ),
            child: hasUrl
                ? Image(
                    image: netImage(context, url!, logicalWidth: 42),
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => const _AvatarFallback(),
                  )
                : const _AvatarFallback(),
          ),
          // Kleines Typ-Badge unten rechts: Post / Kommentar / Story / User.
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary,
                border: Border.all(
                  color: AppColors.surfaceContainerLow,
                  width: 2,
                ),
              ),
              child: Icon(icon, size: 12, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

class _BannedBadge extends StatelessWidget {
  final bool permanent;
  const _BannedBadge({required this.permanent});

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final color = Colors.red.shade700;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        permanent ? l.moderationBannedPermanent : l.moderationBanned,
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

// ── Inhalt: was gemeldet wurde ───────────────────────────────────────────

class _PreviewSection extends StatelessWidget {
  final ReportQueueItem item;
  const _PreviewSection({required this.item});

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final preview = item.preview;

    // Geloescht: Hinweis + Text-Kopie vom Melden (bei Storys gibt es keine).
    if (item.contentDeleted) {
      return _InfoBox(
        icon: Icons.delete_outline_rounded,
        label: l.moderationContentDeleted,
        text: preview?.content,
      );
    }

    // "" gleich zu null machen: Dann reicht ueberall ein "!= null", und Dart
    // promoted die lokalen finals danach zu String. (Ein extra
    // "final hasX = x != null" wuerde NICHT promoten.)
    final title = _nonEmpty(preview?.title);
    final content = _nonEmpty(preview?.content);
    final image = _nonEmpty(preview?.imageUrl);

    // Keine Preview ODER alle Felder leer (z.B. User ohne Bild und Bio).
    if (title == null && content == null && image == null) {
      return _InfoBox(
        icon: Icons.visibility_off_outlined,
        label: l.moderationNoPreview,
      );
    }

    return switch (item.target) {
      // Story: hochkantes Vorschaubild, wie im Viewer. Ohne Bild bleibt nur
      // Text, und den gibt es bei Storys nicht -> oben schon abgefangen.
      ReportTarget.story => image != null
          ? _PreviewImage(url: image, width: 110, aspectRatio: 9 / 16)
          : _BodyText(content ?? title ?? ''),

      // User: gemeldet wird das Profil, also Profilbild gross + Bio.
      ReportTarget.user => Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (image != null) ...[
              _PreviewImage(url: image, width: 88, aspectRatio: 1),
              const SizedBox(width: 12),
            ],
            if (content != null) Expanded(child: _BodyText(content)),
          ],
        ),

      // Post + Kommentar: Text (Titel fett) und ggf. Bild darunter.
      ReportTarget.post || ReportTarget.comment => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (title != null) ...[
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.onSurface,
                ),
              ),
              const SizedBox(height: 4),
            ],
            if (content != null) _BodyText(content),
            if (image != null) ...[
              const SizedBox(height: 10),
              _PreviewImage(url: image, aspectRatio: 4 / 3),
            ],
          ],
        ),
    };
  }
}

String? _nonEmpty(String? s) => (s == null || s.trim().isEmpty) ? null : s;

class _BodyText extends StatelessWidget {
  final String text;
  const _BodyText(this.text);

  @override
  Widget build(BuildContext context) => Text(
        text,
        maxLines: 6,
        overflow: TextOverflow.ellipsis,
        style: GoogleFonts.inter(
          fontSize: 14,
          height: 1.4,
          color: AppColors.onSurface,
        ),
      );
}

/// Bild mit runden Ecken. Ohne [width] nimmt es die volle Kartenbreite.
class _PreviewImage extends StatelessWidget {
  final String url;
  final double? width;
  final double aspectRatio;

  const _PreviewImage({required this.url, this.width, required this.aspectRatio});

  @override
  Widget build(BuildContext context) {
    // Fuer die Decode-Groesse reicht eine Schaetzung: volle Bildschirmbreite.
    final logicalWidth = width ?? MediaQuery.sizeOf(context).width;
    return SizedBox(
      width: width,
      child: AspectRatio(
        aspectRatio: aspectRatio,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Container(
            color: AppColors.surfaceContainerHighest,
            child: Image(
              image: netImage(context, url, logicalWidth: logicalWidth),
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => Center(
                child: Icon(
                  Icons.broken_image_outlined,
                  color: AppColors.onSurfaceVariant,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Grauer Kasten mit Icon + Hinweis, darunter optional ein Text.
class _InfoBox extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? text;

  const _InfoBox({required this.icon, required this.label, this.text});

  @override
  Widget build(BuildContext context) {
    final t = text;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: AppColors.onSurfaceVariant),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
          if (t != null && t.isNotEmpty) ...[
            const SizedBox(height: 8),
            _BodyText(t),
          ],
        ],
      ),
    );
  }
}

// ── Gruende + Anmerkungen der Melder ─────────────────────────────────────

class _ReasonChips extends StatelessWidget {
  final Map<ReportReason, int> reasons;
  const _ReasonChips({required this.reasons});

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    // Haeufigster Grund zuerst. Kopie per toList(), die Map bleibt unberuehrt.
    final sorted = reasons.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // Wrap statt Row: Lange Labels ("Belaestigung oder Mobbing") brechen
    // in die naechste Zeile um statt ueberzulaufen.
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        for (final e in sorted)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${e.key.label(l)} · ${e.value}',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
          ),
      ],
    );
  }
}

/// "N Anmerkungen anzeigen" -> klappt die Freitexte der Melder auf.
/// Stateful nur fuer das eine bool. Scrollt die Karte aus dem Bild, entsorgt
/// ListView.builder sie, und sie ist beim Zurueckscrollen wieder zu (gewollt).
class _DetailsSection extends StatefulWidget {
  final List<String> details;
  const _DetailsSection({required this.details});

  @override
  State<_DetailsSection> createState() => _DetailsSectionState();
}

class _DetailsSectionState extends State<_DetailsSection> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          behavior: HitTestBehavior.opaque, // auch Luecken im Row antippbar
          onTap: () => setState(() => _open = !_open),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _open
                      ? l.moderationHideDetails
                      : l.moderationShowDetails(widget.details.length),
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(width: 2),
                AnimatedRotation(
                  turns: _open ? 0.5 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    Icons.expand_more_rounded,
                    size: 20,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
        // AnimatedSize animiert die Hoehe zwischen "nichts" und der Liste.
        // alignment topCenter: waechst nach unten statt aus der Mitte.
        AnimatedSize(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          alignment: Alignment.topCenter,
          child: _open
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final d in widget.details)
                      Container(
                        margin: const EdgeInsets.only(top: 6),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          d,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            height: 1.4,
                            color: AppColors.onSurface,
                          ),
                        ),
                      ),
                  ],
                )
              : const SizedBox(width: double.infinity),
        ),
      ],
    );
  }
}

// ── Buttons ──────────────────────────────────────────────────────────────

/// neutral = grau (Keine Massnahme), primary = lila (Massnahme ergreifen).
enum _ButtonStyle { neutral, primary }

/// Pill-Button in einem der zwei Stile.
/// [onTap] null = gesperrt (halb transparent), [loading] = Spinner statt Text.
class _ActionButton extends StatelessWidget {
  final String label;
  final _ButtonStyle style;
  final bool loading;
  final VoidCallback? onTap;

  const _ActionButton({
    required this.label,
    required this.style,
    required this.loading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = switch (style) {
      _ButtonStyle.neutral => (
          AppColors.surfaceContainerHighest,
          AppColors.onSurface
        ),
      _ButtonStyle.primary => (AppColors.primary, Colors.white),
    };
    // Der ladende Button bleibt voll sichtbar, nur die ANDEREN werden blass.
    final dimmed = onTap == null && !loading;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 150),
        opacity: dimmed ? 0.45 : 1,
        child: Container(
          height: 40,
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(20),
          ),
          child: loading
              ? SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: fg),
                )
              // scaleDown: Wird ein Label (andere Sprache, grosse
              // Systemschrift) zu breit, schrumpft es statt anzustossen.
              : FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    label,
                    maxLines: 1,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: fg,
                    ),
                  ),
                ),
        ),
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
          size: 22,
          color: AppColors.onSurfaceVariant,
        ),
      );
}

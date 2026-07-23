import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// Gemeinsamer Baustein fuer alle blockierenden Ladezustaende der App
/// (Post-Upload, Onboarding-Abschluss, Story-Editor oeffnen). Jede Stelle
/// haengt ihn in eine andere Huelle (Dialog vs. Vollflaechen-Overlay), aber
/// Spinner-Optik und Typografie bleiben ueberall gleich.

class AppLoadingSpinner extends StatelessWidget {
  final double size;
  final Color? color;
  final Color? trackColor;

  const AppLoadingSpinner({
    super.key,
    this.size = 64,
    this.color,
    this.trackColor,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CircularProgressIndicator(
        strokeWidth: size / 13,
        color: color ?? AppColors.primary,
        backgroundColor: trackColor ?? AppColors.surfaceContainer,
      ),
    );
  }
}

TextStyle appLoadingTitleStyle({Color? color}) => GoogleFonts.plusJakartaSans(
  fontSize: 18,
  fontWeight: FontWeight.w800,
  color: color ?? AppColors.onSurface,
  letterSpacing: -0.3,
);

TextStyle appLoadingMessageStyle({Color? color}) => GoogleFonts.plusJakartaSans(
  fontSize: 14,
  fontWeight: FontWeight.w600,
  color: color ?? AppColors.onSurfaceVariant,
);

/// Wechselt zyklisch durch [messages] (fuer Vorgaenge mit mehreren
/// Teilschritten, z.B. Upload -> Erstellen -> Fertig). Bei nur einer
/// Nachricht bleibt der Text einfach stehen, kein Timer noetig.
class AppLoadingMessageCycle extends StatefulWidget {
  final List<String> messages;
  final TextStyle? style;
  final Duration interval;

  const AppLoadingMessageCycle({
    super.key,
    required this.messages,
    this.style,
    this.interval = const Duration(milliseconds: 1800),
  });

  @override
  State<AppLoadingMessageCycle> createState() => _AppLoadingMessageCycleState();
}

class _AppLoadingMessageCycleState extends State<AppLoadingMessageCycle> {
  int _index = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    if (widget.messages.length > 1) {
      _timer = Timer.periodic(widget.interval, (_) {
        setState(() => _index = (_index + 1) % widget.messages.length);
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      child: Text(
        widget.messages[_index],
        key: ValueKey(_index),
        style: widget.style ?? appLoadingMessageStyle(),
      ),
    );
  }
}

/// Lade-Dialog mit Scrim + Karte, fuer Vorgaenge bei denen die Seite
/// dahinter sichtbar bleiben soll (z.B. Post-Vorschau waehrend des Uploads).
class AppLoadingDialog extends StatelessWidget {
  final String title;
  final List<String> messages;
  // Platz fuer eine Aufrufer-eigene Verzierung unter dem Text (z.B. die
  // huepfenden Punkte beim Post-Upload) - der Rest bleibt ueberall gleich.
  final Widget? trailing;

  const AppLoadingDialog({
    super.key,
    required this.title,
    required this.messages,
    this.trailing,
  });

  static void show(
    BuildContext context, {
    required String title,
    required List<String> messages,
    Widget? trailing,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: AppColors.onSurface.withValues(alpha: 0.55),
      builder: (context) => AppLoadingDialog(
        title: title,
        messages: messages,
        trailing: trailing,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Container(
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(28),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const AppLoadingSpinner(size: 80),
            const SizedBox(height: 24),
            Text(title, style: appLoadingTitleStyle()),
            const SizedBox(height: 6),
            AppLoadingMessageCycle(messages: messages),
            if (trailing != null) ...[const SizedBox(height: 20), trailing!],
          ],
        ),
      ),
    );
  }
}

/// Vollflaechiges dunkles Ladeoverlay, fuer Vorgaenge ohne fertige Seite
/// im Hintergrund (Story-Editor oeffnen) oder mit mehreren Teilschritten
/// vor einer Navigation (Onboarding-Abschluss). Erwartet einen Stack als
/// Elternwidget (legt sich per Positioned.fill drueber).
class AppLoadingOverlay extends StatelessWidget {
  final String? title;
  final List<String> messages;

  const AppLoadingOverlay({super.key, this.title, required this.messages});

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      // Material statt ColoredBox: liegt im Stack ohne Material-Vorfahr,
      // sonst rendert Text im gelb unterstrichenen Fallback-Stil.
      child: Material(
        color: Colors.black.withValues(alpha: 0.75),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppLoadingSpinner(
                size: 64,
                trackColor: Colors.white.withValues(alpha: 0.15),
              ),
              const SizedBox(height: 20),
              if (title != null) ...[
                Text(title!, style: appLoadingTitleStyle(color: Colors.white)),
                const SizedBox(height: 6),
              ],
              AppLoadingMessageCycle(
                messages: messages,
                style: appLoadingMessageStyle(color: Colors.white70),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Dialoge fuer die seltenen Faelle, in denen das Chat-Backup beim Login nicht
// still wiederhergestellt werden kann (siehe KeySetup / docs/E2EE.md).
// Optik bewusst wie der Login-Screen: gefuellte Felder, Gradient-Button.

import 'package:flutter/material.dart';

import 'app_colors.dart';

// Ergebnis des Passwort-Dialogs: entweder ein Passwort zum erneuten Versuchen
// oder der Wunsch, die Chats zurueckzusetzen. null (Dialog weg) = Abbruch.
class BackupPasswordChoice {
  final String? password;
  const BackupPasswordChoice.retry(String this.password);
  const BackupPasswordChoice.reset() : password = null;
  bool get isReset => password == null;
}

// Backup passt nicht zum Login-Passwort (Passwort woanders geaendert oder
// eigenes Backup-Passwort). [wrongAttempt] = der letzte Versuch war falsch.
Future<BackupPasswordChoice?> showBackupPasswordDialog(
  BuildContext context, {
  required bool wrongAttempt,
}) {
  return showDialog<BackupPasswordChoice>(
    context: context,
    barrierDismissible: false,
    builder: (_) => _BackupPasswordDialog(wrongAttempt: wrongAttempt),
  );
}

class _BackupPasswordDialog extends StatefulWidget {
  final bool wrongAttempt;
  const _BackupPasswordDialog({required this.wrongAttempt});

  @override
  State<_BackupPasswordDialog> createState() => _BackupPasswordDialogState();
}

class _BackupPasswordDialogState extends State<_BackupPasswordDialog> {
  final _controller = TextEditingController();
  bool _obscure = true;

  @override
  void initState() {
    super.initState();
    // Button erst aktiv, wenn etwas eingegeben ist.
    _controller.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    // Kein trim — muss exakt das Passwort sein, mit dem verpackt wurde.
    if (_controller.text.isEmpty) return;
    Navigator.pop(context, BackupPasswordChoice.retry(_controller.text));
  }

  @override
  Widget build(BuildContext context) {
    return _DialogShell(
      children: [
        _IconBadge(
          icon: Icons.lock_reset_rounded,
          gradient: [AppColors.primary, AppColors.primaryContainer],
          iconColor: Colors.white,
        ),
        const SizedBox(height: 20),
        const _DialogTitle('Chats wiederherstellen'),
        const SizedBox(height: 10),
        const _DialogBody(
          'Deine Chats wurden mit einem anderen Passwort gesichert. '
          'Gib dein vorheriges Passwort ein, um sie wiederherzustellen.',
        ),
        const SizedBox(height: 28),
        const _FieldLabel('Vorheriges Passwort'),
        TextField(
          controller: _controller,
          obscureText: _obscure,
          autofocus: true,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _submit(),
          style: TextStyle(color: AppColors.onSurface),
          decoration: InputDecoration(
            prefixIcon: Icon(
              Icons.lock,
              color: AppColors.onSurfaceVariant.withValues(alpha: 0.5),
            ),
            suffixIcon: IconButton(
              onPressed: () => setState(() => _obscure = !_obscure),
              icon: Icon(
                _obscure
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                color: AppColors.onSurfaceVariant.withValues(alpha: 0.6),
              ),
            ),
            hintText: '••••••••',
            hintStyle: TextStyle(
              color: AppColors.onSurface.withValues(alpha: 0.3),
            ),
            filled: true,
            fillColor: AppColors.surfaceContainerHighest.withValues(alpha: 0.3),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: BorderSide.none,
            ),
            // Falscher Versuch: roter Rahmen statt nur roter Zeile.
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: widget.wrongAttempt
                  ? const BorderSide(color: Colors.redAccent, width: 1.5)
                  : BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: BorderSide(
                color: widget.wrongAttempt
                    ? Colors.redAccent
                    : AppColors.primary.withValues(alpha: 0.6),
                width: 1.5,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(vertical: 18),
          ),
        ),
        if (widget.wrongAttempt)
          Padding(
            padding: const EdgeInsets.only(left: 4, top: 8),
            child: Row(
              children: const [
                Icon(Icons.error_outline, size: 16, color: Colors.redAccent),
                SizedBox(width: 6),
                Text(
                  'Das Passwort passt nicht. Versuch es nochmal.',
                  style: TextStyle(
                    color: Colors.redAccent,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 24),
        _GradientButton(
          label: 'Wiederherstellen',
          onPressed: _controller.text.isEmpty ? null : _submit,
        ),
        const SizedBox(height: 4),
        _SecondaryButton(
          label: 'Abbrechen',
          onPressed: () => Navigator.pop(context),
        ),
        const SizedBox(height: 12),
        Divider(color: AppColors.onSurface.withValues(alpha: 0.08)),
        const SizedBox(height: 4),
        // Notausgang bewusst klein und unten — nicht der empfohlene Weg.
        Center(
          child: TextButton.icon(
            onPressed: () =>
                Navigator.pop(context, const BackupPasswordChoice.reset()),
            icon: Icon(
              Icons.restart_alt_rounded,
              size: 18,
              color: AppColors.onSurfaceVariant,
            ),
            label: Text(
              'Passwort vergessen? Chats zurücksetzen',
              style: TextStyle(
                color: AppColors.onSurfaceVariant,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// Bestaetigung fuer den Notausgang. true = wirklich zuruecksetzen.
// Bewusst deutlich formuliert: danach sind die alten Nachrichten weg.
Future<bool> showResetChatsDialog(BuildContext context) async {
  final confirmed = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) => _DialogShell(
      children: [
        _IconBadge(
          icon: Icons.warning_amber_rounded,
          gradient: [
            Colors.redAccent.withValues(alpha: 0.15),
            Colors.redAccent.withValues(alpha: 0.15),
          ],
          iconColor: Colors.redAccent,
        ),
        const SizedBox(height: 20),
        const _DialogTitle('Chats zurücksetzen?'),
        const SizedBox(height: 10),
        const _DialogBody(
          'Das lässt sich nicht rückgängig machen. Bitte lies kurz, '
          'was passiert:',
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerHighest.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Column(
            children: [
              _ConsequenceRow(
                icon: Icons.lock_outline,
                color: Colors.redAccent,
                text: 'Deine bisherigen Nachrichten sind auf allen Geräten '
                    'nicht mehr lesbar.',
              ),
              SizedBox(height: 14),
              _ConsequenceRow(
                icon: Icons.devices_outlined,
                color: Colors.redAccent,
                text: 'Andere angemeldete Geräte werden abgemeldet.',
              ),
              SizedBox(height: 14),
              _ConsequenceRow(
                icon: Icons.check_circle_outline,
                color: Colors.green,
                text: 'Neue Chats funktionieren ganz normal.',
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        _DangerButton(
          label: 'Chats zurücksetzen',
          onPressed: () => Navigator.pop(dialogContext, true),
        ),
        const SizedBox(height: 4),
        _SecondaryButton(
          label: 'Abbrechen',
          onPressed: () => Navigator.pop(dialogContext, false),
        ),
      ],
    ),
  );
  return confirmed ?? false;
}

// --- gemeinsame Bausteine ---------------------------------------------------

// Rahmen beider Dialoge: breiter als AlertDialog, runde Ecken, scrollbar
// (sonst Overflow, wenn die Tastatur hochkommt).
class _DialogShell extends StatelessWidget {
  final List<Widget> children;
  const _DialogShell({required this.children});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: children,
          ),
        ),
      ),
    );
  }
}

class _IconBadge extends StatelessWidget {
  final IconData icon;
  final List<Color> gradient;
  final Color iconColor;
  const _IconBadge({
    required this.icon,
    required this.gradient,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: gradient,
          ),
        ),
        child: Icon(icon, size: 30, color: iconColor),
      ),
    );
  }
}

class _DialogTitle extends StatelessWidget {
  final String text;
  const _DialogTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.5,
        color: AppColors.onSurface,
      ),
    );
  }
}

class _DialogBody extends StatelessWidget {
  final String text;
  const _DialogBody(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: 15,
        height: 1.45,
        fontWeight: FontWeight.w500,
        color: AppColors.onSurfaceVariant,
      ),
    );
  }
}

// Wie _buildLabel im Login-Screen.
class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
          color: AppColors.onSurfaceVariant,
        ),
      ),
    );
  }
}

class _ConsequenceRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String text;
  const _ConsequenceRow({
    required this.icon,
    required this.color,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 14,
              height: 1.35,
              fontWeight: FontWeight.w500,
              color: AppColors.onSurface,
            ),
          ),
        ),
      ],
    );
  }
}

// Wie der "Login to Feed"-Button. onPressed null = ausgegraut.
class _GradientButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  const _GradientButton({required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    return AnimatedOpacity(
      opacity: enabled ? 1 : 0.45,
      duration: const Duration(milliseconds: 150),
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.primary, AppColors.primaryContainer],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: enabled
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.2),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ]
              : null,
        ),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            disabledBackgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          onPressed: onPressed,
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}

class _DangerButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  const _DangerButton({required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.redAccent,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        onPressed: onPressed,
        child: Text(
          label,
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}

class _SecondaryButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  const _SecondaryButton({required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: TextButton(
        style: TextButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        onPressed: onPressed,
        child: Text(
          label,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: AppColors.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

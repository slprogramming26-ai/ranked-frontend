// "Konto loeschen" fuer Gesperrte: ohne Token, nur mit E-Mail + Passwort
// (POST /users/delete). Optik wie die Key-Restore-Dialoge: gefuellte Felder,
// roter Button, Fehler direkt im Dialog statt als SnackBar.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../auth/delete_result.dart';
import '../core/user_api_service.dart';
import '../l10n/l10n.dart';
import '../local_data/database.dart';
import '../ui/app_colors.dart';

/// true = Konto geloescht und lokal aufgeraeumt, false = abgebrochen.
/// [initialEmail] fuellt das E-Mail-Feld vor (leer beim Zwangs-Logout-Pfad,
/// dort kennen wir die Adresse nicht).
Future<bool> showDeleteSuspendedDialog(
  BuildContext context, {
  String initialEmail = '',
}) async {
  final deleted = await showDialog<bool>(
    context: context,
    // Kein Tap daneben: sonst geht der Dialog mitten im Request zu.
    barrierDismissible: false,
    builder: (_) => _DeleteSuspendedDialog(initialEmail: initialEmail),
  );
  return deleted ?? false;
}

class _DeleteSuspendedDialog extends StatefulWidget {
  final String initialEmail;
  const _DeleteSuspendedDialog({required this.initialEmail});

  @override
  State<_DeleteSuspendedDialog> createState() => _DeleteSuspendedDialogState();
}

class _DeleteSuspendedDialogState extends State<_DeleteSuspendedDialog> {
  late final TextEditingController _email;
  final _password = TextEditingController();
  bool _obscure = true;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _email = TextEditingController(text: widget.initialEmail);
    // Button erst aktiv, wenn beide Felder etwas enthalten; Fehler weg,
    // sobald man tippt.
    _email.addListener(_onChanged);
    _password.addListener(_onChanged);
  }

  void _onChanged() => setState(() => _error = null);

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  bool get _canSubmit =>
      !_busy && _email.text.trim().isNotEmpty && _password.text.isNotEmpty;

  Future<void> _submit() async {
    if (!_canSubmit) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    // Vor dem await holen: danach koennte der Dialog schon weg sein.
    final db = context.read<AppDatabase>();
    final l10n = context.l10n;

    // Passwort ohne trim - wie beim Login, sonst passt der Hash nicht.
    final result = await UserApiService.deleteSuspendedAccount(
      _email.text.trim(),
      _password.text,
    );
    // Kein default: kommt ein neuer DeleteResult-Fall dazu, meckert der Compiler.
    switch (result) {
      case DeleteOk():
        // Keypair + Token hat der Service schon geloescht, die DB fehlt noch.
        // Auch wenn der Dialog inzwischen weg ist: aufraeumen muss sein.
        await db.clearDatabase();
        if (mounted) Navigator.pop(context, true);
        return;
      case DeleteInvalid():
        _showError(l10n.loginInvalidCredentials);
      case DeleteTooManyRequests():
        _showError(l10n.suspendedDeleteTooMany);
      case DeleteOffline():
        _showError(l10n.loginServerError);
      case DeleteError():
        _showError(l10n.suspendedDeleteFailed);
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    setState(() {
      _error = message;
      _busy = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    // System-Zurueck waehrend des Requests sperren (wie barrierDismissible).
    return PopScope(
      canPop: !_busy,
      child: _DialogShell(
        children: [
          Center(
            child: Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.redAccent.withValues(alpha: 0.15),
              ),
              child: const Icon(
                Icons.delete_forever_rounded,
                size: 30,
                color: Colors.redAccent,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            l10n.suspendedDeleteTitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
              color: AppColors.onSurface,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            l10n.suspendedDeleteMessage,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              height: 1.45,
              fontWeight: FontWeight.w500,
              color: AppColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),
          _FieldLabel(l10n.loginEmailLabel),
          TextField(
            controller: _email,
            enabled: !_busy,
            keyboardType: TextInputType.emailAddress,
            autocorrect: false,
            textInputAction: TextInputAction.next,
            style: TextStyle(color: AppColors.onSurface),
            decoration: _fieldDecoration(
              icon: Icons.alternate_email,
              hint: 'alex@example.com',
            ),
          ),
          const SizedBox(height: 16),
          _FieldLabel(l10n.loginPasswordLabel),
          TextField(
            controller: _password,
            enabled: !_busy,
            obscureText: _obscure,
            // E-Mail schon da (Login-Pfad) -> direkt ins Passwort.
            autofocus: widget.initialEmail.isNotEmpty,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _submit(),
            style: TextStyle(color: AppColors.onSurface),
            decoration: _fieldDecoration(
              icon: Icons.lock,
              hint: '••••••••',
              suffix: IconButton(
                onPressed: () => setState(() => _obscure = !_obscure),
                icon: Icon(
                  _obscure
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  color: AppColors.onSurfaceVariant.withValues(alpha: 0.6),
                ),
              ),
            ),
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(left: 4, top: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 16,
                    color: Colors.redAccent,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      _error!,
                      style: const TextStyle(
                        color: Colors.redAccent,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 24),
          _DangerButton(
            label: l10n.suspendedDeleteConfirm,
            busy: _busy,
            onPressed: _canSubmit ? _submit : null,
          ),
          const SizedBox(height: 4),
          SizedBox(
            height: 48,
            child: TextButton(
              style: TextButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              onPressed: _busy ? null : () => Navigator.pop(context, false),
              child: Text(
                l10n.suspendedDeleteCancel,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.onSurfaceVariant,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _fieldDecoration({
    required IconData icon,
    required String hint,
    Widget? suffix,
  }) {
    return InputDecoration(
      prefixIcon: Icon(
        icon,
        color: AppColors.onSurfaceVariant.withValues(alpha: 0.5),
      ),
      suffixIcon: suffix,
      hintText: hint,
      hintStyle: TextStyle(color: AppColors.onSurface.withValues(alpha: 0.3)),
      filled: true,
      fillColor: AppColors.surfaceContainerHighest.withValues(alpha: 0.3),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: BorderSide.none,
      ),
      // Fehler: roter Rahmen an beiden Feldern (401 sagt nicht, welches).
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: _error != null
            ? const BorderSide(color: Colors.redAccent, width: 1.5)
            : BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: BorderSide(
          color: _error != null
              ? Colors.redAccent
              : AppColors.primary.withValues(alpha: 0.6),
          width: 1.5,
        ),
      ),
      disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(vertical: 18),
    );
  }
}

// --- Bausteine (eigene Kopien, wie in key_restore_dialogs.dart) ------------

// Breiter als AlertDialog, runde Ecken, scrollbar (sonst Overflow, wenn die
// Tastatur hochkommt).
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

// Roter Button; onPressed null = ausgegraut, busy = Spinner statt Text.
class _DangerButton extends StatelessWidget {
  final String label;
  final bool busy;
  final VoidCallback? onPressed;
  const _DangerButton({
    required this.label,
    required this.busy,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.redAccent,
          foregroundColor: Colors.white,
          // Waehrend busy bleibt der Button rot, nur ohne Tap.
          disabledBackgroundColor: Colors.redAccent.withValues(
            alpha: busy ? 1 : 0.45,
          ),
          disabledForegroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        onPressed: onPressed,
        child: busy
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Colors.white,
                ),
              )
            : Text(
                label,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }
}

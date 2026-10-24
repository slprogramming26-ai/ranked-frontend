import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../ui/app_colors.dart';
import 'code_input.dart';
import 'code_request_result.dart';
import '../l10n/l10n.dart';
import '../moderation/suspended_screen.dart';
import '../moderation/suspension.dart';
import '../core/user_api_service.dart';
import 'verify_result.dart';

/// Code-Eingabe nach der Registrierung bzw. nach einem Login mit
/// unbestaetigter E-Mail. Per Navigator.push oeffnen:
///
/// ```dart
/// final ok = await Navigator.push<bool>(context, MaterialPageRoute(
///   builder: (_) => VerifyEmailScreen(email: email)));
/// ```
///
/// true = E-Mail ist bestaetigt -> der Aufrufer loggt sich danach ein.
/// Token NICHT voraussetzen: bei 409 (war schon bestaetigt) gibt es keine.
/// false/null = abgebrochen (Zurueck-Pfeil, System-Zurueck, Sperre).
class VerifyEmailScreen extends StatefulWidget {
  const VerifyEmailScreen({
    super.key,
    required this.email,
    this.sendCodeOnOpen = false,
  });

  final String email;

  /// true beim Login: der Code von der Registrierung ist evtl. laengst
  /// abgelaufen -> gleich einen neuen anfordern. Nach createUser false,
  /// da wurde gerade erst einer verschickt.
  final bool sendCodeOnOpen;

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  static const _codeLength = CodeInput.length;
  // Gleich wie EMAIL_CODE_RESEND_COOLDOWN im Backend.
  static const _resendCooldown = 60;
  // Bei 429 sagt der Server nicht, wie lange noch -> kurz warten statt
  // stumpf wieder 60 s (meist sind nur noch ein paar Sekunden uebrig).
  static const _cooldownRetry = 15;

  final _codeController = TextEditingController();
  final _focusNode = FocusNode();
  Timer? _timer;
  int _secondsLeft = 0;
  bool _isVerifying = false;
  bool _isSending = false;
  String? _errorMessage;
  String? _infoMessage;
  // Gesetzt = Gesperrt-Screen statt Formular (wie im Login).
  Suspension? _suspension;

  @override
  void initState() {
    super.initState();
    if (widget.sendCodeOnOpen) {
      // Nach dem ersten Frame: _resend braucht context.l10n und ruft
      // setState - beides ist mitten in initState noch nicht erlaubt.
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _resend(onOpen: true),
      );
    } else {
      _startCountdown(_resendCooldown);
    }
  }

  @override
  void dispose() {
    // Ohne cancel tickt der Timer weiter und ruft setState auf einem
    // toten State -> Exception.
    _timer?.cancel();
    _codeController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  // Ohne eigenes setState: wird aus initState und aus setState-Bloecken
  // heraus aufgerufen. Danach zaehlt der Timer selbst runter.
  void _startCountdown(int seconds) {
    _timer?.cancel();
    _secondsLeft = seconds;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() => _secondsLeft--);
      if (_secondsLeft <= 0) timer.cancel();
    });
  }

  void _onCodeChanged(String code) {
    setState(() => _errorMessage = null);
    // Sechste Ziffer = abschicken, kein extra Tippen auf den Button noetig.
    if (code.length == _codeLength) _verify();
  }

  Future<void> _verify() async {
    final code = _codeController.text;
    if (code.length != _codeLength || _isVerifying) return;
    setState(() {
      _isVerifying = true;
      _errorMessage = null;
      _infoMessage = null;
    });

    final result = await UserApiService.verify(widget.email, code);
    if (!mounted) return;
    final l10n = context.l10n;
    // Kein default: kommt ein neuer VerifyResult-Fall dazu, meckert der Compiler.
    switch (result) {
      case VerifyOk() || VerifyAlreadyOk():
        Navigator.pop(context, true);
        return;
      case VerifyBanned(:final suspension):
        setState(() {
          _suspension = suspension;
          _isVerifying = false;
        });
        return;
      case VerifyCodeInvalid():
        _codeController.clear(); // naechster Versuch startet bei Box 1
        _showError(l10n.verifyCodeInvalid);
      case VerifyTooManyRequests():
        _showError(l10n.verifyTooManyRequests);
      case VerifyOffline():
        _showError(l10n.loginServerError);
      case VerifyError():
        _showError(l10n.verifyError);
    }
  }

  void _showError(String message) {
    setState(() {
      _errorMessage = message;
      _isVerifying = false;
    });
  }

  // onOpen: der automatische Versand beim Oeffnen (Login-Pfad). Ein 429
  // heisst dort nur "es gibt schon einen frischen Code" - kein Fehler.
  Future<void> _resend({bool onOpen = false}) async {
    if (_isSending || _secondsLeft > 0) return;
    setState(() {
      _isSending = true;
      _errorMessage = null;
      _infoMessage = null;
    });

    final result = await UserApiService.resendVerification(widget.email);
    if (!mounted) return;
    final l10n = context.l10n;
    setState(() {
      _isSending = false;
      switch (result) {
        case CodeRequestSent():
          _infoMessage = l10n.verifyResent;
          _startCountdown(_resendCooldown);
        case CodeRequestCooldown():
          if (!onOpen) _errorMessage = l10n.verifyCooldown;
          _startCountdown(_cooldownRetry);
        case CodeRequestOffline():
          _errorMessage = l10n.loginServerError;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final suspension = _suspension;
    if (suspension != null) {
      return SuspendedScreen(
        suspension: suspension,
        onBack: () => Navigator.pop(context, false),
      );
    }
    final l10n = context.l10n;

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.onSurface),
          onPressed: () => Navigator.pop(context, false),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: Column(
            children: [
              _buildIcon(),
              const SizedBox(height: 28),
              Text(
                l10n.verifyTitle,
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.8,
                  color: AppColors.onSurface,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                l10n.verifySubtitle(widget.email),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  height: 1.45,
                  fontWeight: FontWeight.w500,
                  color: AppColors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 32),
              CodeInput(
                controller: _codeController,
                focusNode: _focusNode,
                enabled: !_isVerifying,
                hasError: _errorMessage != null,
                onChanged: _onCodeChanged,
              ),
              if (_errorMessage != null || _infoMessage != null) ...[
                const SizedBox(height: 16),
                _buildMessage(),
              ],
              const SizedBox(height: 28),
              _buildConfirmButton(l10n.verifyButton),
              const SizedBox(height: 20),
              _buildResend(),
              const SizedBox(height: 4),
              Text(
                l10n.verifySpamHint,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.onSurfaceVariant.withValues(alpha: 0.8),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Brief im weichen Doppel-Kreis, gleiche Form wie im SuspendedScreen.
  Widget _buildIcon() {
    return Container(
      width: 112,
      height: 112,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.primary.withValues(alpha: 0.08),
      ),
      child: Center(
        child: Container(
          width: 76,
          height: 76,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [AppColors.primary, AppColors.primaryContainer],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.25),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: const Icon(
            Icons.mark_email_unread_outlined,
            color: Colors.white,
            size: 34,
          ),
        ),
      ),
    );
  }

  // Fehler im Primary-Ton wie im CredentialsStep, Info neutral.
  Widget _buildMessage() {
    final isError = _errorMessage != null;
    final color = isError ? AppColors.primary : AppColors.onSurfaceVariant;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isError
            ? AppColors.primary.withValues(alpha: 0.10)
            : AppColors.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(
            isError ? Icons.error_outline : Icons.check_circle_outline,
            color: color,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _errorMessage ?? _infoMessage!,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Gleicher Button wie im Login-Formular.
  Widget _buildConfirmButton(String text) {
    final canSubmit =
        _codeController.text.length == _codeLength && !_isVerifying;
    return Container(
      width: double.infinity,
      height: 60,
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: canSubmit ? 1 : 0.45),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          if (canSubmit)
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.2),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
        ],
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
        onPressed: canSubmit ? _verify : null,
        child: _isVerifying
            ? const CircularProgressIndicator(color: Colors.white)
            : Text(
                text,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }

  Widget _buildResend() {
    final l10n = context.l10n;
    if (_isSending) {
      return SizedBox(
        height: 48,
        child: Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.primary,
            ),
          ),
        ),
      );
    }
    if (_secondsLeft > 0) {
      return SizedBox(
        height: 48,
        child: Center(
          child: Text(
            l10n.verifyResendIn(_secondsLeft),
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: AppColors.onSurfaceVariant,
              // Ziffern gleich breit -> der Text wackelt beim Runterzaehlen nicht.
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ),
      );
    }
    return TextButton(
      onPressed: _resend,
      style: TextButton.styleFrom(minimumSize: const Size(0, 48)),
      child: Text(
        l10n.verifyResend,
        style: TextStyle(
          color: AppColors.primary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

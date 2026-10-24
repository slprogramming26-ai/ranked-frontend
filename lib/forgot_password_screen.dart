import 'dart:async';

import 'package:email_validator/email_validator.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';
import 'code_input.dart';
import 'code_request_result.dart';
import 'l10n/l10n.dart';
import 'onboarding/onboarding_text_field.dart';
import 'password_policy.dart';
import 'reset_result.dart';
import 'user_api_service.dart';

/// Was der Screen bei Erfolg zurueckgibt: damit loggt der Login-Screen
/// direkt ein (reset liefert selbst keine Token).
typedef ResetCredentials = ({String email, String password});

/// Passwort vergessen, zwei Phasen in einem Screen:
///   1. E-Mail eingeben -> Code anfordern
///   2. Code + neues Passwort -> zuruecksetzen
///
/// ```dart
/// final creds = await Navigator.push<ResetCredentials>(context,
///   MaterialPageRoute(builder: (_) => ForgotPasswordScreen(initialEmail: email)));
/// ```
///
/// null = abgebrochen.
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key, this.initialEmail = ''});

  /// Aus dem Login-Feld, damit man die Adresse nicht zweimal tippt.
  final String initialEmail;

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

enum _Phase { email, reset }

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  // Gleich wie im VerifyEmailScreen (EMAIL_CODE_RESEND_COOLDOWN).
  static const _resendCooldown = 60;
  static const _cooldownRetry = 15;

  late final _emailController = TextEditingController(
    text: widget.initialEmail,
  );
  final _codeController = TextEditingController();
  final _codeFocusNode = FocusNode();
  final _passwordController = TextEditingController();

  _Phase _phase = _Phase.email;
  // Die Adresse, an die der Code WIRKLICH ging. Ab Phase 2 zaehlt nur noch
  // die, nicht mehr das (evtl. inzwischen geaenderte) Feld.
  String _email = '';
  Timer? _timer;
  int _secondsLeft = 0;
  bool _isSending = false;
  bool _isResetting = false;
  // 429 mit Tageslimit -> heute kein Versuch mehr, Button bleibt aus.
  bool _dailyLimit = false;
  String? _errorMessage;
  String? _infoMessage;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _timer?.cancel();
    _emailController.dispose();
    _codeController.dispose();
    _codeFocusNode.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Wie im VerifyEmailScreen: ohne eigenes setState, Aufruf aus setState-
  // Bloecken heraus.
  void _startCountdown(int seconds) {
    _timer?.cancel();
    _secondsLeft = seconds;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() => _secondsLeft--);
      if (_secondsLeft <= 0) timer.cancel();
    });
  }

  // Phase 1 ("Code senden") UND Phase 2 ("erneut senden").
  Future<void> _requestCode() async {
    if (_isSending || _secondsLeft > 0) return;
    final isResend = _phase == _Phase.reset;
    final email = isResend ? _email : _emailController.text.trim();
    // Pflicht, nicht Kosmetik: eine kaputte Adresse gibt im Backend 422, und
    // _requestCode macht daraus "gesendet" -> man wartete ewig auf den Code.
    // Gleiche Pruefung wie im Onboarding.
    if (!EmailValidator.validate(email)) {
      setState(() => _errorMessage = context.l10n.resetEmailInvalid);
      return;
    }
    setState(() {
      _isSending = true;
      _errorMessage = null;
      _infoMessage = null;
    });

    final result = await UserApiService.forgotPassword(email);
    if (!mounted) return;
    final l10n = context.l10n;
    setState(() {
      _isSending = false;
      switch (result) {
        case CodeRequestSent():
          if (isResend) _infoMessage = l10n.verifyResent;
          _email = email;
          _phase = _Phase.reset;
          _startCountdown(_resendCooldown);
        case CodeRequestCooldown():
          // Es gibt schon einen frischen Code (z.B. nach Zurueck und
          // nochmal senden) -> trotzdem zur Eingabe, nur in Phase 2 meckern.
          if (isResend) _errorMessage = l10n.verifyCooldown;
          _email = email;
          _phase = _Phase.reset;
          _startCountdown(_cooldownRetry);
        case CodeRequestOffline():
          _errorMessage = l10n.loginServerError;
      }
    });
  }

  Future<void> _reset() async {
    final code = _codeController.text;
    final password = _passwordController.text;
    if (code.length != CodeInput.length || _isResetting || _dailyLimit) return;
    if (!isValidPasswordLength(password)) {
      _showError(context.l10n.resetPasswordLength);
      return;
    }
    setState(() {
      _isResetting = true;
      _errorMessage = null;
      _infoMessage = null;
    });

    final result = await UserApiService.resetPassword(_email, code, password);
    if (!mounted) return;
    final l10n = context.l10n;
    // Kein default: kommt ein neuer ResetResult-Fall dazu, meckert der Compiler.
    switch (result) {
      case ResetOk():
        Navigator.pop<ResetCredentials>(
          context,
          (email: _email, password: password),
        );
        return;
      case ResetCodeInvalid():
        // Nur der Code ist falsch - das Passwort bleibt stehen.
        _codeController.clear();
        _showError(l10n.verifyCodeInvalid);
      case ResetDailyLimit():
        _dailyLimit = true; // setState kommt gleich in _showError
        _showError(l10n.resetDailyLimit);
      case ResetTooManyRequests():
        _showError(l10n.verifyTooManyRequests);
      case ResetOffline():
        _showError(l10n.loginServerError);
      case ResetError():
        _showError(l10n.verifyError);
    }
  }

  void _showError(String message) {
    setState(() {
      _errorMessage = message;
      _isResetting = false;
    });
  }

  // Zurueck in Phase 2 = zurueck zur E-Mail (Tippfehler korrigieren), nicht
  // gleich raus aus dem Screen.
  void _backToEmail() {
    _timer?.cancel();
    _codeController.clear();
    _passwordController.clear();
    setState(() {
      _phase = _Phase.email;
      _secondsLeft = 0;
      // Das Tageslimit gilt pro Konto - mit anderer Adresse evtl. nicht.
      _dailyLimit = false;
      _errorMessage = null;
      _infoMessage = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isEmailPhase = _phase == _Phase.email;

    // Faengt System-Zurueck (Geste/Taste) in Phase 2 ab.
    return PopScope(
      canPop: isEmailPhase,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _backToEmail();
      },
      child: Scaffold(
        backgroundColor: AppColors.surface,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: AppColors.onSurface),
            // maybePop statt pop -> laeuft durch den PopScope oben, der
            // Pfeil verhaelt sich also wie System-Zurueck.
            onPressed: () => Navigator.maybePop(context),
          ),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
            child: Column(
              children: [
                _buildIcon(isEmailPhase),
                const SizedBox(height: 28),
                Text(
                  isEmailPhase ? l10n.resetTitle : l10n.resetCodeTitle,
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
                  isEmailPhase
                      ? l10n.resetEmailSubtitle
                      : l10n.resetCodeSubtitle(_email),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    height: 1.45,
                    fontWeight: FontWeight.w500,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 32),
                // Weicher Uebergang zwischen den Phasen statt hartem Sprung.
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  child: isEmailPhase
                      ? _buildEmailPhase()
                      : _buildResetPhase(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmailPhase() {
    return Column(
      key: const ValueKey(_Phase.email),
      children: [
        OnboardingTextField(
          controller: _emailController,
          hint: 'alex@example.com',
          keyboardType: TextInputType.emailAddress,
          prefix: Icon(
            Icons.alternate_email,
            color: AppColors.onSurfaceVariant.withValues(alpha: 0.6),
          ),
        ),
        if (_errorMessage != null) ...[
          const SizedBox(height: 16),
          _buildMessage(),
        ],
        const SizedBox(height: 28),
        _buildPrimaryButton(
          text: context.l10n.resetSendButton,
          isLoading: _isSending,
          onPressed: _isSending ? null : _requestCode,
        ),
      ],
    );
  }

  Widget _buildResetPhase() {
    final l10n = context.l10n;
    return Column(
      key: const ValueKey(_Phase.reset),
      children: [
        CodeInput(
          controller: _codeController,
          focusNode: _codeFocusNode,
          enabled: !_isResetting,
          hasError: _errorMessage != null,
          // Neuer Versuch -> alter Fehler weg (wie im VerifyEmailScreen).
          // Das Tageslimit bleibt stehen, da hilft kein neuer Code.
          onChanged: (_) {
            if (_errorMessage != null && !_dailyLimit) {
              setState(() => _errorMessage = null);
            }
          },
        ),
        const SizedBox(height: 16),
        OnboardingTextField(
          controller: _passwordController,
          hint: l10n.resetNewPasswordHint,
          obscure: _obscurePassword,
          prefix: Icon(
            Icons.lock_outline,
            color: AppColors.onSurfaceVariant.withValues(alpha: 0.6),
          ),
          suffix: IconButton(
            onPressed: () =>
                setState(() => _obscurePassword = !_obscurePassword),
            icon: Icon(
              _obscurePassword ? Icons.visibility : Icons.visibility_off,
              color: AppColors.onSurfaceVariant,
            ),
          ),
        ),
        if (_errorMessage != null || _infoMessage != null) ...[
          const SizedBox(height: 16),
          _buildMessage(),
        ],
        const SizedBox(height: 28),
        // Button haengt an Code UND Passwort -> bei jedem Tippen neu
        // pruefen, ohne den ganzen Screen per setState neu zu bauen.
        ListenableBuilder(
          listenable: Listenable.merge([_codeController, _passwordController]),
          builder: (context, _) {
            final canSubmit =
                _codeController.text.length == CodeInput.length &&
                _passwordController.text.isNotEmpty &&
                !_isResetting &&
                !_dailyLimit;
            return _buildPrimaryButton(
              text: l10n.resetButton,
              isLoading: _isResetting,
              onPressed: canSubmit ? _reset : null,
            );
          },
        ),
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
    );
  }

  // Gleiche Form wie im VerifyEmailScreen, Icon je nach Phase.
  Widget _buildIcon(bool isEmailPhase) {
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
          child: Icon(
            isEmailPhase ? Icons.lock_reset : Icons.password,
            color: Colors.white,
            size: 34,
          ),
        ),
      ),
    );
  }

  // Fehler im Primary-Ton wie im VerifyEmailScreen, Info neutral.
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

  // Gleicher Button wie im Login/VerifyEmailScreen. onPressed null = aus.
  Widget _buildPrimaryButton({
    required String text,
    required bool isLoading,
    required VoidCallback? onPressed,
  }) {
    final enabled = onPressed != null;
    return Container(
      width: double.infinity,
      height: 60,
      decoration: BoxDecoration(
        // Beim Laden voll rot lassen, sonst flackert der Button.
        color: AppColors.primary.withValues(
          alpha: enabled || isLoading ? 1 : 0.45,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          if (enabled)
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
        onPressed: onPressed,
        child: isLoading
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
      onPressed: _requestCode,
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
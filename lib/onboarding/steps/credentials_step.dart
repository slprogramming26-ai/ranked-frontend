import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../app_colors.dart';

class CredentialsStep extends StatefulWidget {
  // Die Controller leben im Flow-State (collect-first): Der Flow liest die
  // Werte am Ende selbst aus, und die Eingaben ueberleben Seitenwechsel.
  final TextEditingController emailController;
  final TextEditingController usernameController;
  final TextEditingController passwordController;

  // Backend-Fehler (E-Mail/Username vergeben, <16) kommen vom Flow rein,
  // weil erst der Complete-Button den createUser-Call ausloest.
  final String? errorMessage;

  const CredentialsStep({
    super.key,
    required this.emailController,
    required this.usernameController,
    required this.passwordController,
    this.errorMessage,
  });

  @override
  State<CredentialsStep> createState() => _CredentialsStepState();
}

class _CredentialsStepState extends State<CredentialsStep> {
  // Nur das Auge-Toggle ist lokaler UI-State — Repeat-Passwort entfaellt
  // bewusst, das Auge reicht zum Kontrollieren.
  bool _obscurePassword = true;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          const SizedBox(height: 20),

          // --- Icon Badge ---
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  AppColors.primary,
                  AppColors.primaryContainer,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.3),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Icon(
              Icons.rocket_launch_outlined,
              color: Colors.white,
              size: 32,
            ),
          ),

          const SizedBox(height: 20),

          // --- Hero Text ---
          RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              style: GoogleFonts.plusJakartaSans(
                fontSize: 26,
                fontWeight: FontWeight.w900,
                color: AppColors.onSurface,
                letterSpacing: -0.5,
              ),
              children: [
                const TextSpan(text: 'Join the '),
                TextSpan(
                  text: 'Pulse',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Text(
            "Last step — pick your login and your profile goes live.",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: AppColors.onSurfaceVariant,
              height: 1.5,
            ),
          ),

          const SizedBox(height: 28),

          _buildTextField(
            controller: widget.emailController,
            hint: 'Email Address',
            icon: Icons.mail_outline,
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 12),

          _buildTextField(
            controller: widget.usernameController,
            hint: 'username',
            prefixText: '@',
          ),
          const SizedBox(height: 12),

          _buildTextField(
            controller: widget.passwordController,
            hint: 'Password',
            icon: Icons.lock_outline,
            obscure: _obscurePassword,
            suffix: IconButton(
              onPressed: () =>
                  setState(() => _obscurePassword = !_obscurePassword),
              icon: Icon(
                _obscurePassword ? Icons.visibility : Icons.visibility_off,
                color: AppColors.onSurfaceVariant,
                size: 20,
              ),
            ),
          ),

          // --- Backend-Fehler (409 doppelt / 403 unter 16) ---
          if (widget.errorMessage != null)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFA26769).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: Color(0xFFA26769),
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        widget.errorMessage!,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFFA26769),
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          const SizedBox(height: 20),

          Text(
            'By signing up, you agree to our Community Guidelines',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 10,
              color: AppColors.onSurfaceVariant.withValues(alpha: 0.6),
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    IconData? icon,
    String? prefixText,
    bool obscure = false,
    Widget? suffix,
    TextInputType? keyboardType,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        keyboardType: keyboardType,
        style: TextStyle(
          color: AppColors.onSurface,
          fontWeight: FontWeight.w600,
          fontSize: 15,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(
            color: AppColors.onSurfaceVariant.withValues(alpha: 0.5),
            fontWeight: FontWeight.w500,
          ),
          prefixIcon: icon != null
              ? Icon(icon,
                  color: AppColors.primary.withValues(alpha: 0.6), size: 20)
              : prefixText != null
                  ? Padding(
                      padding: const EdgeInsets.only(left: 16, right: 8),
                      child: Text(
                        prefixText,
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
                          color: AppColors.primary,
                        ),
                      ),
                    )
                  : null,
          prefixIconConstraints: const BoxConstraints(minWidth: 48),
          suffixIcon: suffix,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.transparent,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }
}
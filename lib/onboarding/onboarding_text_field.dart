import 'package:flutter/material.dart';
import '../app_colors.dart';

/// Das eine Eingabefeld im Onboarding (Bio, E-Mail, Username, Passwort):
/// helle Flaeche mit duennem Rand, der beim Fokus rot wird.
/// Ein Style fuer den ganzen Flow, damit sich die Steps wie aus einem Guss
/// anfuehlen.
class OnboardingTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final int maxLines;
  final bool obscure;
  final TextInputType? keyboardType;
  final Widget? prefix;
  final Widget? suffix;

  const OnboardingTextField({
    super.key,
    required this.controller,
    required this.hint,
    this.maxLines = 1,
    this.obscure = false,
    this.keyboardType,
    this.prefix,
    this.suffix,
  });

  static const _radius = 16.0;

  OutlineInputBorder _border(Color color) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(_radius),
    borderSide: BorderSide(color: color, width: 1.5),
  );

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      obscureText: obscure,
      keyboardType: keyboardType,
      style: TextStyle(
        color: AppColors.onSurface,
        fontSize: 15,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          color: AppColors.onSurfaceVariant.withValues(alpha: 0.6),
          fontSize: 14,
          height: 1.6,
        ),
        prefixIcon: prefix,
        prefixIconConstraints: const BoxConstraints(minWidth: 48),
        suffixIcon: suffix,
        filled: true,
        fillColor: AppColors.inputFill,
        contentPadding: const EdgeInsets.all(16),
        border: _border(AppColors.surfaceContainerHighest),
        enabledBorder: _border(AppColors.surfaceContainerHighest),
        focusedBorder: _border(AppColors.primary),
      ),
    );
  }
}

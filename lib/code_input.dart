import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// 6-stelliger Code als Kaestchen (E-Mail bestaetigen, Passwort vergessen).
///
/// 6 Kaestchen zum Anschauen + ein unsichtbares TextField darueber, das
/// die Eingabe macht. So funktionieren Tastatur, Einfuegen (lange druecken)
/// und das SMS/Mail-Autofill (oneTimeCode) wie bei einem normalen Feld.
///
/// Controller und FocusNode gehoeren dem Aufrufer (er braucht den Text fuer
/// den Button und raeumt beides in dispose auf). Neu zeichnen bei Tippen
/// und Fokuswechsel macht das Widget selbst.
class CodeInput extends StatelessWidget {
  const CodeInput({
    super.key,
    required this.controller,
    required this.focusNode,
    this.onChanged,
    this.enabled = true,
    this.hasError = false,
    this.autofocus = true,
  });

  static const length = 6;

  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String>? onChanged;
  final bool enabled;

  /// Kaestchen-Rand leicht eingefaerbt, solange ein Fehler angezeigt wird.
  final bool hasError;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Hoert auf Text UND Fokus -> der Aufrufer muss dafuer kein
        // setState mehr machen.
        ListenableBuilder(
          listenable: Listenable.merge([controller, focusNode]),
          builder: (context, _) {
            final code = controller.text;
            return Row(
              children: [
                for (var i = 0; i < length; i++) ...[
                  if (i > 0) const SizedBox(width: 8),
                  Expanded(child: _buildDigitBox(i, code)),
                ],
              ],
            );
          },
        ),
        Positioned.fill(
          child: Opacity(
            opacity: 0,
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              autofocus: autofocus,
              enabled: enabled,
              keyboardType: TextInputType.number,
              autofillHints: const [AutofillHints.oneTimeCode],
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(length),
              ],
              showCursor: false,
              decoration: const InputDecoration(
                border: InputBorder.none,
                counterText: '',
              ),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDigitBox(int index, String code) {
    final hasDigit = index < code.length;
    // Aktiv = hier landet die naechste Ziffer (bei vollem Code die letzte).
    final isActive =
        focusNode.hasFocus && index == code.length.clamp(0, length - 1);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      height: 60,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.inputFill,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isActive
              ? AppColors.primary
              : hasError
              ? AppColors.primary.withValues(alpha: 0.35)
              : AppColors.surfaceContainerHighest,
          width: isActive ? 2 : 1.5,
        ),
      ),
      child: Text(
        hasDigit ? code[index] : '',
        style: GoogleFonts.plusJakartaSans(
          fontSize: 24,
          fontWeight: FontWeight.w800,
          color: AppColors.onSurface,
        ),
      ),
    );
  }
}

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'app_colors.dart';

/// Branded Start-Splash: laeuft, solange der Token-Check beim App-Start
/// unterwegs ist (loggedIn == null in main.dart).
///
/// Design: grosser Bruder des Login-Headers — gleicher Gradient, gleiche
/// RANKED-Wortmarke. Zwei Animationen haengen an EINEM Controller:
///   1. "Atmen": die Wortmarke skaliert sanft hoch und runter (Sinus).
///   2. Glanz-Streifen: ein heller Lichtstreifen wandert einmal pro Zyklus
///      schraeg ueber den Schriftzug (ShaderMask, wie beim Skeleton-Shimmer
///      im Ranking — nur auf Text statt auf Platzhalter-Boxen).
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  // repeat() laesst den Wert endlos 0 -> 1 laufen; alles unten leitet sich
  // aus diesem einen Wert ab, damit Atmen und Glanz synchron bleiben.
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2200),
  )..repeat();

  @override
  void initState() {
    super.initState();
    // Gegenstueck zu preserve() in main(): erst wenn unser erster Frame
    // GEZEICHNET ist (PostFrameCallback), darf der native OS-Splash weg —
    // so gibt es keinen Moment, in dem keiner von beiden zu sehen ist.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FlutterNativeSplash.remove();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.primary, AppColors.primaryContainer],
          ),
        ),
        child: Center(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              final t = _controller.value;

              // Atmen: Sinus schwingt pro Zyklus einmal von -1 ueber +1
              // zurueck -> Scale pendelt zwischen 0.975 und 1.025.
              final scale = 1 + 0.025 * math.sin(t * 2 * math.pi);

              // Glanz: Startposition weit links (-1.8) ausserhalb des Texts,
              // wandert bis weit rechts (+1.8) raus. easeInOut laesst ihn in
              // der Mitte schnell durchziehen und an den Raendern "ruhen".
              final dx = -1.8 + 3.6 * Curves.easeInOut.transform(t);

              return Transform.scale(
                scale: scale,
                child: ShaderMask(
                  // srcATop malt den Gradient NUR dort, wo der Text Pixel
                  // hat; die transparenten Enden lassen den Text unveraendert.
                  blendMode: BlendMode.srcATop,
                  shaderCallback: (bounds) => LinearGradient(
                    begin: Alignment(dx - 0.6, -0.4),
                    end: Alignment(dx + 0.6, 0.4),
                    colors: [
                      Colors.transparent,
                      Colors.white.withValues(alpha: 0.5),
                      Colors.transparent,
                    ],
                  ).createShader(bounds),
                  child: child,
                ),
              );
            },
            // Wortmarke 1:1 wie im Login-Header, nur groesser.
            child: const Text(
              'RANKED',
              style: TextStyle(
                fontSize: 56,
                fontFamily: 'Plus Jakarta Sans',
                fontWeight: FontWeight.w900,
                fontStyle: FontStyle.italic,
                color: Colors.white,
                letterSpacing: -3,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
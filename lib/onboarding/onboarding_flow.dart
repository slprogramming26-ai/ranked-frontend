import 'dart:io';
import 'package:flutter/foundation.dart';

import '../core/image_sanitizer.dart';
import 'package:email_validator/email_validator.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ranked/main.dart';
import 'package:ranked/l10n/l10n.dart';
import '../ui/app_colors.dart';
import '../ui/app_loading.dart';
import '../auth/login_result.dart';
import '../auth/password_policy.dart';
import '../core/token_storage.dart';
import '../core/user_api_service.dart';
import '../auth/verify_email_screen.dart';
import 'steps/about_me_step.dart';
import 'steps/age_step.dart';
import 'steps/credentials_step.dart';
import 'steps/vibe_step.dart';
import 'steps/welcome_step.dart';
import 'package:ranked/e2ee/key_setup.dart';

class OnboardingFlow extends StatefulWidget {
  const OnboardingFlow({super.key});

  @override
  State<OnboardingFlow> createState() => _OnboardingFlowState();
}

class _OnboardingFlowState extends State<OnboardingFlow> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // Collect-first: Bild bleibt bis zum Schluss eine lokale Datei,
  // null = kein Bild gewaehlt. Upload passiert erst in _handleNextStep.
  File? _finalImageFile;
  String _finalBio = '';

  Map<String, bool> vibeSelections = {
    'Productivity': false,
    'Creativity': false,
    'Fitness': false,
    'Gaming': false,
    'Coding': false,
    'Music': false,
    'Reading': false,
    'Sports': false,
  };

  int _age = 18;

  // Credentials: Controller leben hier im Flow, damit die Eingaben
  // Seitenwechsel ueberleben und _handleNextStep sie am Ende auslesen kann.
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  String? _credentialsError;
  bool _isSubmitting = false;

  // Mit diesen Daten wurde das Konto angelegt (null = noch keins). Bricht
  // der User auf dem Code-Screen ab und tippt nochmal, darf createUser
  // nicht erneut laufen -> sonst 409 "E-Mail vergeben" fuers eigene Konto.
  ({String email, String password})? _createdWith;
  // E-Mail schon bestaetigt -> beim erneuten Tippen direkt zum Login.
  bool _verified = false;

  @override
  void initState() {
    super.initState();
    // _canProceed haengt vom Feldinhalt ab — bei jedem Tastendruck neu
    // auswerten, sonst bleibt der Button ausgegraut.
    _emailController.addListener(_onCredentialsChanged);
    _usernameController.addListener(_onCredentialsChanged);
    _passwordController.addListener(_onCredentialsChanged);
  }

  void _onCredentialsChanged() => setState(() {});

  @override
  void dispose() {
    _emailController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  // Getter statt Feld: Die Widgets muessen bei jedem setState neu gebaut
  // werden, sonst sieht z.B. der VibeStep eine veraltete Auswahl.
  List<Widget> get _pages => [
    const WelcomeStep(),
    VibeStep(selections: vibeSelections, onToggle: _toggleVibe),
    AboutMeStep(
      onImagePicked: (file) => _finalImageFile = file,
      onAboutMeFinished: (bio) => _finalBio = bio,
    ),
    AgeStep(age: _age, onChanged: (v) => setState(() => _age = v)),
    CredentialsStep(
      emailController: _emailController,
      usernameController: _usernameController,
      passwordController: _passwordController,
      errorMessage: _credentialsError,
    ),
  ];

  bool get _isLastPage => _currentPage == _pages.length - 1;

  // Pro Seite: Darf der Next-Button gedrueckt werden?
  // Vibes/Bio/Bild sind bewusst optional ("Share only what you want to
  // share") — Pflicht-Checks bekommen erst Age/Username/Credentials.
  bool get _canProceed {
    switch (_currentPage) {
      case 3:
        return _age >= 16;
      case 4:
        return EmailValidator.validate(_emailController.text.trim()) &&
            _usernameController.text.trim().isNotEmpty &&
            isValidPasswordLength(_passwordController.text);
      default:
        return true;
    }
  }

  void _toggleVibe(String name) {
    final isActive = vibeSelections[name] ?? false;
    final activeCount = vibeSelections.values.where((v) => v).length;

    if (activeCount >= 2 && !isActive) return;

    setState(() {
      vibeSelections[name] = !isActive;
    });
  }

  void _goBack() {
    _pageController.previousPage(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _handleNextStep() async {
    if (!_isLastPage) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
      return;
    }

    // Collect-first, create-last: Erst der Complete-Button legt den User
    // wirklich an, dann Code bestaetigen -> login -> Upload -> Details.
    final email = _emailController.text.trim();
    setState(() {
      _isSubmitting = true;
      _credentialsError = null;
    });

    // Neue E-Mail (erster Versuch oder Tippfehler korrigiert) -> neues Konto.
    // Ein altes unbestaetigtes raeumt das Backend nach 24 h selbst weg.
    if (_createdWith?.email != email) {
      String? error;
      try {
        error = await UserApiService.createUser(
          email,
          _usernameController.text.trim(),
          _passwordController.text,
          _age,
        );
      } catch (_) {
        // Roher http.post wirft ohne Netz -> sonst haengt das Overlay ewig.
        // Hier statt im Service, weil nur hier context.l10n da ist.
        if (!mounted) return;
        error = context.l10n.loginServerError;
      }
      if (!mounted) return;
      if (error != null) {
        // Backend-Detail (E-Mail/Username vergeben, unter 16) ist direkt
        // anzeigbar — der User kann korrigieren und nochmal druecken.
        setState(() {
          _credentialsError = error;
          _isSubmitting = false;
        });
        return;
      }
      _createdWith = (email: email, password: _passwordController.text);
      _verified = false;
    }
    // Das Passwort, mit dem das Konto WIRKLICH angelegt wurde - auch wenn
    // der User es nach dem Abbruch im Feld noch geaendert hat.
    final password = _createdWith!.password;

    if (!_verified) {
      if (!mounted) return;
      // Overlay aus, sonst haengt es noch da, wenn der User vom Code-Screen
      // zurueckkommt.
      setState(() => _isSubmitting = false);
      final ok = await Navigator.push<bool>(
        context,
        MaterialPageRoute(builder: (_) => VerifyEmailScreen(email: email)),
      );
      // Abgebrochen -> User bleibt auf der Credentials-Seite.
      if (ok != true || !mounted) return;
      _verified = true;
      setState(() => _isSubmitting = true);
    }

    // Frisches Konto kann nicht gesperrt sein -> alles ausser Ok ist Fehler.
    // Bewusst nochmal login, obwohl verify() schon Token gespeichert hat:
    // bei 409 (war schon bestaetigt) gibt es keine.
    final result = await UserApiService.login(email, password);
    if (result is! LoginOk) {
      // verify()-Token wegwerfen, sonst loggt der naechste App-Start per
      // Session-Restore ein, ohne dass KeySetup je gelaufen ist.
      await TokenStorage.clearAll();
      if (!mounted) return;
      setState(() {
        _credentialsError = context.l10n.onboardingLoginFailedAuto;
        _isSubmitting = false;
      });
      return;
    }

    // Ab hier best-effort: Das Konto existiert schon. Wenn Upload oder
    // Details scheitern, lassen wir den User trotzdem in die App — Bild,
    // Bio und Vibes kann er spaeter im Profil nachtragen.
    final List<String> selectedVibes = vibeSelections.entries
        .where((e) => e.value)
        .map((e) => e.key)
        .toList();

    try {
      // E2EE: Nur hier (und beim Login) liegt das Passwort fürs Backup vor.
      final userId = (await UserApiService.getCurrentUser())['id'] as int?;
      if (userId != null) {
        await KeySetup.afterRegistration(userId, password);
      }
    } catch (e) {
      debugPrint('[E2EE] Key-Setup nach Registrierung fehlgeschlagen: $e');
    }

    try {
      String imageUrl = "";
      if (_finalImageFile != null) {
        // Metadaten loeschen + verkleinern (Hintergrund-Isolate).
        final cleanPath = await compute(
          sanitizeImageFile,
          (path: _finalImageFile!.path, maxSize: 1024, quality: 85),
        );

        if (!mounted) return;

        // Kein Fallback auf die Originaldatei — die traegt noch GPS/Kameradaten.
        // Aber auch kein Abbruch: das Konto existiert an dieser Stelle schon,
        // der User muss hier rauskommen. Also ohne Bild weiter (best-effort,
        // siehe oben), nachtragen kann er es im Profil.
        if (cleanPath == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(context.l10n.onboardingImageProcessError),
            ),
          );
        } else {
          imageUrl =
              await UserApiService.uploadUserImage(File(cleanPath)) ?? "";
        }
      }

      await UserApiService.addUserDetails(
        selectedVibes.isNotEmpty ? selectedVibes[0] : null,
        selectedVibes.length > 1 ? selectedVibes[1] : null,
        imageUrl,
        _finalBio,
      );
    } catch (e) {
      debugPrint("Fehler beim Speichern der Profildetails: $e");
    }

    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) =>
            const MyHomePage(title: 'Ranked Feed', initialLoggedIn: true),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                _buildHeader(),

                // PageView Content
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    // Kein freies Wischen: Navigation laeuft nur ueber die
                    // Buttons, damit spaeter kein Step uebersprungen werden kann.
                    physics: const NeverScrollableScrollPhysics(),
                    onPageChanged: (index) =>
                        setState(() => _currentPage = index),
                    children: _pages,
                  ),
                ),

                _buildFooterButton(),
              ],
            ),

            // Konto erstellen laeuft ueber mehrere sequenzielle Requests
            // (createUser -> login -> Bild-Upload -> Details) - der laengste
            // der drei Ladevorgaenge in der App, daher wie Post-Upload und
            // Story-Editor ein blockierendes Overlay statt nur Button-Spinner.
            if (_isSubmitting)
              AppLoadingOverlay(
                title: context.l10n.onboardingLoadingSetup,
                messages: [
                  context.l10n.onboardingLoadingCreating,
                  context.l10n.onboardingLoadingSigning,
                  context.l10n.onboardingLoadingSecuring,
                  context.l10n.onboardingLoadingUploading,
                  context.l10n.onboardingLoadingAlmost,
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              // Zurueck-Pfeil ersetzt das Wischen (ab Seite 2); waehrend
              // createUser laeuft gesperrt, sonst Doppel-Registrierung.
              if (_currentPage > 0 && !_isSubmitting)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: IconButton(
                    onPressed: _goBack,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon: Icon(
                      Icons.arrow_back_rounded,
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ),
              Text(
                'Ranked',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  fontStyle: FontStyle.italic,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          Row(
            children: [
              Text(
                context.l10n.onboardingStepProgress(
                  _currentPage + 1,
                  _pages.length,
                ),
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 40,
                height: 6,
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainer,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: (_currentPage + 1) / _pages.length,
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFooterButton() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: AnimatedOpacity(
        // Ausgegraut, solange die Seite nicht "fertig" ist (_canProceed)
        opacity: _canProceed ? 1.0 : 0.4,
        duration: const Duration(milliseconds: 200),
        child: Container(
          width: double.infinity,
          height: 65,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
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
              shadowColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            // Waehrend _isSubmitting deckt das AppLoadingOverlay den Button
            // ohnehin ab - hier reicht das Sperren per onPressed: null.
            onPressed: (_canProceed && !_isSubmitting) ? _handleNextStep : null,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _isLastPage ? context.l10n.onboardingCreateButton : context.l10n.onboardingNextButton,
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(width: 10),
                const Icon(Icons.arrow_forward, color: Colors.white),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

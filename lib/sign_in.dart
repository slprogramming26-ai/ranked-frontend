import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';
import 'package:ranked/main.dart';
import 'user_api_service.dart';
import 'location_picker.dart';
import 'package:email_validator/email_validator.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

class SignIn extends StatefulWidget {
  const SignIn({super.key});

  @override
  State<SignIn> createState() => _SignInState();
}

class _SignInState extends State<SignIn> {
  late TextEditingController email_editing_controller;
  late TextEditingController username_editing_controller;
  late TextEditingController password_editing_controller;
  late TextEditingController repeat_password_editing_controller;

  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    email_editing_controller = TextEditingController();
    username_editing_controller = TextEditingController();
    password_editing_controller = TextEditingController();
    repeat_password_editing_controller = TextEditingController();
  }

  @override
  void dispose() {
    email_editing_controller.dispose();
    username_editing_controller.dispose();
    password_editing_controller.dispose();
    repeat_password_editing_controller.dispose();
    super.dispose();
  }

  Future<void> _handleCreateAccount() async {
    if (!EmailValidator.validate(email_editing_controller.text)) {
      setState(() => _errorMessage = 'Ungültige Email-Adresse');
      return;
    }

    if (password_editing_controller.text !=
        repeat_password_editing_controller.text) {
      setState(() => _errorMessage = 'Passwörter stimmen nicht überein');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final response = await UserApiService.createUser(
      email_editing_controller.text,
      username_editing_controller.text,
      password_editing_controller.text,
    );

    if (response['Fehler'] == "Email oder username schon benutzt") {
      setState(() {
        _errorMessage = "Email oder username schon benutzt";
        _isLoading = false;
      });
      return;
    }

    final success = await UserApiService.login(
      email_editing_controller.text.trim(),
      password_editing_controller.text,
    );

    if (success == true) {

      setState(() => _isLoading = false);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => IntroScreen()),
      );
      //
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Stack(
        children: [
          // Dekorative Kreise
          Positioned(
            top: -80,
            right: -80,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withValues(alpha: 0.05),
              ),
            ),
          ),
          Positioned(
            bottom: -80,
            left: -80,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.tertiary.withValues(alpha: 0.05),
              ),
            ),
          ),

          Center(
            child: SafeArea(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Brand Header
                    Padding(
                      padding: const EdgeInsets.only(top: 16, bottom: 32),
                      child: Text(
                        'RANKED',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          fontStyle: FontStyle.italic,
                          color: AppColors.primary,
                          letterSpacing: -1,
                        ),
                      ),
                    ),

                    // Hero Text
                    RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 34,
                          fontWeight: FontWeight.w800,
                          color: AppColors.onSurface,
                          letterSpacing: -1,
                        ),
                        children: [
                          TextSpan(text: 'Join the '),
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
                    SizedBox(height: 8),
                    Text(
                      'Create your account to start climbing the global leaderboards.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.onSurfaceVariant,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        height: 1.5,
                      ),
                    ),

                    SizedBox(height: 36),

                    // Email Field
                    _buildTextField(
                      controller: email_editing_controller,
                      hint: 'Email Address',
                      icon: Icons.mail_outline,
                    ),
                    SizedBox(height: 12),

                    // Username Field
                    _buildTextField(
                      controller: username_editing_controller,
                      hint: 'username',
                      prefixText: '@',
                    ),
                    SizedBox(height: 12),

                    // Password Field
                    _buildTextField(
                      controller: password_editing_controller,
                      hint: 'Password',
                      icon: Icons.lock_outline,
                      obscure: _obscurePassword,
                      suffix: IconButton(
                        onPressed: () => setState(
                          () => _obscurePassword = !_obscurePassword,
                        ),
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility
                              : Icons.visibility_off,
                          color: AppColors.onSurfaceVariant,
                          size: 20,
                        ),
                      ),
                    ),
                    SizedBox(height: 12),

                    // Repeat Password Field
                    _buildTextField(
                      controller: repeat_password_editing_controller,
                      hint: 'Repeat Password',
                      icon: Icons.lock_outline,
                      obscure: true,
                    ),

                    // Fehlermeldung
                    if (_errorMessage != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(
                            color: Colors.red,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),

                    SizedBox(height: 28),

                    // Create Account Button
                    Container(
                      width: double.infinity,
                      height: 58,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [AppColors.primary, AppColors.primaryContainer],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.25),
                            blurRadius: 20,
                            offset: Offset(0, 8),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _handleCreateAccount,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: _isLoading
                            ? CircularProgressIndicator(color: Colors.white)
                            : Text(
                                'CREATE ACCOUNT',
                                style: GoogleFonts.plusJakartaSans(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 15,
                                  letterSpacing: 2,
                                ),
                              ),
                      ),
                    ),

                    SizedBox(height: 20),

                    // Community Guidelines
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

                    SizedBox(height: 16),

                    // Login Link
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Already have an account? ',
                          style: TextStyle(
                            color: AppColors.onSurfaceVariant,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Text(
                            'Log In',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ),
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
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscure,
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
              ? Icon(icon, color: AppColors.primary.withValues(alpha: 0.6), size: 20)
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
          prefixIconConstraints: BoxConstraints(minWidth: 48),
          suffixIcon: suffix,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.transparent,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }
}

class IntroScreen extends StatefulWidget {
  const IntroScreen({super.key});

  @override
  State<IntroScreen> createState() => _IntroScreenState();
}

class _IntroScreenState extends State<IntroScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  late int length;
  String _finalImageUrl = "";
  String _finalBio = '';
  int? _finalLocationId;

  // Im PageView:

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

  // Die Funktion wird super simpel:
  void _toggleVibe(String name) {
    final isActive = vibeSelections[name] ?? false;
    final activeCount = vibeSelections.values.where((v) => v).length;

    if (activeCount >= 2 && !isActive) return;

    setState(() {
      vibeSelections[name] = !isActive;
    });
  }

  Future<void> _handleNextStep() async {
    if (_currentPage < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
      return;
    }

    final List<String> selectedVibes = vibeSelections.entries
        .where((e) => e.value) // Nur aktive Einträge
        .map((e) => e.key.replaceFirst('vibecard_', ''))
        .toList();

    if (selectedVibes.length < 2) {
      return;
    }

    try {
      await UserApiService.addUserDetails(
        selectedVibes[0],
        selectedVibes[1],
        _finalImageUrl,
        _finalBio,
        locationId: _finalLocationId,
      );

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) =>
              const MyHomePage(title: 'Ranked Feed', initialLoggedIn: true),
        ),
      );
    } catch (e) {
      print("Fehler beim Speichern: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Ranked',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      fontStyle: FontStyle.italic,
                      color: AppColors.primary,
                    ),
                  ),
                  Row(
                    children: [
                      Text(
                        'Step ${_currentPage + 1} of 3',
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
                          widthFactor: (_currentPage + 1) / 3,
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
            ),

            // PageView Content
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (index) => setState(() => _currentPage = index),
                children: [
                  _buildWelcomeStep(),
                  _buildVibeStep(),
                  AboutMeStep(
                    onImageUploaded: (url) {
                      _finalImageUrl = url;
                    },
                    onAboutMeFinished: (bio) {
                      _finalBio = bio;
                    },
                    onLocationPicked: (locationId) {
                      _finalLocationId = locationId;
                    },
                  ),
                ],
              ),
            ),

            // Footer Button
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Container(
                width: double.infinity,
                height: 65,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.primary, AppColors.primaryContainer],
                  ),
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
                  onPressed: () async {
                    _handleNextStep();
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _currentPage == 1 ? 'Complete Profile' : 'Next',
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
          ],
        ),
      ),
    );
  }

  // --- STEP 1: WELCOME ---
  Widget _buildWelcomeStep() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            "Welcome to\nthe Pulse",
            style: GoogleFonts.plusJakartaSans(
              fontSize: 48,
              fontWeight: FontWeight.w900,
              height: 1,
              color: AppColors.onSurface,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            "The world’s first editorial social feed where your energy matters.",
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 40),
          _bentoItem(
            Icons.analytics,
            "Post your life",
            "Share your daily Pulse. Authentic and raw.",
            AppColors.primary,
            true,
          ),
          _bentoItem(
            Icons.military_tech,
            "Get Ranked",
            "The community evaluates your creativity.",
            AppColors.tertiaryContainer,
            false,
          ),
          _bentoItem(
            Icons.insert_emoticon_rounded,
            'Earn and customize',
            'Rank others to earn coins. Unlock exclusive avatar items and "Freundebuch" skins',
            Colors.lightGreen,
            true,
          ),
        ],
      ),
    );
  }

  // --- STEP 2: VIBES ---
  Widget _buildVibeStep() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          Text(
            "What's Your Vibe?",
            style: GoogleFonts.plusJakartaSans(
              fontSize: 32,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          const Text("Select Pulse Factors that define your daily rhythm."),
          const SizedBox(height: 30),
          Expanded(
            child: GridView.count(
              crossAxisCount: 2,
              mainAxisSpacing: 15,
              crossAxisSpacing: 15,
              childAspectRatio: 1.2,
              children: [
                _vibeCard(Icons.bolt, "Productivity"),
                _vibeCard(Icons.palette, "Creativity"),
                _vibeCard(Icons.fitness_center, "Fitness"),
                _vibeCard(Icons.sports_esports, "Gaming"),
                _vibeCard(Icons.computer, 'Coding'),
                _vibeCard(Icons.music_note, 'Music'),
                _vibeCard(Icons.book, 'Reading'),
                _vibeCard(Icons.sports_soccer, 'Sports'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _bentoItem(
    IconData icon,
    String title,
    String sub,
    Color color,
    bool rotateLeft,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        children: [
          Transform.rotate(
            angle: rotateLeft ? -0.1 : 0.1,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Icon(icon, color: Colors.white, size: 30),
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                Text(
                  sub,
                  style: const TextStyle(color: Colors.grey, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _vibeCard(IconData icon, String label) {
    bool isActive = vibeSelections[label] ?? false;

    return InkWell(
      onTap: () {
        _toggleVibe(label);
      },
      borderRadius: BorderRadius.circular(30),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: isActive
              ? LinearGradient(
                  colors: [AppColors.primary, AppColors.primaryContainer],
                )
              : null,
          color: vibeSelections[label] == true
              ? null
              : AppColors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: vibeSelections[label] == true
                  ? Colors.white
                  : AppColors.primary,
              size: 32,
            ),
            const SizedBox(height: 10),
            Text(
              label,
              style: TextStyle(
                color: vibeSelections[label] == true
                    ? Colors.white
                    : Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AboutMeStep extends StatefulWidget {
  final Function(String url) onImageUploaded;
  final Function(String bio) onAboutMeFinished;
  final Function(int locationId) onLocationPicked;

  const AboutMeStep({
    super.key,
    required this.onImageUploaded,
    required this.onAboutMeFinished,
    required this.onLocationPicked,
  });

  @override
  State<AboutMeStep> createState() => _AboutMeStepState();
}

class _AboutMeStepState extends State<AboutMeStep> {
  File? _image;
  bool _isUploading = false;
  final _picker = ImagePicker();
  late TextEditingController _bioController;
  // Nur fuer die Anzeige in der ORIGIN-Card — die id wandert per Callback
  // hoch in den IntroScreen und geht erst mit addUserDetails ans Backend.
  String? _locationName;

  Future<void> _pickLocation() async {
    final loc = await showLocationPicker(context);
    if (loc == null || !mounted) return;
    setState(() => _locationName = loc['name'] as String?);
    widget.onLocationPicked(loc['id'] as int);
  }

  @override
  void initState() {
    super.initState();
    _bioController = TextEditingController();
    _bioController.addListener(() {
      widget.onAboutMeFinished(_bioController.text);
    });
  }

  @override
  void dispose() {
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _pickAndUploadImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile == null) return;

    setState(() {
      _image = File(pickedFile.path);
      _isUploading = true;
    });

    final url = await UserApiService.uploadUserImage(_image!);
    if (url != null) {
      widget.onImageUploaded(url);
    }

    setState(() => _isUploading = false);
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          const SizedBox(height: 20),

          // --- Avatar ---
          GestureDetector(
            onTap: _pickAndUploadImage,
            child: Stack(
              alignment: Alignment.bottomRight,
              children: [
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        AppColors.primary,
                        AppColors.primaryContainer,
                        AppColors.tertiaryContainer,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.surface,
                        width: 3,
                      ),
                      color: AppColors.surfaceContainerHighest,
                    ),
                    child: ClipOval(
                      child: _isUploading
                          ? Center(
                              child: CircularProgressIndicator(
                                color: AppColors.primary,
                                strokeWidth: 2,
                              ),
                            )
                          : _image != null
                          ? Image.file(_image!, fit: BoxFit.cover)
                          : Icon(
                              Icons.person,
                              size: 44,
                              color: AppColors.primary,
                            ),
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.35),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.photo_camera,
                    color: Colors.white,
                    size: 14,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // --- Hero Text ---
          Text(
            "The Digital Pulse",
            style: GoogleFonts.plusJakartaSans(
              fontSize: 26,
              fontWeight: FontWeight.w900,
              color: AppColors.onSurface,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            "Let others feel your energy. This is your curated scrapbook entry.",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: AppColors.onSurfaceVariant,
              height: 1.5,
            ),
          ),

          const SizedBox(height: 28),

          // --- Story Label ---
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              "YOUR STORY",
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: const Color(0xFFA26769),
                letterSpacing: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 8),

          // --- Textarea with shadow effect ---
          Stack(
            children: [
              // Offset shadow layer
              Positioned(
                top: 4,
                left: 4,
                right: -4,
                bottom: -4,
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
              // Actual TextField
              TextField(
                controller: _bioController,
                maxLines: 6,
                decoration: InputDecoration(
                  hintText:
                      "Share your story, your goals, or what makes you unique...",
                  hintStyle: TextStyle(
                    color: AppColors.outlineVariant,
                    fontSize: 13,
                    height: 1.6,
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.all(16),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: AppColors.surfaceContainerHighest,
                      width: 1.5,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: AppColors.surfaceContainerHighest,
                      width: 1.5,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: AppColors.primary,
                      width: 1.5,
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // --- Bento Cards ---
          Row(
            children: [
              Expanded(
                child: _bentoCard(Icons.music_note, "PULSE MOOD", "Add Anthem"),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _bentoCard(
                  Icons.location_on,
                  "ORIGIN",
                  _locationName ?? "Add City",
                  onTap: _pickLocation,
                ),
              ),
            ],
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _bentoCard(IconData icon, String label, String value,
      {VoidCallback? onTap}) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AppColors.surfaceContainer,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: AppColors.primary, size: 18),
            ),
            const SizedBox(width: 10),
            // Expanded, damit lange Ortsnamen ("Garmisch-Partenkirchen")
            // die Row nicht sprengen, sondern mit … abgeschnitten werden.
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.inter(
                      fontSize: 8,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFFA26769),
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.onSurface,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

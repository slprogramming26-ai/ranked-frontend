
import 'package:flutter/material.dart';
import 'user_api_service.dart';
import 'onboarding/onboarding_flow.dart';
import 'app_colors.dart';

class LoginScreen extends StatefulWidget {
  final VoidCallback onLoginSuccess;

  const LoginScreen({
    super.key,
    required this.onLoginSuccess,
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  late TextEditingController email_editing_controller;
  late TextEditingController password_editing_controller;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    email_editing_controller = TextEditingController();
    password_editing_controller = TextEditingController();
  }

  @override
  void dispose() {
    email_editing_controller.dispose();
    password_editing_controller.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final success = await UserApiService.login(
      email_editing_controller.text.trim(),
      password_editing_controller.text,
    );

    if (success == true) {
      if (!mounted) return;
      widget.onLoginSuccess();
    } else {
      setState(() {
        _errorMessage = 'Ungültige E-Mail oder Passwort';
      });
    }

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: AppColors.surface,
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // 1. ASYMMETRIC HEADER
              Stack(
                children: [
                  ClipPath(
                    clipper: SkewedAppBarClipper(),
                    child: Container(
                      height: 220,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            AppColors.primary,
                            AppColors.primaryContainer,
                          ],
                        ),
                      ),
                      child: const Center(
                        child: Text(
                          'RANKED',
                          style: TextStyle(
                            fontSize: 52,
                            fontFamily: 'Plus Jakarta Sans',
                            // Falls installiert
                            fontWeight: FontWeight.w900,
                            fontStyle: FontStyle.italic,
                            color: Colors.white,
                            letterSpacing: -3,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),
                    // 2. GREETING
                    Text(
                      "Welcome back",
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        color: AppColors.onSurface,
                        letterSpacing: -1,
                      ),
                    ),
                    Text(
                      "The pulse is waiting for you.",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // 3. EMAIL INPUT
                    _buildLabel("Email Address"),
                    _buildCustomTextField(
                      controller: email_editing_controller,
                      hint: "alex@example.com",
                      icon: Icons.alternate_email,
                    ),
                    const SizedBox(height: 20),

                    // 4. PASSWORD INPUT
                    _buildLabel("Password"),
                    _buildCustomTextField(
                      controller: password_editing_controller,
                      hint: "••••••••",
                      icon: Icons.lock,
                      isPassword: true,
                    ),

                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {},
                        child: Text(
                          "Forgot password?",
                          style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),

                    if (_errorMessage != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),

                    // 5. LOGIN BUTTON
                    Container(
                      width: double.infinity,
                      height: 60,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.primary,
                            AppColors.primaryContainer,
                          ],
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
                        onPressed: _isLoading ? null : _handleLogin,
                        child: _isLoading
                            ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                            : const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    "Login to Feed",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  SizedBox(width: 10),
                                  Icon(
                                    Icons.arrow_forward,
                                    color: Colors.white,
                                  ),
                                ],
                              ),
                      ),
                    ),

                    const SizedBox(height: 40),
                    // 6. DIVIDER
                    Row(
                      children: [
                        Expanded(
                          child: Divider(
                            color: AppColors.onSurface.withValues(alpha: 0.1),
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            "OR CONTINUE WITH",
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: AppColors.onSurfaceVariant,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Divider(
                            color: AppColors.onSurface.withValues(alpha: 0.1),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // 7. SOCIAL LOGINS
                    Row(
                      children: [
                        Expanded(child: _buildSocialButton("Google", "G")),
                        // Platzhalter für Logo
                        const SizedBox(width: 16),
                        Expanded(child: _buildSocialButton("Apple", "A")),
                      ],
                    ),

                    const SizedBox(height: 40),
                    // 8. SIGN UP LINK
                    Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "New to Ranked?",
                            style: TextStyle(
                              color: AppColors.onSurfaceVariant,
                            ),
                          ),
                          TextButton(
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const OnboardingFlow(),
                              ),
                            ),
                            child: Text(
                              "Sign Up",
                              style: TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // HELPER WIDGETS FÜR DEN CLEANEN LOOK
  Widget _buildLabel(String text) {
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

  Widget _buildCustomTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool isPassword = false,
  }) {
    return TextField(
      controller: controller,
      obscureText: isPassword,
      decoration: InputDecoration(
        prefixIcon: Icon(
          icon,
          color: AppColors.onSurfaceVariant.withValues(alpha: 0.5),
        ),
        hintText: hint,
        hintStyle: TextStyle(color: AppColors.onSurface.withValues(alpha: 0.3)),
        filled: true,
        fillColor: AppColors.surfaceContainerHighest.withValues(
          alpha: 0.3,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 20),
      ),
    );
  }

  Widget _buildSocialButton(String label, String icon) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.onSurface.withValues(alpha: 0.05)),
      ),
      child: Center(
        child: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.onSurface,
          ),
        ),
      ),
    );
  }
}

class SkewedAppBarClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    Path path = Path();
    path.lineTo(0, 0); // Start oben links
    path.lineTo(size.width, 0); // Linie nach oben rechts
    path.lineTo(
      size.width,
      size.height * 0.85,
    ); // Linie nach rechts unten (bei 85% der Höhe)
    path.lineTo(0, size.height); // Schräge Linie nach ganz unten links
    path.close(); // Zurück zum Start
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
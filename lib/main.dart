import 'dart:math';

import 'package:flutter/material.dart';
import 'package:ranked/messenger/messenger.dart';
import 'package:ranked/ranking/ranking.dart';
import 'post/posts_feed.dart';
import 'profile.dart';
import 'package:google_fonts/google_fonts.dart';
import 'user_api_service.dart';
import 'api_client.dart';
import 'token_storage.dart';
import 'post/create_post.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'dart:ui';
import 'package:provider/provider.dart';
import 'post/post_provider.dart';
import 'story/story.dart';
import 'sign_in.dart';
import 'app_colors.dart';
import 'search.dart';
import 'theme_provider.dart';
import "local_data/database.dart";

void main() {
  final db = AppDatabase();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => RankingProvider()),
        ChangeNotifierProvider(create: (_) => PostProvider()),
        ChangeNotifierProvider(create: (_) => StoryProvider()),
        ChangeNotifierProvider(create: (_) => ProfileProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        Provider.value(value: db),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    // Haengt an der Dark-Mode-Wahl: setzt vor jedem Build das globale Flag in
    // AppColors und baut bei Umschaltung den kompletten Baum neu auf.
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        AppColors.isDark = themeProvider.isDark;
        return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        useMaterial3: true,
        brightness: themeProvider.isDark ? Brightness.dark : Brightness.light,
        scaffoldBackgroundColor: AppColors.surface,
        textTheme: GoogleFonts.nunitoTextTheme(),
        fontFamily: GoogleFonts.nunito().fontFamily,
        // This is the theme of your application.
        //
        // TRY THIS: Try running your application with "flutter run". You'll see
        // the application has a purple toolbar. Then, without quitting the app,
        // try changing the seedColor in the colorScheme below to Colors.green
        // and then invoke "hot reload" (save your changes or press the "hot
        // reload" button in a Flutter-supported IDE, or press "r" if you used
        // the command line to start the app).
        //
        // Notice that the counter didn't reset back to zero; the application
        // state is not lost during the reload. To reset the state, use hot
        // restart instead.
        //
        // This works for code too, not just values: Most code changes can be
        // tested with just a hot reload.
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          brightness: themeProvider.isDark ? Brightness.dark : Brightness.light,
        ),
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
        );
      },
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({
    super.key,
    required this.title,
    this.initialLoggedIn = false, // Standardmäßig false
  });

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;
  final bool initialLoggedIn;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _currentIndex = 0;
  late TextEditingController email_editing_controller;
  late TextEditingController password_editing_controller;
  bool? loggedIn; // null = loading, true = eingeloggt, false = Login-Screen
  StreamSubscription<void>? _logoutSub;
  final List<Widget> _screens = [
    PostsFeed(),
    RankingHome(),
    MessengerHomescreen(),
    Profile(),
    SearchPage(),
  ];

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    email_editing_controller = TextEditingController();
    password_editing_controller = TextEditingController();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.leanBack);
    _checkExistingSession();
    _logoutSub = ApiClient.forceLogoutStream.listen((_) async {
      if (mounted) {
        final db = context.read<AppDatabase>();
        await db.clearDatabase();
        if (mounted) {
          setState(() => loggedIn = false);
        }
      }
    });
  }

  Future<void> _checkExistingSession() async {
    final refreshToken = await TokenStorage.getRefreshToken();
    if (refreshToken == null) {
      setState(() => loggedIn = false);
      return;
    }
    final ok = await ApiClient.tryRefreshOnStart();
    setState(() => loggedIn = ok);
  }

  @override
  void dispose() {
    email_editing_controller.dispose();
    password_editing_controller.dispose();
    _logoutSub?.cancel();
    super.dispose();
  }

  bool _isLoading = false;
  String? _errorMessage;

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
      final db = context.read<AppDatabase>();
      await db.clearDatabase();
      if (mounted) {
        setState(() {
          loggedIn = true;
        });
      }
    } else {
      setState(() {
        _errorMessage = 'Ungültige E-Mail oder Passwort';
      });
    }

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final dynamic currentScreen = _screens[_currentIndex];

    if (loggedIn == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (loggedIn == true) {
      return Scaffold(
        backgroundColor: AppColors.surface,
        extendBody: true,
        body: currentScreen,
        bottomNavigationBar: _buildFloatingNav(context),
      );
    } else {
      return Scaffold(
        resizeToAvoidBottomInset: true,
        backgroundColor: AppColors.surface, // surface-bright
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
                          color: AppColors.onSurface, // on-surface
                          letterSpacing: -1,
                        ),
                      ),
                      Text(
                        "The pulse is waiting for you.",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color:
                              AppColors.onSurfaceVariant, // on-surface-variant
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
                              color: AppColors.primary.withOpacity(0.2),
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
                              color: AppColors.onSurface.withOpacity(0.1),
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
                              color: AppColors.onSurface.withOpacity(0.1),
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
                                  builder: (context) => const SignIn(),
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
          color: AppColors.onSurfaceVariant.withOpacity(0.5),
        ),
        hintText: hint,
        hintStyle: TextStyle(color: AppColors.onSurface.withOpacity(0.3)),
        filled: true,
        fillColor: AppColors.surfaceContainerHighest.withOpacity(
          0.3,
        ), // surface-container-highest
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
        color: AppColors.surfaceContainerHigh, // surface-container-high
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.onSurface.withOpacity(0.05)),
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

  Widget _buildFloatingNav(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: SizedBox(
        height: 76,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Glass bar
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.navGlass.withOpacity(0.88),
                  borderRadius: BorderRadius.circular(40),
                  border: Border.all(
                    color: AppColors.navBorder.withOpacity(0.6),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.12),
                      blurRadius: 40,
                      offset: const Offset(0, 10),
                    ),
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(40),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                    child: Row(
                      children: [
                        _buildNavTab(
                          Icons.home_outlined,
                          Icons.home_rounded,
                          0,
                        ),
                        _buildNavTab(
                          Icons.leaderboard_outlined,
                          Icons.leaderboard_rounded,
                          1,
                        ),
                        const SizedBox(width: 72),
                        _buildNavTab(
                          Icons.chat_bubble_outline_rounded,
                          Icons.chat_bubble_rounded,
                          2,
                        ),
                        _buildNavTab(
                          Icons.person_outline_rounded,
                          Icons.person_rounded,
                          3,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Center Create button (elevated above bar)
            GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CreatePost()),
              ),
              child: Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.primary, AppColors.primaryContainer],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.45),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.2),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.add_rounded,
                  color: Colors.white,
                  size: 32,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavTab(IconData icon, IconData activeIcon, int index) {
    final bool isSelected = _currentIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _currentIndex = index),
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              transitionBuilder: (child, animation) => ScaleTransition(
                scale: animation,
                child: FadeTransition(opacity: animation, child: child),
              ),
              child: Icon(
                isSelected ? activeIcon : icon,
                key: ValueKey(isSelected),
                color: isSelected
                    ? AppColors.primary
                    : AppColors.onSurfaceVariant.withOpacity(0.45),
                size: 24,
              ),
            ),
            const SizedBox(height: 5),
            AnimatedContainer(
              duration: const Duration(milliseconds: 350),
              curve: Curves.easeOutBack,
              width: isSelected ? 20 : 4,
              height: 3,
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : Colors.transparent,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ],
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

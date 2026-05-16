import 'package:flutter/material.dart';
import 'package:ranked/ranking.dart';
import 'posts_feed.dart';
import 'profile.dart';
import 'package:google_fonts/google_fonts.dart';
import 'token_storage.dart';
import 'api_service.dart';
import 'create_post.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import 'package:provider/provider.dart';
import 'post_provider.dart';
import 'sign_in.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => RankingProvider()),
        ChangeNotifierProvider(create: (_) => PostProvider()),
        ChangeNotifierProvider(create: (_) => ProfileProvider())
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
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        useMaterial3: true,
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
        colorScheme: .fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
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
  bool? loged_in = false;
  final List<Widget> _screens = [
    PostsFeed(),
    RankingHome(),
    Profile(),
  ];

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    loged_in = widget.initialLoggedIn;
    email_editing_controller = TextEditingController();
    password_editing_controller = TextEditingController();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.leanBack);

  }

  @override
  void dispose() {
    // TODO: implement dispose
    email_editing_controller.dispose();
    password_editing_controller.dispose();
    super.dispose();
  }

  bool _isLoading = false;
  String? _errorMessage;

  // In deiner _MyHomePageState:
  Future<void> _handleLogin() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final token = await ApiService.login(
      email_editing_controller.text.trim(),
      password_editing_controller.text,
    );

    if (token != null) {
      await TokenStorage.saveToken(token);
      setState(() {
        loged_in = true; // Jetzt als State-Variable statt final bool
      });
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

    if (loged_in == true)
      return Scaffold(
        backgroundColor: Color(0xFFFFF4F3),
        body: currentScreen,
        floatingActionButton: _currentIndex == 0
            ? FloatingActionButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => CreatePost()),
                  );
                },
                backgroundColor: Color(0xFFBA1C00),
                child: Text(
                  '+',
                  style: TextStyle(color: Colors.white, fontSize: 30),
                ),
              )
            : null,
        extendBody:
            true, // WICHTIG: Erlaubt dem Body, hinter die Nav-Bar zu fließen
        bottomNavigationBar: Container(
          margin: const EdgeInsets.all(20), // Lässt die Bar "schweben"
          height: 80,
          decoration: BoxDecoration(
            color: const Color(0xFFFFF4F3).withOpacity(0.8),
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFB41B00).withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(30),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10), // Glass-Effekt
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildNavItem(Icons.dynamic_feed, "Feed", 0),
                  _buildNavItem(Icons.leaderboard, "Rank", 1),
                  _buildNavItem(Icons.person, "Profile", 2),
                ],
              ),
            ),
          ),
        ),
      );
    else
      return Scaffold(
        resizeToAvoidBottomInset: true,
        backgroundColor: const Color(0xFFFFF4F3), // surface-bright
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
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xFFB41B00), Color(0xFFFF775D)],
                          ),
                        ),
                        child: const Center(
                          child: Text(
                            'RANKED',
                            style: TextStyle(
                              fontSize: 52,
                              fontFamily: 'Plus Jakarta Sans', // Falls installiert
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
                      const Text(
                        "Welcome back",
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF4D2124), // on-surface
                          letterSpacing: -1,
                        ),
                      ),
                      const Text(
                        "The pulse is waiting for you.",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF834C4F), // on-surface-variant
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
                          child: const Text(
                            "Forgot password?",
                            style: TextStyle(color: Color(0xFFB41B00), fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),

                      if (_errorMessage != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
                        ),

                      // 5. LOGIN BUTTON
                      Container(
                        width: double.infinity,
                        height: 60,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFB41B00), Color(0xFFFF775D)],
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFB41B00).withOpacity(0.2),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            )
                          ],
                        ),
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          ),
                          onPressed: _isLoading ? null : _handleLogin,
                          child: _isLoading
                              ? const CircularProgressIndicator(color: Colors.white)
                              : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text("Login to Feed", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                              SizedBox(width: 10),
                              Icon(Icons.arrow_forward, color: Colors.white),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 40),
                      // 6. DIVIDER
                      Row(
                        children: [
                          Expanded(child: Divider(color: const Color(0xFF4D2124).withOpacity(0.1))),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16),
                            child: Text("OR CONTINUE WITH", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF834C4F))),
                          ),
                          Expanded(child: Divider(color: const Color(0xFF4D2124).withOpacity(0.1))),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // 7. SOCIAL LOGINS
                      Row(
                        children: [
                          Expanded(child: _buildSocialButton("Google", "G")), // Platzhalter für Logo
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
                            const Text("New to Ranked?", style: TextStyle(color: Color(0xFF834C4F))),
                            TextButton(
                              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const SignIn())),
                              child: const Text("Sign Up", style: TextStyle(color: Color(0xFFB41B00), fontWeight: FontWeight.w900)),
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
      child: Text(text.toUpperCase(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.2, color: Color(0xFF834C4F))),
    );
  }

  Widget _buildCustomTextField({required TextEditingController controller, required String hint, required IconData icon, bool isPassword = false}) {
    return TextField(
      controller: controller,
      obscureText: isPassword,
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: const Color(0xFF834C4F).withOpacity(0.5)),
        hintText: hint,
        hintStyle: TextStyle(color: const Color(0xFF4D2124).withOpacity(0.3)),
        filled: true,
        fillColor: const Color(0xFFFFD2D3).withOpacity(0.3), // surface-container-highest
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(vertical: 20),
      ),
    );
  }

  Widget _buildSocialButton(String label, String icon) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: const Color(0xFFFFDADA), // surface-container-high
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF4D2124).withOpacity(0.05)),
      ),
      child: Center(child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF4D2124)))),
    );
  }


  Widget _buildNavItem(IconData icon, String label, int index) {
    bool isSelected = _currentIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: isSelected
            ? BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFB41B00), Color(0xFFFF775D)],
                ),
                borderRadius: BorderRadius.circular(20),
              )
            : null,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : const Color(0xFF4D2124),
            ),
            if (isSelected)
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
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

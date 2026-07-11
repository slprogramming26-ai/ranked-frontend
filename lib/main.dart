import 'package:flutter/material.dart';
import 'package:ranked/messenger/messenger.dart';
import 'package:ranked/ranking/ranking.dart';
import 'post/posts_feed.dart';
import 'profile.dart';
import 'package:google_fonts/google_fonts.dart';
import 'api_client.dart';
import 'token_storage.dart';
import 'post/create_post.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'package:provider/provider.dart';
import 'post/post_provider.dart';
import 'story/story.dart';
import 'story/story_create_screen.dart';
import 'app_colors.dart';
import 'search.dart';
import 'theme_provider.dart';
import "local_data/database.dart";
import 'messenger/messenger_controller.dart';
import 'package:image_picker/image_picker.dart';
import 'login_screen.dart';
import 'floating_nav.dart';

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
        // Besitzt den MessengerApiService fuer die ganze Login-Session
        // (Verdrahtung mit Login/Logout folgt in Schritt 2).
        ChangeNotifierProvider(create: (_) => MessengerController()),
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
            brightness: themeProvider.isDark
                ? Brightness.dark
                : Brightness.light,
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
              brightness: themeProvider.isDark
                  ? Brightness.dark
                  : Brightness.light,
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
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.leanBack);
    _checkExistingSession();
    _logoutSub = ApiClient.forceLogoutStream.listen((_) async {
      if (mounted) {
        final db = context.read<AppDatabase>();
        // ERST den Messenger stoppen, DANN die DB leeren: der Service
        // persistiert eingehende Nachrichten in die DB — andersrum koennte
        // zwischen Leeren und Stoppen noch eine Nachricht reinschreiben.
        await context.read<MessengerController>().shutdown();
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
    if (!mounted) return;
    setState(() => loggedIn = ok);
    if (ok) {
      _startMessenger();
      _recoverLostPostDraft();
    }
  }

  // Startet den app-weiten Messenger (WebSocket fuer die ganze Session).
  // Wird von BEIDEN Login-Pfaden gerufen: Session-Restore + frischer Login.
  // Doppelt aufrufen ist dank Idempotenz-Guard im Controller ungefaehrlich.
  Future<void> _startMessenger() async {
    final provider = context.read<ProfileProvider>();
    final db = context.read<AppDatabase>();
    final controller = context.read<MessengerController>();
    await provider.fetchUser();
    if (!mounted) return;
    final userId = provider.userdata["id"] as int;
    await controller.init(db, userId);
  }

  Future<void> _recoverLostPostDraft() async {
    final db = context.read<AppDatabase>();

    // Android-only: "Hat der letzte Prozess ein Kamerabild angefordert,
    // das nie ankam?" Wirft nie - alle Ausgaenge kommen als Daten zurueck.
    // Auf iOS ist die Antwort immer isEmpty.
    final lost = await ImagePicker().retrieveLostData();
    final lostFile = lost.file;
    final draft = await db.getPostDraft();

    if (lostFile != null) {
      // Ein verlorenes Foto heisst: der Kill passierte GERADE EBEN mitten im
      // Kamera-Flow -> ohne Nachfrage direkt zurueck in den Screen, der die
      // Kamera angefordert hatte (draftType), als waere nichts gewesen.
      if (draft != null && draft.draftType == 'story') {
        // Marker verbraucht; das Foto reist per Konstruktor mit.
        await db.deletePostDraft();
        if (!mounted) return;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                StoryCreateScreen(recoveredImagePath: lostFile.path),
          ),
        );
        return;
      }
      await db.attachImageToPostDraft(lostFile.path);
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const CreatePost()),
      );
      return;
    }

    if (draft == null) return;

    // Story-Marker ohne gerettetes Foto: Kill vor dem Abdruecken -> bei
    // Stories gibt es nichts wiederherzustellen, nur aufraeumen.
    if (draft.draftType == 'story') {
      await db.deletePostDraft();
      return;
    }

    // Post-Entwurf ohne Foto: Kill lag vor dem Abdruecken oder laenger
    // zurueck -> hier erst fragen statt ungefragt zu navigieren.
    if (!mounted) return;

    final restore = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Entwurf wiederherstellen?'),
        content: const Text('Du hast einen unfertigen Post.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Verwerfen'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Wiederherstellen'),
          ),
        ],
      ),
    );
    if (!mounted) return;

    if (restore == true) {
      // CreatePost laedt den Entwurf selbst (fetchPostDraft in initState).
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const CreatePost()),
      );
    } else {
      await db.deletePostDraft();
    }
  }

  @override
  void dispose() {
    _logoutSub?.cancel();
    super.dispose();
  }

  Future<void> _onLoginSuccess() async {
    final db = context.read<AppDatabase>();
    await db.clearDatabase();
    if (mounted) {
      setState(() {
        loggedIn = true;
      });
      _startMessenger();
    }
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
        bottomNavigationBar: FloatingNavBar(
          currentIndex: _currentIndex,
          onTabSelected: (i) => setState(() => _currentIndex = i),
        ),
      );
    } else {
      return LoginScreen(onLoginSuccess: _onLoginSuccess);
    }
  }

}

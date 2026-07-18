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
import 'post/comment_provider.dart';
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
import 'splash_screen.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';

Future<void> main() async {
  // Haelt den nativen OS-Splash fest, bis Flutter seinen ersten Frame fertig
  // hat (remove() ruft der SplashScreen selbst). Ohne preserve() gaebe es
  // zwischen OS-Splash und erstem Flutter-Frame einen kurzen weissen Blitzer.
  final widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  // Dark-Mode-Wahl VOR dem ersten Frame laden (der native Splash steht noch),
  // sonst startet die App hell und springt sichtbar auf dunkel um.
  final themeProvider = await ThemeProvider.load();

  final db = AppDatabase();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => RankingProvider()),
        ChangeNotifierProvider(create: (_) => PostProvider()),
        ChangeNotifierProvider(create: (_) => CommentProvider()),
        ChangeNotifierProvider(create: (_) => StoryProvider()),
        ChangeNotifierProvider(create: (_) => ProfileProvider()),
        ChangeNotifierProvider.value(value: themeProvider),
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
  late final ThemeProvider _themeProvider;
  // Lazy IndexedStack: Jeder Tab wird erst beim ERSTEN Besuch gebaut
  // (_screens[i] bleibt bis dahin null) und lebt danach im IndexedStack
  // weiter — kein dispose/remount mehr beim Tab-Wechsel, Feed und
  // Scroll-Position bleiben erhalten.
  final List<Widget Function()> _screenBuilders = [
    () => PostsFeed(),
    () => RankingHome(),
    () => MessengerHomescreen(),
    () => Profile(),
    () => SearchPage(),
  ];
  late final List<Widget?> _screens =
      List<Widget?>.filled(_screenBuilders.length, null);

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.leanBack);
    _checkExistingSession();
    // Bereits gebaute Tabs lesen AppColors nur beim eigenen Build — ohne
    // diesen Listener bleiben sie nach einem Dark-Mode-Toggle in den alten
    // Farben haengen (siehe Kommentar am Screen-Cache oben).
    _themeProvider = context.read<ThemeProvider>();
    _themeProvider.addListener(_onThemeChanged);
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
    // Mindestanzeigedauer des Splashs: laeuft PARALLEL zum Token-Check (der
    // Timer startet jetzt, nicht nach dem Check). Ein Splash, der nach 150ms
    // wieder wegblitzt, wirkt wie ein Glitch — also warten wir am Ende auf
    // beides: Ergebnis da UND Minimum abgelaufen.
    final minSplash = Future<void>.delayed(const Duration(milliseconds: 1100));

    final refreshToken = await TokenStorage.getRefreshToken();
    final ok = refreshToken == null
        ? false
        : await ApiClient.tryRefreshOnStart();

    await minSplash;
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

  // Wirft alle bereits gebauten Tabs weg, damit sie beim naechsten Anzeigen
  // mit den aktuellen AppColors neu gebaut werden. Kostet Scroll-Position
  // etc. der Tabs, aber ein Dark-Mode-Toggle ist selten genug, dass das ok ist.
  void _onThemeChanged() {
    if (!mounted) return;
    setState(() {
      for (var i = 0; i < _screens.length; i++) {
        _screens[i] = null;
      }
    });
  }

  @override
  void dispose() {
    _themeProvider.removeListener(_onThemeChanged);
    _logoutSub?.cancel();
    super.dispose();
  }

  Future<void> _onLoginSuccess() async {
    final db = context.read<AppDatabase>();
    await db.clearDatabase();
    if (mounted) {
      setState(() {
        // Tab-Cache leeren: sonst wuerden nach einem Re-Login alle vorher
        // besuchten Tabs sofort gleichzeitig starten (und ggf. Daten des
        // alten Users zeigen). So startet der neue User wieder lazy bei Tab 0.
        for (var i = 0; i < _screens.length; i++) {
          _screens[i] = null;
        }
        _currentIndex = 0;
        loggedIn = true;
      });
      _startMessenger();
    }
  }

  @override
  Widget build(BuildContext context) {
    // AnimatedSwitcher blendet zwischen den drei Zustaenden (Splash / Home /
    // Login) weich ueber, statt hart umzuschalten. Er vergleicht Kinder per
    // Key: gleicher Key = kein Uebergang, nur Rebuild — deshalb bekommt jeder
    // Zustand einen festen ValueKey (Tab-Wechsel innerhalb von Home bleiben
    // dadurch uebergangsfrei).
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 450),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeIn,
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        // Leichter Zoom dazu: Neues waechst von 97% auf 100%, das alte
        // schrumpft beim Ausblenden (gleiche Animation rueckwaerts).
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.97, end: 1).animate(animation),
          child: child,
        ),
      ),
      child: _buildCurrentState(),
    );
  }

  Widget _buildCurrentState() {
    if (loggedIn == null) {
      return const SplashScreen(key: ValueKey('splash'));
    }

    if (loggedIn == true) {
      // Aktuellen Tab bauen, falls er zum ersten Mal besucht wird.
      _screens[_currentIndex] ??= _screenBuilders[_currentIndex]();
      return Scaffold(
        key: const ValueKey('home'),
        backgroundColor: AppColors.surface,
        extendBody: true,
        // IndexedStack haelt alle bereits gebauten Tabs im Baum und zeigt nur
        // den aktiven — die anderen behalten ihren State, werden aber nicht
        // gemalt. Unbesuchte Tabs sind nur leere Platzhalter.
        body: IndexedStack(
          index: _currentIndex,
          children: [
            for (final screen in _screens) screen ?? const SizedBox.shrink(),
          ],
        ),
        bottomNavigationBar: FloatingNavBar(
          currentIndex: _currentIndex,
          onTabSelected: (i) => setState(() => _currentIndex = i),
        ),
      );
    }

    return LoginScreen(
      key: const ValueKey('login'),
      onLoginSuccess: _onLoginSuccess,
    );
  }

}

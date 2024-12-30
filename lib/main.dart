import 'package:flutter/material.dart';
import 'package:notewave/pages/notespage.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'firebase_options.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:notewave/services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  MobileAds.instance.initialize();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  final NotificationService notificationService = NotificationService();
  await notificationService.initialize();

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _isDarkMode = false;
  late AppOpenAdManager _appOpenAdManager;

  @override
  void initState() {
    super.initState();
    _loadThemeMode();
    _appOpenAdManager = AppOpenAdManager();
    _appOpenAdManager.loadAd();
    Future.delayed(Duration(seconds: 1), () {
      _showAppOpenAd();
    });
  }

  Future<void> _loadThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isDarkMode = prefs.getBool('dark_mode') ?? false;
    });
  }

  void _toggleTheme(bool value) {
    setState(() {
      _isDarkMode = value;
    });
  }

  // Show the app open ad when the app is launched
  void _showAppOpenAd() {
    if (_appOpenAdManager.isAdAvailable) {
      _appOpenAdManager.showAdIfAvailable();
    } else {
      print('AppOpenAd not ready.');
    }
  }

  @override
  void dispose() {
    _appOpenAdManager
        .dispose(); // Dispose of the ad manager when the app is closed
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ThemeProvider(
      isDarkMode: _isDarkMode,
      toggleTheme: _toggleTheme,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'NoteWave',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.deepPurple,
            brightness: Brightness.light,
          ),
          useMaterial3: true,
          scaffoldBackgroundColor: Colors.white,
          cardColor: Colors.white,
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.white,
            foregroundColor: Colors.black,
          ),
        ),
        darkTheme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.deepPurple,
            brightness: Brightness.dark,
          ),
          useMaterial3: true,
          scaffoldBackgroundColor: Colors.grey[900],
          cardColor: Colors.grey[850],
          appBarTheme: AppBarTheme(
            backgroundColor: Colors.grey[900],
            foregroundColor: Colors.white,
          ),
        ),
        themeMode: _isDarkMode ? ThemeMode.dark : ThemeMode.light,
        home: const NotesPage(),
      ),
    );
  }
}

class AppOpenAdManager {
  String adUnitId =
      'ca-app-pub-3940256099942544/9257395921'; // Test Ad Unit ID, replace with your real Ad Unit ID
  AppOpenAd? _appOpenAd;
  bool _isShowingAd = false;

  /// Load an AppOpenAd.
  void loadAd() {
    print('Loading AppOpenAd...');
    AppOpenAd.load(
      adUnitId: adUnitId,
      request: AdRequest(),
      adLoadCallback: AppOpenAdLoadCallback(
        onAdLoaded: (ad) {
          _appOpenAd = ad;
          print('AppOpenAd loaded successfully');
        },
        onAdFailedToLoad: (error) {
          print('AppOpenAd failed to load: $error');
        },
      ),
    );
  }

  /// Show the ad if available.
  void showAdIfAvailable() {
    if (_appOpenAd == null) {
      print('Ad not loaded yet.');
      loadAd(); // Reload the ad if not loaded
      return;
    }
    if (_isShowingAd) {
      print('Ad is already showing.');
      return;
    }

    print('Showing App Open Ad...');

    // Set the fullScreenContentCallback and show the ad.
    _appOpenAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (ad) {
        _isShowingAd = true;
        print('$ad onAdShowedFullScreenContent');
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        print('$ad onAdFailedToShowFullScreenContent: $error');
        _isShowingAd = false;
        ad.dispose();
        _appOpenAd = null;
      },
      onAdDismissedFullScreenContent: (ad) {
        print('$ad onAdDismissedFullScreenContent');
        _isShowingAd = false;
        ad.dispose();
        _appOpenAd = null;
        loadAd(); // Reload the ad after dismissal
      },
    );

    _appOpenAd!.show(); // Show the ad if available
  }

  /// Whether an ad is available to be shown.
  bool get isAdAvailable => _appOpenAd != null;

  void dispose() {
    _appOpenAd?.dispose();
  }
}

class ThemeProvider extends InheritedWidget {
  final bool isDarkMode;
  final Function(bool) toggleTheme;

  const ThemeProvider({
    Key? key,
    required Widget child,
    required this.isDarkMode,
    required this.toggleTheme,
  }) : super(key: key, child: child);

  static ThemeProvider? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<ThemeProvider>();
  }

  @override
  bool updateShouldNotify(ThemeProvider oldWidget) {
    return isDarkMode != oldWidget.isDarkMode;
  }
}

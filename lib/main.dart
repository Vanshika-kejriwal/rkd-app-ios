// import 'dart:js';

// ignore_for_file: prefer_const_constructors

// import 'package:device_preview/device_preview.dart';

// import 'package:business_app/models/leads.dart';
import 'dart:io';

import 'package:business_app/permissions/permitrequest.dart';
import 'package:business_app/screens/dashboard.dart';
import 'package:business_app/screens/login_screen.dart';

import 'package:business_app/screens/splash_screen.dart';
// import 'package:business_app/screens/user_registration.dart';
import 'package:business_app/services/network_provider.dart';
import 'package:business_app/widgets/no_internet.dart';
// import 'package:business_app/services/notification_service.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:upgrader/upgrader.dart';
import 'firebase_options.dart';

// import 'package:responsive_sizer/responsive_sizer.dart';
//import 'package:responsive_sizer/responsive_sizer.dart';
//import 'package:sizer/sizer.dart';
@pragma("vm:entry-point")
Future<void> _firebaseBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // await Upgrader().initialize();
  if (kDebugMode) {
    await Upgrader.clearSavedSettings();
  }
  Permitrequest permitrequest = Permitrequest();
  // NotificationService notificationService = NotificationService();
  await permitrequest.askLocationPermission();

  // await permitrequest.askNotificationPermission();
  // camera permission
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  FirebaseMessaging.onBackgroundMessage(_firebaseBackgroundHandler);
  runApp(MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (context) => NetworkProvider()),
    ],
    child: const MyApp(),
  ));
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();

    subscribe();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.orange,
        useMaterial3: true,
      ),
      home: UpgradeAlert(
          upgrader: Upgrader(debugLogging: true),
          // barrierDismissible: false,
          showIgnore: false,
          showLater: false,
          showReleaseNotes: false,
          child: AppRoot()),
      builder: (context, child) {
        return Stack(
          children: [
            child!,
            Consumer<NetworkProvider>(
              builder: (context, networkProvider, child) {
                return networkProvider.isOnline
                    ? const SizedBox()
                    : const NoInternetScreen();
              },
            ),
          ],
        );
      },
    );
  }
}

class AppRoot extends StatefulWidget {
  const AppRoot({super.key});
  @override
  State<AppRoot> createState() => _AppRootState();
}

class _AppRootState extends State<AppRoot> with WidgetsBindingObserver {
  bool _showSplash = true;
  Widget? _nextScreen;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _cleanupfiles();
    _init();
  }

  Future<void> _cleanupfiles() async {
    try {
      final dir = await getTemporaryDirectory();

      // 1. Get the list of all items (files and directories) inside the temp folder
      final items = dir.listSync(recursive: false);

      for (var item in items) {
        try {
          // 2. Attempt to delete each item.
          // recursive: true is crucial for deleting subdirectories (like share_plus)
          await item.delete(recursive: true);
        } on FileSystemException catch (e) {
          // 3. Silently catch errors caused by locked files (errno 39)
          // Check for the specific FileSystemException code if possible (platform-dependent)
          // On Linux/Android, errno 39 is typically 'Directory not empty'
          if (kDebugMode) {
            print(
                "Warning: Could not delete locked item: ${item.path}. Error: $e");
          }
          // DO NOT RETHROW. Just allow the loop to continue.
        } catch (e) {
          if (kDebugMode) {
            print("Error cleaning up file: ${item.path}. Error: $e");
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print("Error accessing temporary directory: $e");
      }
    }
  }

  // @override
  // void didChangeAppLifecycleState(AppLifecycleState state) {
  //   super.didChangeAppLifecycleState(state);
  //   if (state == AppLifecycleState.resumed) {
  //     _cleanupfiles();
  //   }
  // }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cleanupfiles();
    super.dispose();
  }

  Future<void> _init() async {
    // Keep splash for 3s
    await Future.delayed(const Duration(seconds: 2));

    // Decide where to go next (e.g., check login state, prefs, etc.)
    bool loggedIn = await _isUserLoggedIn();
    var ut = await SharedPreferences.getInstance();
    var userType = ut.getString("UT") ?? "";

    if (mounted) {
      setState(() {
        _showSplash = false;
        _nextScreen = loggedIn ? Dashboard(ut: userType) : LoginScreen();
      });
    }
  }

  Future<bool> _isUserLoggedIn() async {
    // Your logic: check SharedPreferences, token, API call, etc.
    var sharedpref = await SharedPreferences.getInstance();
    var isLoggedIn = sharedpref.getBool("Login");
    if (isLoggedIn != null && isLoggedIn) {
      return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    if (_showSplash) {
      return SplashScreen();
    } else {
      return _nextScreen!;
    }
  }
}

void subscribe() {
  if (!kIsWeb) {
    FirebaseMessaging messaging = FirebaseMessaging.instance;
    messaging.subscribeToTopic("all");
    if (kDebugMode) {
      messaging.subscribeToTopic("test");
    }
  }
}

// Remove GoRouter and use MaterialApp with routes

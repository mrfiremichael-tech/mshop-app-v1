import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/app_controller.dart';
import 'core/localization/app_localizations.dart';
import 'firebase_options.dart';
import 'services/auth_service.dart';

import 'screens/auth/login_screen.dart';
import 'screens/pharmacy/pharmacy_dashboard.dart';
import 'screens/pharmacy/staff/staff_dashboard.dart';
import 'screens/mshop_owner/mshop_owner_dashboard.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  final appController = AppController();

  runApp(
    MShopApp(
      appController: appController,
    ),
  );
}

/*
|--------------------------------------------------------------------------
| GLOBAL NAVIGATOR
|--------------------------------------------------------------------------
*/

final GlobalKey<NavigatorState>
    mshopNavigatorKey =
    GlobalKey<NavigatorState>();

/*
|--------------------------------------------------------------------------
| SESSION SETTINGS
|--------------------------------------------------------------------------
*/

const Duration mshopSessionTimeout =
    Duration(minutes: 30);

/*
|--------------------------------------------------------------------------
| APP
|--------------------------------------------------------------------------
*/

class MShopApp extends StatelessWidget {
  final AppController appController;

  const MShopApp({
    super.key,
    required this.appController,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: appController,
      builder: (context, _) {
        return MaterialApp(
          navigatorKey:
              mshopNavigatorKey,

          debugShowCheckedModeBanner:
              false,

          title: 'M-Shop Pharmacy',

          locale:
              appController.locale,

          themeMode:
              appController.themeMode,

          supportedLocales: const [
            Locale('en'),
            Locale('sw'),
          ],

          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],

          theme: ThemeData(
            useMaterial3: true,

            colorScheme:
                ColorScheme.fromSeed(
              seedColor:
                  const Color(0xFF00875A),
              brightness:
                  Brightness.light,
            ),

            scaffoldBackgroundColor:
                const Color(0xFFF8FAF9),

            appBarTheme:
                const AppBarTheme(
              centerTitle: false,
              elevation: 0,
            ),
          ),

          darkTheme: ThemeData(
            useMaterial3: true,

            colorScheme:
                ColorScheme.fromSeed(
              seedColor:
                  const Color(0xFF00875A),
              brightness:
                  Brightness.dark,
            ),

            scaffoldBackgroundColor:
                const Color(0xFF101614),

            appBarTheme:
                const AppBarTheme(
              centerTitle: false,
              elevation: 0,
            ),
          ),

          home: SplashScreen(
            appController:
                appController,
          ),

          routes: {
            '/login': (context) =>
                LoginScreen(
                  appController:
                      appController,
                ),

            '/pharmacy-dashboard':
                (context) =>
                    PharmacyDashboard(
                  appController:
                      appController,
                ),
          },

          builder: (
            context,
            child,
          ) {
            return SessionTimeoutManager(
              child:
                  child ??
                  const SizedBox(),
            );
          },
        );
      },
    );
  }
}

/*
|--------------------------------------------------------------------------
| SESSION TIMEOUT MANAGER
|--------------------------------------------------------------------------
*/

class SessionTimeoutManager
    extends StatefulWidget {
  final Widget child;

  const SessionTimeoutManager({
    super.key,
    required this.child,
  });

  @override
  State<SessionTimeoutManager>
      createState() =>
          _SessionTimeoutManagerState();
}

class _SessionTimeoutManagerState
    extends State<SessionTimeoutManager>
    with WidgetsBindingObserver {

  Timer? _timer;

  StreamSubscription<User?>?
      _authListener;

  DateTime? _lastActivity;

  bool _dialogVisible = false;

  bool _inBackground = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance
        .addObserver(this);

    _authListener =
        FirebaseAuth.instance
            .authStateChanges()
            .listen(
      (user) {
        if (user == null) {
          _timer?.cancel();
          _lastActivity = null;
          return;
        }

        _registerActivity();
      },
    );

    _registerActivity();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _authListener?.cancel();

    WidgetsBinding.instance
        .removeObserver(this);

    super.dispose();
  }

  /*
  |--------------------------------------------------------------------------
  | REGISTER ACTIVITY
  |--------------------------------------------------------------------------
  */

  void _registerActivity() {
    final user =
        FirebaseAuth.instance.currentUser;

    if (user == null) {
      return;
    }

    if (_inBackground) {
      return;
    }

    _lastActivity =
        DateTime.now();

    _scheduleTimeout();
  }

  /*
  |--------------------------------------------------------------------------
  | SCHEDULE
  |--------------------------------------------------------------------------
  */

  void _scheduleTimeout() {
    _timer?.cancel();

    final user =
        FirebaseAuth.instance.currentUser;

    final last =
        _lastActivity;

    if (user == null ||
        last == null ||
        _inBackground) {
      return;
    }

    final elapsed =
        DateTime.now()
            .difference(last);

    final remaining =
        mshopSessionTimeout -
        elapsed;

    if (remaining <=
        Duration.zero) {
      _checkForegroundTimeout();
      return;
    }

    _timer = Timer(
      remaining,
      _checkForegroundTimeout,
    );
  }

  /*
  |--------------------------------------------------------------------------
  | FOREGROUND TIMEOUT
  |--------------------------------------------------------------------------
  */

  Future<void>
      _checkForegroundTimeout() async {
    final user =
        FirebaseAuth.instance.currentUser;

    if (user == null ||
        _inBackground ||
        _dialogVisible) {
      return;
    }

    final last =
        _lastActivity;

    if (last == null) {
      _registerActivity();
      return;
    }

    final elapsed =
        DateTime.now()
            .difference(last);

    if (elapsed <
        mshopSessionTimeout) {
      _scheduleTimeout();
      return;
    }

    await _showSessionDialog();
  }

  /*
  |--------------------------------------------------------------------------
  | SESSION DIALOG
  |--------------------------------------------------------------------------
  */

  Future<void>
      _showSessionDialog() async {
    if (_dialogVisible) {
      return;
    }

    final user =
        FirebaseAuth.instance.currentUser;

    final context =
        mshopNavigatorKey.currentContext;

    if (user == null ||
        context == null) {
      return;
    }

    _dialogVisible = true;

    final continueSession =
        await showDialog<bool>(
      context: context,

      barrierDismissible:
          false,

      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'Session Timeout',
          ),

          content: const Text(
            'You have been inactive for 30 minutes. Do you want to continue using M-Shop?',
          ),

          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(
                  dialogContext,
                ).pop(false);
              },
              child: const Text(
                'Logout',
              ),
            ),

            FilledButton(
              onPressed: () {
                Navigator.of(
                  dialogContext,
                ).pop(true);
              },
              child: const Text(
                'Continue',
              ),
            ),
          ],
        );
      },
    );

    _dialogVisible = false;

    if (!mounted) {
      return;
    }

    if (continueSession ==
        true) {
      _registerActivity();
      return;
    }

    await _logout();
  }

  /*
  |--------------------------------------------------------------------------
  | LOGOUT
  |--------------------------------------------------------------------------
  */

  Future<void> _logout() async {
    _timer?.cancel();

    try {
      await FirebaseAuth.instance
          .signOut();
    } catch (error) {
      debugPrint(
        'SESSION LOGOUT ERROR: $error',
      );
    }

    if (!mounted) {
      return;
    }

    mshopNavigatorKey.currentState
        ?.pushNamedAndRemoveUntil(
      '/login',
      (route) => false,
    );
  }

  /*
  |--------------------------------------------------------------------------
  | APP LIFECYCLE
  |--------------------------------------------------------------------------
  */

  @override
  void didChangeAppLifecycleState(
    AppLifecycleState state,
  ) {
    switch (state) {
      case AppLifecycleState.resumed:
        _inBackground = false;
        _checkAfterResume();
        break;

      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
        _inBackground = true;
        _timer?.cancel();
        break;

      case AppLifecycleState.detached:
        _inBackground = true;
        _timer?.cancel();
        break;
    }
  }

  /*
  |--------------------------------------------------------------------------
  | CHECK AFTER BACKGROUND
  |--------------------------------------------------------------------------
  */

  Future<void>
      _checkAfterResume() async {
    final user =
        FirebaseAuth.instance.currentUser;

    if (user == null) {
      return;
    }

    final last =
        _lastActivity;

    if (last == null) {
      _registerActivity();
      return;
    }

    final elapsed =
        DateTime.now()
            .difference(last);

    if (elapsed >=
        mshopSessionTimeout) {
      await _logout();
      return;
    }

    _scheduleTimeout();
  }

  /*
  |--------------------------------------------------------------------------
  | USER INPUT
  |--------------------------------------------------------------------------
  */

  void _handlePointerDown(
    PointerDownEvent event,
  ) {
    _registerActivity();
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    return Listener(
      behavior:
          HitTestBehavior.translucent,

      onPointerDown:
          _handlePointerDown,

      child: Focus(
        onKeyEvent: (
          node,
          event,
        ) {
          _registerActivity();

          return KeyEventResult
              .ignored;
        },

        child:
            widget.child,
      ),
    );
  }
}

/*
|--------------------------------------------------------------------------
| SPLASH
|--------------------------------------------------------------------------
*/

class SplashScreen
    extends StatefulWidget {
  final AppController appController;

  const SplashScreen({
    super.key,
    required this.appController,
  });

  @override
  State<SplashScreen> createState() =>
      _SplashScreenState();
}

class _SplashScreenState
    extends State<SplashScreen> {

  @override
  void initState() {
    super.initState();

    _startSplash();
  }

  Future<void> _startSplash() async {
    await Future.delayed(
      const Duration(
        seconds: 3,
      ),
    );

    if (!mounted) {
      return;
    }

    await _openCorrectScreen();
  }

  /*
  |--------------------------------------------------------------------------
  | EXISTING SESSION
  |--------------------------------------------------------------------------
  */

  Future<void>
      _openCorrectScreen() async {
    final user =
        FirebaseAuth.instance.currentUser;

    if (!mounted) {
      return;
    }

    if (user == null) {
      _openLogin();
      return;
    }

    try {
      final profile =
          await AuthService()
              .getCurrentUserProfile();

      if (!mounted) {
        return;
      }

      if (profile == null) {
        _openLogin();
        return;
      }

      final role =
          profile['role']
              ?.toString()
              .trim()
              .toLowerCase();

      if (role ==
          'mshop_owner') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) =>
                MshopOwnerDashboard(
              appController:
                  widget.appController,
            ),
          ),
        );

        return;
      }

      if (role ==
          'pharmacy_owner') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) =>
                PharmacyDashboard(
              appController:
                  widget.appController,
            ),
          ),
        );

        return;
      }

      if (role ==
          'staff') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) =>
                StaffDashboard(
              appController:
                  widget.appController,
            ),
          ),
        );

        return;
      }

      await FirebaseAuth.instance
          .signOut();

      if (!mounted) {
        return;
      }

      _openLogin();
    } catch (error) {
      debugPrint(
        'SESSION CHECK ERROR: $error',
      );

      if (!mounted) {
        return;
      }

      _openLogin();
    }
  }

  void _openLogin() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) =>
            LoginScreen(
          appController:
              widget.appController,
        ),
      ),
    );
  }

  /*
  |--------------------------------------------------------------------------
  | SPLASH UI
  |--------------------------------------------------------------------------
  */

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      backgroundColor:
          Colors.white,

      body: Center(
        child: Padding(
          padding:
              const EdgeInsets.all(32),

          child: Image.asset(
            'assets/images/mshop_logo.png',
            width: 260,
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}

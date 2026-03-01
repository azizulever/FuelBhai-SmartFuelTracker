import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mileage_calculator/screens/auth/login_screen.dart';
import 'package:mileage_calculator/screens/onboarding_screen.dart';
import 'package:mileage_calculator/screens/splash_screen.dart';
import 'package:mileage_calculator/services/auth_service.dart';
import 'package:mileage_calculator/services/fueling_service.dart';
import 'package:mileage_calculator/services/service_trip_sync.dart';
import 'package:mileage_calculator/utils/theme.dart';
import 'package:mileage_calculator/widgets/main_navigation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:mileage_calculator/firebase_options.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mileage_calculator/services/analytics_service.dart';
import 'package:mileage_calculator/services/crashlytics_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Initialize Crashlytics global error handlers
  Get.put(CrashlyticsService());
  await CrashlyticsService.init();

  // Initialize Analytics service
  Get.put(AnalyticsService());

  // Initialize AuthService first and check guest mode
  final authService = Get.put(AuthService());

  // Wait for guest mode check to complete before initializing other services
  await authService.checkGuestMode();

  // Now initialize other services - they can properly detect guest mode
  Get.put(FuelingService());
  Get.put(ServiceTripSyncService());

  runApp(const MileageCalculatorApp());
}

class MileageCalculatorApp extends StatelessWidget {
  const MileageCalculatorApp({super.key});

  @override
  Widget build(BuildContext context) {
    final analyticsService = Get.find<AnalyticsService>();
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'FuelBhai',
      theme: appTheme,
      navigatorObservers: [analyticsService.observer],
      home: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({Key? key}) : super(key: key);

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _isLoading = true;
  bool _shouldShowOnboarding = false;
  bool _shouldShowWelcome = true;

  @override
  void initState() {
    super.initState();
    _checkAuthState();
  }

  Future<void> _checkAuthState() async {
    // Minimum splash display time so it doesn't flash away instantly
    final minSplash = Future.delayed(const Duration(milliseconds: 1500));

    final prefs = await SharedPreferences.getInstance();
    final onboardingCompleted = prefs.getBool('onboarding_completed') ?? false;
    final skippedLogin = prefs.getBool('skipped_login') ?? false;

    // Get current Firebase user
    Get.find<AuthService>();
    final currentUser = FirebaseAuth.instance.currentUser;

    // Start data fetching/syncing immediately and wait for it to finish
    // (with a 10-second timeout so we never hang on the splash screen).
    // Also run the minimum splash delay in parallel.
    if (onboardingCompleted) {
      if (skippedLogin && currentUser == null) {
        // Guest mode — load local data
        await Future.wait([
          minSplash,
          Future.any([
            _loadGuestDataOnStartup(),
            Future.delayed(const Duration(seconds: 10)),
          ]),
        ]);
      } else if (currentUser != null) {
        // Logged-in user — sync from Firebase
        await Future.wait([
          minSplash,
          Future.any([
            _syncDataOnStartup(),
            Future.delayed(const Duration(seconds: 10)),
          ]),
        ]);
      } else {
        // Not onboarded but no user — just wait for min splash
        await minSplash;
      }
    } else {
      // First time user — just wait for min splash
      await minSplash;
    }

    // Determine which screen to show
    if (!onboardingCompleted) {
      if (mounted) {
        setState(() {
          _shouldShowOnboarding = true;
          _shouldShowWelcome = false;
          _isLoading = false;
        });
      }
    } else if (skippedLogin || currentUser != null) {
      if (mounted) {
        setState(() {
          _shouldShowOnboarding = false;
          _shouldShowWelcome = false;
          _isLoading = false;
        });
      }

      if (skippedLogin && currentUser == null) {
        _showDataWarningSnackbar();
      }
    } else {
      if (mounted) {
        setState(() {
          _shouldShowOnboarding = false;
          _shouldShowWelcome = true;
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadGuestDataOnStartup() async {
    try {
      final authService = Get.find<AuthService>();

      // Ensure guest mode is enabled
      if (!authService.isGuestMode.value) {
        await authService.enableGuestMode();
      }
    } catch (e) {}
  }

  Future<void> _syncDataOnStartup() async {
    try {
      final fuelingService = Get.find<FuelingService>();
      await fuelingService.syncFromFirebaseToOffline();

      // Also sync service & trip records
      try {
        final serviceTripSync = Get.find<ServiceTripSyncService>();
        await serviceTripSync.syncFromFirebase();
      } catch (_) {}
    } catch (e) {
      // Don't show error to user on startup
    }
  }

  void _showDataWarningSnackbar() {
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.warning_amber_rounded, color: Colors.white),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Your data is stored locally only. Create an account to sync across devices.',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 4),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SplashScreen();
    }

    if (_shouldShowOnboarding) {
      return const OnboardingScreen();
    }

    return _shouldShowWelcome ? const LoginScreen() : const MainNavigation();
  }
}

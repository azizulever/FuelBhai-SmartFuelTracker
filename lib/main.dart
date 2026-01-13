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

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

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
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'FuelBhai',
      theme: appTheme,
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
    await Future.delayed(const Duration(seconds: 3)); // Splash screen duration

    final prefs = await SharedPreferences.getInstance();
    final onboardingCompleted = prefs.getBool('onboarding_completed') ?? false;
    final skippedLogin = prefs.getBool('skipped_login') ?? false;

    // Initialize auth service and get current Firebase user
    final authService = Get.find<AuthService>();
    final currentUser = FirebaseAuth.instance.currentUser;

    // Determine which screen to show
    if (!onboardingCompleted) {
      // First time user - show onboarding
      if (mounted) {
        setState(() {
          _shouldShowOnboarding = true;
          _shouldShowWelcome = false;
          _isLoading = false;
        });
      }
    } else if (skippedLogin || currentUser != null) {
      // User has completed onboarding and either skipped login or is logged in
      if (mounted) {
        setState(() {
          _shouldShowOnboarding = false;
          _shouldShowWelcome = false;
          _isLoading = false;
        });
      }

      if (skippedLogin && currentUser == null) {
        // Guest mode - load local data
        print('👤 Guest mode detected, loading local data...');
        await _loadGuestDataOnStartup();
        _showDataWarningSnackbar();
      } else if (currentUser != null) {
        // User is logged in, trigger data sync
        _syncDataOnStartup();
      }
    } else {
      // User has completed onboarding but not logged in or skipped
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
      print('📥 App startup: Loading guest data from local storage...');
      final authService = Get.find<AuthService>();

      // Ensure guest mode is enabled
      if (!authService.isGuestMode.value) {
        await authService.enableGuestMode();
      }

      // Add a small delay to ensure services are fully initialized
      await Future.delayed(const Duration(milliseconds: 300));

      print('✅ Guest mode initialized, services will load data automatically');
    } catch (e) {
      print('❌ Error during guest data load: $e');
    }
  }

  Future<void> _syncDataOnStartup() async {
    try {
      print('🔄 App startup: Syncing data for logged-in user...');
      final fuelingService = Get.find<FuelingService>();

      // Add a small delay to ensure services are fully initialized
      await Future.delayed(const Duration(milliseconds: 500));

      await fuelingService.syncFromFirebaseToOffline();
      print('✅ Startup data sync completed');
    } catch (e) {
      print('❌ Error during startup data sync: $e');
      // Don't show error to user on startup - just log it
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

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:mileage_calculator/controllers/mileage_controller.dart';
import 'package:mileage_calculator/services/fueling_service.dart';
import 'package:mileage_calculator/services/service_trip_sync.dart';
import 'package:mileage_calculator/services/local_storage_service.dart';
import 'package:mileage_calculator/utils/theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService extends GetxController {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final LocalStorageService _localStorageService = LocalStorageService();

  RxBool isLoading = false.obs;
  RxBool isLoggedIn = false.obs;
  RxBool isGuestMode = false.obs;
  RxString guestUserId = ''.obs;

  /// True while guest→Firebase migration is in progress.
  /// Services should wait before fetching from Firebase.
  bool isMigrating = false;

  Rx<User?> user = Rx<User?>(null);

  @override
  void onInit() {
    super.onInit();
    user.value = _auth.currentUser;
    isLoggedIn.value = user.value != null;

    checkGuestMode();

    _auth.authStateChanges().listen((User? firebaseUser) {
      user.value = firebaseUser;
      isLoggedIn.value = firebaseUser != null;

      if (firebaseUser != null) {
        isGuestMode.value = false;
      }
    });
  }

  /// Check if the user is in guest mode
  Future<void> checkGuestMode() async {
    final prefs = await SharedPreferences.getInstance();
    isGuestMode.value = prefs.getBool('skipped_login') ?? false;

    if (isGuestMode.value) {
      guestUserId.value = await _localStorageService.getGuestUserId();
    }
  }

  Future<String> signInWithGoogle() async {
    try {
      isLoading.value = true;

      // ── Capture guest state BEFORE sign-in ──
      // signInWithCredential triggers authStateChanges which sets
      // isGuestMode = false, so we must snapshot the flag now.
      final wasGuestMode = isGuestMode.value;

      // Sign out first to ensure clean state
      await GoogleSignIn().signOut();

      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();

      if (googleUser == null) {
        isLoading.value = false;
        return 'Sign-in aborted by user';
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Flag migration so services don't race with an early fetch
      if (wasGuestMode) isMigrating = true;

      await FirebaseAuth.instance.signInWithCredential(credential);

      // Save user data locally
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_email', googleUser.email);
      await prefs.setString('user_name', googleUser.displayName ?? 'User');

      // Migrate guest data using the captured flag (not the reactive one)
      if (wasGuestMode) {
        await _migrateGuestDataToFirebase();
        isMigrating = false;
      }

      // Trigger data sync after successful login
      await _syncDataAfterLogin();

      Get.snackbar(
        'Success',
        'Signed in with Google successfully',
        backgroundColor: primaryColor,
        colorText: Colors.white,
        borderRadius: 12,
        margin: const EdgeInsets.all(16),
        snackPosition: SnackPosition.TOP,
        icon: const Icon(Icons.check_circle, color: Colors.white),
        shouldIconPulse: false,
        duration: const Duration(seconds: 3),
      );

      isLoading.value = false;
      return 'Success';
    } on FirebaseAuthException catch (e) {
      isLoading.value = false;
      isMigrating = false;
      Get.snackbar(
        'Authentication Error',
        e.message ?? 'An unknown Firebase error occurred',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        borderRadius: 12,
        margin: const EdgeInsets.all(16),
        snackPosition: SnackPosition.TOP,
        icon: const Icon(Icons.error, color: Colors.white),
        shouldIconPulse: false,
        duration: const Duration(seconds: 3),
      );
      return 'FirebaseAuthException: ${e.message}';
    } on Exception catch (e) {
      isLoading.value = false;
      isMigrating = false;

      String errorMessage = 'An unexpected error occurred';
      if (e.toString().contains('sign_in_failed') ||
          e.toString().contains('ApiException: 10')) {
        errorMessage =
            'Google Sign-In is not properly configured.\n\n'
            'Please ensure:\n'
            '1. SHA-1 fingerprint is added to Firebase Console\n'
            '2. Google Sign-In is enabled in Firebase Authentication\n'
            '3. App is properly registered in Google Cloud Console';
      }

      Get.snackbar(
        'Error',
        errorMessage,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        borderRadius: 12,
        margin: const EdgeInsets.all(16),
        snackPosition: SnackPosition.TOP,
        icon: const Icon(Icons.error, color: Colors.white),
        shouldIconPulse: false,
        duration: const Duration(seconds: 5),
      );
      return 'Exception: $e';
    }
  }

  Future<void> signOut() async {
    try {
      final currentUserId = getCurrentUserId();

      // Clear fueling data
      try {
        final fuelingService = Get.find<FuelingService>();
        await fuelingService.clearAllLocalData();
      } catch (_) {}

      // Clear service and trip data
      try {
        final serviceTripSync = Get.find<ServiceTripSyncService>();
        await serviceTripSync.clearAllLocalData();
      } catch (_) {}

      // Clear user-specific local storage keys
      if (currentUserId.isNotEmpty) {
        final prefs = await SharedPreferences.getInstance();
        final keysToRemove = [
          'offline_fueling_records_$currentUserId',
          'pending_operations_$currentUserId',
          'service_records_$currentUserId',
          'trip_records_$currentUserId',
        ];
        for (var key in keysToRemove) {
          await prefs.remove(key);
        }
      }

      // Sign out from Firebase
      await _auth.signOut();

      // Sign out from Google if signed in with Google
      if (await _googleSignIn.isSignedIn()) {
        await _googleSignIn.signOut();
      }

      // Clear user data from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('user_name');
      await prefs.remove('user_email');

      // Clear guest mode if active
      if (isGuestMode.value) {
        await _localStorageService.clearAllGuestData();
        await disableGuestMode();
      }

      Get.snackbar(
        'Success',
        'Logged out successfully',
        backgroundColor: primaryColor,
        colorText: Colors.white,
        borderRadius: 12,
        margin: const EdgeInsets.all(16),
        snackPosition: SnackPosition.TOP,
        icon: const Icon(Icons.check_circle, color: Colors.white),
        shouldIconPulse: false,
        duration: const Duration(seconds: 3),
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'An error occurred during logout',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        borderRadius: 12,
        margin: const EdgeInsets.all(16),
        snackPosition: SnackPosition.TOP,
      );
    }
  }

  String getCurrentUserEmail() {
    return _auth.currentUser?.email ?? 'guest@fuelbhai.com';
  }

  String getCurrentUserName() {
    return _auth.currentUser?.displayName ?? 'Guest User';
  }

  /// Enable guest mode
  Future<void> enableGuestMode() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('skipped_login', true);
    isGuestMode.value = true;
    guestUserId.value = await _localStorageService.getGuestUserId();
  }

  /// Disable guest mode
  Future<void> disableGuestMode() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('skipped_login');
    isGuestMode.value = false;
    guestUserId.value = '';
  }

  /// Get current user ID (either Firebase user ID or guest ID)
  String getCurrentUserId() {
    if (isLoggedIn.value && user.value != null) {
      return user.value!.uid;
    } else if (isGuestMode.value) {
      return guestUserId.value;
    }
    return '';
  }

  /// Migrate guest data to Firebase when user logs in
  Future<void> _migrateGuestDataToFirebase() async {
    try {
      if (!isLoggedIn.value || user.value == null) return;

      final currentUserId = user.value!.uid;

      try {
        final fuelingService = Get.find<FuelingService>();
        await fuelingService.migrateGuestDataToFirebase(currentUserId);
      } catch (_) {}

      try {
        final serviceTripSync = Get.find<ServiceTripSyncService>();
        await serviceTripSync.migrateGuestDataToFirebase(currentUserId);
      } catch (_) {}

      await _localStorageService.clearAllGuestData();
      await disableGuestMode();
    } catch (_) {}
  }

  /// Sync data from Firebase to offline storage after successful login
  Future<void> _syncDataAfterLogin() async {
    try {
      await Future.delayed(const Duration(milliseconds: 200));

      final currentUserId = user.value?.uid ?? '';
      if (currentUserId.isEmpty) return;

      // Clear cached local data for fresh sync
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('service_records_$currentUserId');
      await prefs.remove('trip_records_$currentUserId');
      await prefs.remove('service_records');
      await prefs.remove('trip_records');

      // Sync fueling records
      final fuelingService = Get.find<FuelingService>();
      await fuelingService.syncFromFirebaseToOffline();

      if (fuelingService.hasPendingOperations) {
        await fuelingService.syncPendingData();
      }

      // Sync service and trip records
      try {
        final serviceTripSync = Get.find<ServiceTripSyncService>();
        await serviceTripSync.syncFromFirebase();
      } catch (_) {}

      // Refresh MileageController if it exists
      try {
        final mileageController = Get.find<MileageGetxController>();
        await Future.delayed(const Duration(milliseconds: 100));
        mileageController.update();
      } catch (_) {}

      // Validate user-specific data
      if (fuelingService.fuelingRecords.isNotEmpty) {
        fuelingService.fuelingRecords.removeWhere(
          (record) => record.userId != currentUserId,
        );
      }
    } catch (_) {
      // Login should still succeed even if sync fails
    }
  }
}

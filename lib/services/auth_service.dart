import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:mileage_calculator/controllers/mileage_controller.dart';
import 'package:mileage_calculator/services/fueling_service.dart';
import 'package:mileage_calculator/services/service_trip_sync.dart';
import 'package:mileage_calculator/utils/theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService extends GetxController {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  RxBool isLoading = false.obs;
  RxBool isLoggedIn = false.obs;

  Rx<User?> user = Rx<User?>(null);

  @override
  void onInit() {
    super.onInit();
    user.value = _auth.currentUser;
    isLoggedIn.value = user.value != null;

    // Listen for authentication state changes
    _auth.authStateChanges().listen((User? firebaseUser) {
      user.value = firebaseUser;
      isLoggedIn.value = firebaseUser != null;
    });
  }

  Future<bool> registerWithEmail(
    String email,
    String password, {
    String? name,
  }) async {
    try {
      isLoading.value = true;

      // Create user with email and password
      UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password);

      // Update display name
      if (name != null && name.isNotEmpty) {
        await userCredential.user?.updateDisplayName(name);
      }

      // Save user data locally
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_email', email);
      await prefs.setString('user_name', name ?? 'User');

      // Trigger data sync after successful registration
      await _syncDataAfterLogin();

      Get.snackbar(
        'Success',
        'Account created successfully',
        backgroundColor: primaryColor,
        colorText: Colors.white,
        borderRadius: 12,
        margin: const EdgeInsets.all(16),
        snackPosition: SnackPosition.TOP,
        icon: const Icon(Icons.check_circle, color: Colors.white),
        shouldIconPulse: false,
        duration: const Duration(seconds: 3),
      );

      return true;
    } on FirebaseAuthException catch (e) {
      String errorMessage;

      switch (e.code) {
        case 'email-already-in-use':
          errorMessage = 'This email is already registered.';
          break;
        case 'weak-password':
          errorMessage = 'The password is too weak.';
          break;
        case 'invalid-email':
          errorMessage = 'The email address is invalid.';
          break;
        default:
          errorMessage = 'An error occurred during registration.';
      }

      Get.snackbar(
        'Registration Error',
        errorMessage,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        borderRadius: 12,
        margin: const EdgeInsets.all(16),
        snackPosition: SnackPosition.TOP,
      );

      return false;
    } catch (e) {
      Get.snackbar(
        'Registration Error',
        'An unexpected error occurred during registration.',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        borderRadius: 12,
        margin: const EdgeInsets.all(16),
        snackPosition: SnackPosition.TOP,
      );

      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> signInWithEmail(String email, String password) async {
    try {
      isLoading.value = true;

      await _auth.signInWithEmailAndPassword(email: email, password: password);

      // Get current user's display name or use email as fallback
      String displayName =
          _auth.currentUser?.displayName ??
          _auth.currentUser?.email?.split('@')[0] ??
          'User';

      // Save user data locally
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_email', email);
      await prefs.setString('user_name', displayName);

      // Trigger data sync after successful login
      await _syncDataAfterLogin();

      Get.snackbar(
        'Success',
        'Logged in successfully',
        backgroundColor: primaryColor,
        colorText: Colors.white,
        borderRadius: 12,
        margin: const EdgeInsets.all(16),
        snackPosition: SnackPosition.TOP,
        icon: const Icon(Icons.check_circle, color: Colors.white),
        shouldIconPulse: false,
        duration: const Duration(seconds: 3),
      );

      return true;
    } on FirebaseAuthException catch (e) {
      String errorMessage;

      switch (e.code) {
        case 'user-not-found':
          errorMessage = 'No user found with this email.';
          break;
        case 'wrong-password':
          errorMessage = 'Incorrect password.';
          break;
        case 'invalid-credential':
          errorMessage = 'Invalid email or password.';
          break;
        case 'user-disabled':
          errorMessage = 'This account has been disabled.';
          break;
        default:
          errorMessage = 'An error occurred during login.';
      }

      Get.snackbar(
        'Login Error',
        errorMessage,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        borderRadius: 12,
        margin: const EdgeInsets.all(16),
        snackPosition: SnackPosition.TOP,
      );

      return false;
    } catch (e) {
      Get.snackbar(
        'Login Error',
        'An unexpected error occurred during login.',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        borderRadius: 12,
        margin: const EdgeInsets.all(16),
        snackPosition: SnackPosition.TOP,
      );

      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<String> signInWithGoogle() async {
    try {
      // Sign out first to ensure clean state
      await GoogleSignIn().signOut();

      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();

      if (googleUser == null) {
        return 'Sign-in aborted by user';
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // Create credential with proper tokens
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      await FirebaseAuth.instance.signInWithCredential(credential);

      // Save user data locally
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_email', googleUser.email);
      await prefs.setString('user_name', googleUser.displayName ?? 'User');

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

      print('Successfully logged in');
      return 'Success';
    } on FirebaseAuthException catch (e) {
      print('FirebaseAuthException: ${e.message}');
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
      print('Exception: $e');

      // Check for specific Google Sign-In errors
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

  //
  // Future<bool> signInWithGoogle() async {
  //   try {
  //     isLoading.value = true;
  //
  //     // Start the Google sign-in process
  //     final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
  //
  //     // If user canceled the sign-in
  //     if (googleUser == null) {
  //       isLoading.value = false;
  //       return false;
  //     }
  //
  //     // Obtain auth details from Google
  //     final GoogleSignInAuthentication googleAuth =
  //         await googleUser.authentication;
  //
  //     // Create Firebase credential with Google tokens
  //     final OAuthCredential credential = GoogleAuthProvider.credential(
  //       accessToken: googleAuth.accessToken,
  //       idToken: googleAuth.idToken,
  //     );
  //     print('Google Auth Credintials: $credential');
  //     // Sign in to Firebase with Google credential
  //     final UserCredential userCredential = await _auth.signInWithCredential(
  //       credential,
  //     );
  //
  //     // Save user data locally
  //     final prefs = await SharedPreferences.getInstance();
  //     await prefs.setString('user_email', googleUser.email);
  //     await prefs.setString(
  //       'user_name',
  //       googleUser.displayName ?? 'Google User',
  //     );
  //
  //     Get.snackbar(
  //       'Success',
  //       'Signed in with Google successfully',
  //       backgroundColor: primaryColor,
  //       colorText: Colors.white,
  //       borderRadius: 12,
  //       margin: const EdgeInsets.all(16),
  //       snackPosition: SnackPosition.TOP,
  //       icon: const Icon(Icons.check_circle, color: Colors.white),
  //       shouldIconPulse: false,
  //       duration: const Duration(seconds: 3),
  //     );
  //
  //     return true;
  //   } catch (e) {
  //     Get.snackbar(
  //       'Google Sign-In Error',
  //       'An error occurred during Google sign-in',
  //       backgroundColor: Colors.red,
  //       colorText: Colors.white,
  //       borderRadius: 12,
  //       margin: const EdgeInsets.all(16),
  //       snackPosition: SnackPosition.TOP,
  //     );
  //
  //     return false;
  //   } finally {
  //     isLoading.value = false;
  //   }
  // }

  Future<void> sendPasswordResetEmail(String email) async {
    try {
      isLoading.value = true;

      await _auth.sendPasswordResetEmail(email: email);

      Get.snackbar(
        'Success',
        'Password reset email sent to $email',
        backgroundColor: primaryColor,
        colorText: Colors.white,
        borderRadius: 12,
        margin: const EdgeInsets.all(16),
        snackPosition: SnackPosition.TOP,
        icon: const Icon(Icons.check_circle, color: Colors.white),
        shouldIconPulse: false,
        duration: const Duration(seconds: 3),
      );
    } on FirebaseAuthException catch (e) {
      String errorMessage;

      switch (e.code) {
        case 'user-not-found':
          errorMessage = 'No user found with this email address.';
          break;
        case 'invalid-email':
          errorMessage = 'The email address is invalid.';
          break;
        default:
          errorMessage = 'An error occurred while sending reset email.';
      }

      Get.snackbar(
        'Error',
        errorMessage,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        borderRadius: 12,
        margin: const EdgeInsets.all(16),
        snackPosition: SnackPosition.TOP,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> signOut() async {
    try {
      // Clear fueling data first
      try {
        final fuelingService = Get.find<FuelingService>();
        await fuelingService.clearAllLocalData();
        print('✅ Fueling data cleared');
      } catch (e) {
        print('⚠️ Could not clear fueling data: $e');
      }

      // Clear Service and Trip data
      try {
        final serviceTripSync = Get.find<ServiceTripSyncService>();
        await serviceTripSync.clearAllLocalData();
        print('✅ Service and Trip data cleared');
      } catch (e) {
        print('⚠️ Could not clear service/trip data: $e');
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

  // Helper method to get current user's data
  String getCurrentUserEmail() {
    return _auth.currentUser?.email ?? 'guest@tankibhai.com';
  }

  String getCurrentUserName() {
    return _auth.currentUser?.displayName ?? 'Guest User';
  }

  // Method to sync data from Firebase to offline storage after successful login
  Future<void> _syncDataAfterLogin() async {
    try {
      print('🔄 AuthService: Starting data sync after login...');

      // Wait a moment to ensure auth state is fully updated
      await Future.delayed(const Duration(milliseconds: 200));

      // Clear any cached local data to ensure fresh start - but preserve offline records temporarily
      final prefs = await SharedPreferences.getInstance();
      print('🗑️ Clearing cached Service and Trip records...');
      await prefs.remove('service_records');
      await prefs.remove('trip_records');
      // Don't clear fuel_entries or offline_fueling_records here - let FuelingService handle it

      // Get FuelingService and trigger immediate sync
      final fuelingService = Get.find<FuelingService>();

      print(
        '📥 Explicitly syncing fueling records from Firebase (bypassing delays)...',
      );
      await fuelingService.syncFromFirebaseToOffline();
      print(
        '📊 After sync: ${fuelingService.fuelingRecords.length} fueling records loaded',
      );

      // Process any pending operations
      if (fuelingService.hasPendingOperations) {
        print('📤 Processing pending fueling operations...');
        await fuelingService.syncPendingData();
      }

      // Sync Service and Trip records from Firebase
      try {
        final serviceTripSync = Get.find<ServiceTripSyncService>();
        print('📥 Syncing service and trip records from Firebase...');
        await serviceTripSync.syncFromFirebase();
        print('✅ Service and Trip records synced successfully');
      } catch (e) {
        print(
          '⚠️ ServiceTripSyncService not found, will be initialized when needed: $e',
        );
      }

      // Force refresh MileageController if it exists
      try {
        print('🔄 Refreshing MileageController...');
        final mileageController = Get.find<MileageGetxController>();
        await Future.delayed(const Duration(milliseconds: 100));
        mileageController.update();
        print('✅ MileageController refreshed');
      } catch (e) {
        print(
          '⚠️ MileageController not found, will be initialized when needed: $e',
        );
      }

      // Validate user-specific data after sync
      print('🔍 Validating user-specific data...');
      if (fuelingService.fuelingRecords.isNotEmpty) {
        final currentUserId = user.value?.uid ?? '';
        final userRecords =
            fuelingService.fuelingRecords
                .where((record) => record.userId == currentUserId)
                .length;
        final totalRecords = fuelingService.fuelingRecords.length;

        if (userRecords == totalRecords) {
          print(
            '✅ Data validation passed: All $totalRecords fueling records belong to current user',
          );
        } else {
          print(
            '⚠️ Data validation warning: $userRecords/$totalRecords fueling records belong to current user',
          );
          // Clear mismatched data
          fuelingService.fuelingRecords.removeWhere(
            (record) => record.userId != currentUserId,
          );
          print(
            '🧹 Removed ${totalRecords - userRecords} records from other users',
          );
        }
      }

      print('✅ Data sync completed successfully');
      print('ℹ️ All user data synced from Firebase');
    } catch (e) {
      print('❌ Error during data sync after login: $e');
      // Don't rethrow - login should still succeed even if sync fails
    }
  }
}

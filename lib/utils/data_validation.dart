import 'package:get/get.dart';
import 'package:mileage_calculator/services/auth_service.dart';
import 'package:mileage_calculator/services/fueling_service.dart';

class DataValidation {
  static Future<bool> validateUserSpecificData() async {
    try {
      print('🔍 DataValidation: Starting user-specific data validation...');

      // Get services
      final authService = Get.find<AuthService>();
      final fuelingService = Get.find<FuelingService>();

      if (!authService.isLoggedIn.value || authService.user.value == null) {
        print('❌ User not logged in - validation skipped');
        return false;
      }

      final currentUserId = authService.user.value!.uid;
      print('👤 Current user ID: $currentUserId');

      // Check if all fueling records belong to current user
      final records = fuelingService.fuelingRecords;
      print('📊 Total records in memory: ${records.length}');

      for (var record in records) {
        if (record.userId != currentUserId) {
          print('❌ SECURITY ISSUE: Found record belonging to different user!');
          print('📋 Record ID: ${record.id}');
          print('📋 Record User ID: ${record.userId}');
          print('📋 Current User ID: $currentUserId');
          return false;
        }
      }

      print('✅ All records belong to current user - data validation passed');
      return true;
    } catch (e) {
      print('❌ Data validation failed: $e');
      return false;
    }
  }

  static Future<void> logUserDataSummary() async {
    try {
      final authService = Get.find<AuthService>();
      final fuelingService = Get.find<FuelingService>();

      print('📋 === USER DATA SUMMARY ===');
      print('👤 User logged in: ${authService.isLoggedIn.value}');

      if (authService.isLoggedIn.value && authService.user.value != null) {
        print('👤 User ID: ${authService.user.value!.uid}');
        print('📧 User email: ${authService.user.value!.email}');
        print('👤 User name: ${authService.user.value!.displayName}');
      }

      print(
        '📊 Total fueling records: ${fuelingService.fuelingRecords.length}',
      );
      print(
        '📤 Pending operations: ${fuelingService.pendingOperations.length}',
      );
      print('🌐 Online status: ${fuelingService.isOnline.value}');
      print('⏳ Loading status: ${fuelingService.isLoading.value}');
      print('📋 === END SUMMARY ===');
    } catch (e) {
      print('❌ Failed to generate user data summary: $e');
    }
  }
}

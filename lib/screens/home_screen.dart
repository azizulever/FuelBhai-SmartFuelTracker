import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mileage_calculator/controllers/mileage_controller.dart';
import 'package:mileage_calculator/screens/notification_screen.dart';
import 'package:mileage_calculator/utils/theme.dart';
import 'package:mileage_calculator/widgets/empty_history_placeholder.dart';
import 'package:mileage_calculator/widgets/fuel_entry_list.dart';
import 'package:mileage_calculator/widgets/main_navigation.dart';
import 'package:mileage_calculator/widgets/vehicle_type_selector.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomePage extends StatelessWidget {
  final bool showBottomNav;

  const HomePage({super.key, this.showBottomNav = true});

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Good Morning!';
    } else if (hour < 17) {
      return 'Good Afternoon!';
    } else {
      return 'Good Evening!';
    }
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<MileageGetxController>(
      init: MileageGetxController(),
      builder: (controller) {
        return Scaffold(
          backgroundColor: Colors.white,
          body: SafeArea(
            child: Column(
              children: [
                // Custom Top Bar
                _buildTopBar(context),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Divider(color: Colors.grey[300], thickness: 1),
                ),
                VehicleTypeSelector(
                  selectedVehicleType: controller.selectedVehicleType,
                  onVehicleTypeChanged: controller.updateSelectedVehicleType,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Row(
                        children: [
                          // Left Card: Latest Mileage
                          Expanded(
                            child: _buildEnhancedStatCard(
                              context: context,
                              title: 'Latest Mileage',
                              mainValue:
                                  controller.filteredEntries.isEmpty
                                      ? '0.0'
                                      : controller.lastMileage.toStringAsFixed(
                                        1,
                                      ),
                              unit: 'km/l',
                              averageLabel: 'Average',
                              averageValue:
                                  controller.filteredEntries.isEmpty
                                      ? '0.0'
                                      : controller.averageMileage
                                          .toStringAsFixed(1),
                              averageUnit: 'km/l',
                              icon: Icons.speed_rounded,
                              isBlue: true,
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Right Card: Latest Fuel Cost
                          Expanded(
                            child: _buildEnhancedStatCard(
                              context: context,
                              title: 'Latest Fuel Cost',
                              mainValue:
                                  controller.filteredEntries.isEmpty
                                      ? '0.0'
                                      : controller.lastFuelPrice
                                          .toStringAsFixed(1),
                              unit: 'tk/l',
                              averageLabel: 'Average',
                              averageValue:
                                  controller.filteredEntries.isEmpty
                                      ? '0.0'
                                      : controller.averageFuelPrice
                                          .toStringAsFixed(1),
                              averageUnit: 'tk/l',
                              icon: Icons.local_gas_station_rounded,
                              isBlue: false,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // Nearby Fuel Station Card
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _buildNearbyFuelStationCard(context),
                ),

                const SizedBox(height: 12),
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child:
                        controller.filteredEntries.isEmpty
                            ? EmptyHistoryPlaceholder(
                              vehicleType: controller.selectedVehicleType,
                            )
                            : FuelEntryList(
                              entries: controller.filteredEntries,
                              controller: controller,
                            ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return FutureBuilder<Map<String, String>>(
      future: _getUserInfo(),
      builder: (context, snapshot) {
        final userInfo =
            snapshot.data ?? {'name': 'Guest User', 'initial': 'G'};
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Left side: Profile avatar with greeting and name
              Expanded(
                child: GestureDetector(
                  onTap:
                      () => Get.offAll(
                        () => const MainNavigation(initialIndex: 4),
                      ),
                  child: Row(
                    children: [
                      // Profile Avatar
                      Container(
                        width: MediaQuery.of(context).size.width * 0.12,
                        height: MediaQuery.of(context).size.width * 0.12,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: primaryColor, width: 2),
                        ),
                        child: Center(
                          child: Text(
                            userInfo['initial']!.toUpperCase(),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: primaryColor,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Greeting and Name
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _getGreeting(),
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              userInfo['name']!,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Right side: Notification icon
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.grey[300]!, width: 1),
                ),
                child: IconButton(
                  onPressed: () {
                    Get.to(() => const NotificationScreen());
                  },
                  icon: Stack(
                    children: [
                      const Icon(
                        Icons.notifications_outlined,
                        color: Colors.black87,
                        size: 26,
                      ),
                      // Red dot indicator (optional, can be conditional based on unread notifications)
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          width: 10,
                          height: 10,
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<Map<String, String>> _getUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    final fullName = prefs.getString('user_name') ?? 'Guest User';
    final firstName = fullName.split(' ').first;
    final initial = firstName.isNotEmpty ? firstName.substring(0, 1) : 'G';
    return {'name': fullName, 'initial': initial};
  }

  Widget _buildEnhancedStatCard({
    required BuildContext context,
    required String title,
    required String mainValue,
    required String unit,
    required String averageLabel,
    required String averageValue,
    required String averageUnit,
    required IconData icon,
    required bool isBlue,
  }) {
    // Split value into integer and decimal parts
    final parts = mainValue.split('.');
    final integerPart = parts[0];
    final decimalPart = parts.length > 1 ? '.${parts[1]}' : '';

    final avgParts = averageValue.split('.');
    final avgIntegerPart = avgParts[0];
    final avgDecimalPart = avgParts.length > 1 ? '.${avgParts[1]}' : '';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isBlue ? primaryColor : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color:
                isBlue
                    ? primaryColor.withOpacity(0.3)
                    : Colors.grey.withOpacity(0.15),
            spreadRadius: 0,
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Icon and Title Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isBlue ? Colors.white : Colors.black87,
                    letterSpacing: 0.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color:
                      isBlue
                          ? Colors.white.withOpacity(0.2)
                          : primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color:
                        isBlue
                            ? Colors.white.withOpacity(0.3)
                            : primaryColor.withOpacity(0.3),
                    width: 1.5,
                  ),
                ),
                child: Icon(
                  icon,
                  color: isBlue ? Colors.white : primaryColor,
                  size: 18,
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Main Value Display with grayed decimal
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  integerPart,
                  style: TextStyle(
                    fontSize: 44,
                    fontWeight: FontWeight.bold,
                    color: isBlue ? Colors.white : Colors.black,
                    height: 1,
                    letterSpacing: -1.5,
                  ),
                ),
                if (decimalPart.isNotEmpty)
                  Text(
                    decimalPart,
                    style: TextStyle(
                      fontSize: 44,
                      fontWeight: FontWeight.bold,
                      color:
                          isBlue
                              ? Colors.white.withOpacity(0.5)
                              : Colors.black.withOpacity(0.3),
                      height: 1,
                      letterSpacing: -1.5,
                    ),
                  ),
                const SizedBox(width: 4),
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    unit,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color:
                          isBlue
                              ? Colors.white.withOpacity(0.9)
                              : Colors.black.withOpacity(0.7),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Average Section
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Row(
              children: [
                Text(
                  '$averageLabel: ',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color:
                        isBlue
                            ? Colors.white.withOpacity(0.9)
                            : Colors.black.withOpacity(0.7),
                  ),
                ),
                Text(
                  avgIntegerPart,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: isBlue ? Colors.white : Colors.black,
                    letterSpacing: -0.5,
                  ),
                ),
                if (avgDecimalPart.isNotEmpty)
                  Text(
                    avgDecimalPart,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color:
                          isBlue
                              ? Colors.white.withOpacity(0.5)
                              : Colors.black.withOpacity(0.3),
                      letterSpacing: -0.5,
                    ),
                  ),
                const SizedBox(width: 3),
                Text(
                  averageUnit,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color:
                        isBlue
                            ? Colors.white.withOpacity(0.8)
                            : Colors.black.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNearbyFuelStationCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 0,
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Red location pin icon
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: const Color(0xFFFFEBEE),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.location_on,
              color: Color(0xFFE53935),
              size: 28,
            ),
          ),
          const SizedBox(width: 8),
          // Text content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Find nearby fuel station',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'View all stations within 20 km',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Blue arrow button
          GestureDetector(
            onTap: () {
              // TODO: Navigate to Nearby Fuel Stations page with Google Maps
              Get.snackbar(
                'Coming Soon',
                'Nearby fuel stations feature will be available soon!',
                snackPosition: SnackPosition.BOTTOM,
                backgroundColor: primaryColor,
                colorText: Colors.white,
                margin: const EdgeInsets.all(16),
                borderRadius: 8,
                duration: const Duration(seconds: 2),
              );
            },
            child: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: const Color(0xFFF0F4FF),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: primaryColor, width: 1.5),
              ),
              child: const Icon(
                Icons.arrow_forward_ios_rounded,
                color: primaryColor,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mileage_calculator/controllers/mileage_controller.dart';
import 'package:mileage_calculator/screens/nearby_stations_screen.dart';
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

  // Responsive helpers
  double _getResponsivePadding(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < 360) return 12.0; // Small phones
    if (width < 400) return 14.0; // Medium phones
    return 16.0; // Large phones and tablets
  }

  double _getResponsiveFontSize(BuildContext context, double baseSize) {
    final width = MediaQuery.of(context).size.width;
    if (width < 360) return baseSize * 0.85; // Small phones
    if (width < 400) return baseSize * 0.9; // Medium phones
    return baseSize; // Large phones
  }

  bool _isSmallScreen(BuildContext context) {
    return MediaQuery.of(context).size.width < 360;
  }

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
    final horizontalPadding = _getResponsivePadding(context);
    final isSmall = _isSmallScreen(context);
    final cardSpacing = isSmall ? 8.0 : 12.0;

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
                  padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                  child: Divider(color: Colors.grey[300], thickness: 1),
                ),
                VehicleTypeSelector(
                  selectedVehicleType: controller.selectedVehicleType,
                  onVehicleTypeChanged: controller.updateSelectedVehicleType,
                ),
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: horizontalPadding,
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
                          SizedBox(width: cardSpacing),
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

                SizedBox(height: cardSpacing),

                // Nearby Fuel Station Card
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                  child: _buildNearbyFuelStationCard(context),
                ),

                SizedBox(height: cardSpacing),
                Expanded(
                  child: Container(
                    margin: EdgeInsets.fromLTRB(
                      horizontalPadding,
                      0,
                      horizontalPadding,
                      horizontalPadding,
                    ),
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
    final isSmall = _isSmallScreen(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final horizontalPadding = _getResponsivePadding(context);

    // Responsive avatar size
    final avatarSize =
        screenWidth < 360 ? 40.0 : (screenWidth < 400 ? 44.0 : 48.0);

    return FutureBuilder<Map<String, String>>(
      future: _getUserInfo(),
      builder: (context, snapshot) {
        final userInfo =
            snapshot.data ?? {'name': 'Guest User', 'initial': 'G'};
        return Container(
          padding: EdgeInsets.symmetric(
            horizontal: horizontalPadding,
            vertical: isSmall ? 10 : 12,
          ),
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
                        width: avatarSize,
                        height: avatarSize,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: primaryColor,
                            width: isSmall ? 1.5 : 2,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            userInfo['initial']!.toUpperCase(),
                            style: TextStyle(
                              fontSize: _getResponsiveFontSize(context, 18),
                              fontWeight: FontWeight.bold,
                              color: primaryColor,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: isSmall ? 8 : 12),
                      // Greeting and Name
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _getGreeting(),
                              style: TextStyle(
                                fontSize: _getResponsiveFontSize(context, 14),
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              userInfo['name']!,
                              style: TextStyle(
                                fontSize: _getResponsiveFontSize(context, 16),
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
                  padding: EdgeInsets.all(isSmall ? 8 : 10),
                  constraints: const BoxConstraints(),
                  onPressed: () {
                    Get.to(() => const NotificationScreen());
                  },
                  icon: Stack(
                    children: [
                      Icon(
                        Icons.notifications_outlined,
                        color: Colors.black87,
                        size: isSmall ? 22 : 24,
                      ),
                      // Red dot indicator
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          width: isSmall ? 8 : 10,
                          height: isSmall ? 8 : 10,
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
    final isSmall = _isSmallScreen(context);
    final screenWidth = MediaQuery.of(context).size.width;

    // Responsive sizing
    final cardPadding =
        screenWidth < 360 ? 10.0 : (screenWidth < 400 ? 12.0 : 14.0);
    final borderRadius =
        screenWidth < 360 ? 16.0 : (screenWidth < 400 ? 20.0 : 24.0);
    final titleFontSize = _getResponsiveFontSize(context, 13);
    final iconSize = screenWidth < 360 ? 16.0 : 18.0;
    final iconPadding = screenWidth < 360 ? 6.0 : 8.0;
    final mainValueSize =
        screenWidth < 360 ? 32.0 : (screenWidth < 400 ? 36.0 : 40.0);
    final unitFontSize = _getResponsiveFontSize(context, 13);
    final avgLabelSize = _getResponsiveFontSize(context, 12);
    final avgValueSize = screenWidth < 360 ? 15.0 : 16.0;

    // Split value into integer and decimal parts
    final parts = mainValue.split('.');
    final integerPart = parts[0];
    final decimalPart = parts.length > 1 ? '.${parts[1]}' : '';

    final avgParts = averageValue.split('.');
    final avgIntegerPart = avgParts[0];
    final avgDecimalPart = avgParts.length > 1 ? '.${avgParts[1]}' : '';

    return Container(
      padding: EdgeInsets.all(cardPadding),
      decoration: BoxDecoration(
        color: isBlue ? primaryColor : Colors.white,
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [
          BoxShadow(
            color:
                isBlue
                    ? primaryColor.withOpacity(0.3)
                    : Colors.grey.withOpacity(0.15),
            spreadRadius: 0,
            blurRadius: isSmall ? 8 : 12,
            offset: Offset(0, isSmall ? 2 : 4),
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
                    fontSize: titleFontSize,
                    fontWeight: FontWeight.w600,
                    color: isBlue ? Colors.white : Colors.black87,
                    letterSpacing: 0.2,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              SizedBox(width: isSmall ? 4 : 8),
              Container(
                padding: EdgeInsets.all(iconPadding),
                decoration: BoxDecoration(
                  color:
                      isBlue
                          ? Colors.white.withOpacity(0.2)
                          : primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(isSmall ? 8 : 10),
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
                  size: iconSize,
                ),
              ),
            ],
          ),

          SizedBox(height: isSmall ? 10 : 12),

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
                    fontSize: mainValueSize,
                    fontWeight: FontWeight.bold,
                    color: isBlue ? Colors.white : Colors.black,
                    height: 1,
                    letterSpacing: -1.2,
                  ),
                ),
                if (decimalPart.isNotEmpty)
                  Text(
                    decimalPart,
                    style: TextStyle(
                      fontSize: mainValueSize,
                      fontWeight: FontWeight.bold,
                      color:
                          isBlue
                              ? Colors.white.withOpacity(0.5)
                              : Colors.black.withOpacity(0.3),
                      height: 1,
                      letterSpacing: -1.2,
                    ),
                  ),
                SizedBox(width: isSmall ? 2 : 4),
                Padding(
                  padding: EdgeInsets.only(top: isSmall ? 4 : 5),
                  child: Text(
                    unit,
                    style: TextStyle(
                      fontSize: unitFontSize,
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

          SizedBox(height: isSmall ? 8 : 10),

          // Average Section
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Row(
              children: [
                Text(
                  '$averageLabel: ',
                  style: TextStyle(
                    fontSize: avgLabelSize,
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
                    fontSize: avgValueSize,
                    fontWeight: FontWeight.bold,
                    color: isBlue ? Colors.white : Colors.black,
                    letterSpacing: -0.5,
                  ),
                ),
                if (avgDecimalPart.isNotEmpty)
                  Text(
                    avgDecimalPart,
                    style: TextStyle(
                      fontSize: avgValueSize,
                      fontWeight: FontWeight.bold,
                      color:
                          isBlue
                              ? Colors.white.withOpacity(0.5)
                              : Colors.black.withOpacity(0.3),
                      letterSpacing: -0.5,
                    ),
                  ),
                SizedBox(width: isSmall ? 2 : 3),
                Text(
                  averageUnit,
                  style: TextStyle(
                    fontSize: avgLabelSize,
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
    final isSmall = _isSmallScreen(context);
    final screenWidth = MediaQuery.of(context).size.width;

    // Responsive sizing
    final cardPadding =
        screenWidth < 360 ? 12.0 : (screenWidth < 400 ? 16.0 : 18.0);
    final borderRadius =
        screenWidth < 360 ? 10.0 : (screenWidth < 400 ? 12.0 : 14.0);
    final iconBoxSize =
        screenWidth < 360 ? 42.0 : (screenWidth < 400 ? 46.0 : 50.0);
    final iconSize =
        screenWidth < 360 ? 24.0 : (screenWidth < 400 ? 26.0 : 28.0);
    final titleFontSize = _getResponsiveFontSize(context, 16);
    final subtitleFontSize = _getResponsiveFontSize(context, 13);
    final arrowSize = screenWidth < 360 ? 16.0 : 18.0;
    final spacing = screenWidth < 360 ? 8.0 : 12.0;

    return Container(
      padding: EdgeInsets.all(cardPadding),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 0,
            blurRadius: isSmall ? 8 : 12,
            offset: Offset(0, isSmall ? 2 : 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Red location pin icon
          Container(
            width: iconBoxSize,
            height: iconBoxSize,
            decoration: BoxDecoration(
              color: const Color(0xFFFFEBEE),
              borderRadius: BorderRadius.circular(isSmall ? 10 : 12),
            ),
            child: Icon(
              Icons.location_on,
              color: const Color(0xFFE53935),
              size: iconSize,
            ),
          ),
          SizedBox(width: spacing),
          // Text content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Find nearby fuel station',
                  style: TextStyle(
                    fontSize: titleFontSize,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: isSmall ? 2 : 4),
                Text(
                  'View all stations within 20 km',
                  style: TextStyle(
                    fontSize: subtitleFontSize,
                    fontWeight: FontWeight.w400,
                    color: Colors.grey[600],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          SizedBox(width: spacing),
          // Blue arrow button
          GestureDetector(
            onTap: () {
              // Navigate to Nearby Fuel Stations screen
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const NearbyStationsScreen(),
                ),
              );
            },
            child: Container(
              width: iconBoxSize,
              height: iconBoxSize,
              decoration: BoxDecoration(
                color: const Color(0xFFF0F4FF),
                borderRadius: BorderRadius.circular(isSmall ? 10 : 12),
                border: Border.all(
                  color: primaryColor,
                  width: isSmall ? 1.2 : 1.5,
                ),
              ),
              child: Icon(
                Icons.arrow_forward_ios_rounded,
                color: primaryColor,
                size: arrowSize,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

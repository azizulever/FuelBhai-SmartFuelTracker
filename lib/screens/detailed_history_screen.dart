import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:mileage_calculator/controllers/mileage_controller.dart';
import 'package:mileage_calculator/utils/theme.dart';
import 'package:mileage_calculator/widgets/custom_tab_bar.dart';
import 'package:mileage_calculator/widgets/empty_history_placeholder.dart';
import 'package:mileage_calculator/widgets/fuel_entry_list.dart';
import 'package:mileage_calculator/widgets/add_entry_dialog.dart';
import 'package:mileage_calculator/widgets/main_navigation.dart';
import 'package:mileage_calculator/services/analytics_service.dart';

class DetailedHistoryScreen extends StatefulWidget {
  final bool showBottomNav;
  final VoidCallback? onBack;

  const DetailedHistoryScreen({
    Key? key,
    this.showBottomNav = true,
    this.onBack,
  }) : super(key: key);

  @override
  State<DetailedHistoryScreen> createState() => _DetailedHistoryScreenState();
}

class _DetailedHistoryScreenState extends State<DetailedHistoryScreen> {
  int _selectedTabIndex = 0;

  @override
  void initState() {
    super.initState();
    AnalyticsService.to.logScreenView('DetailedHistoryScreen');
  }

  // Responsive helpers
  double _getResponsivePadding(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < 360) return 12.0;
    if (width < 400) return 14.0;
    return 16.0;
  }

  double _getResponsiveFontSize(BuildContext context, double baseSize) {
    final width = MediaQuery.of(context).size.width;
    if (width < 360) return baseSize * 0.85;
    if (width < 400) return baseSize * 0.9;
    return baseSize;
  }

  bool _isSmallScreen(BuildContext context) {
    return MediaQuery.of(context).size.width < 360;
  }

  @override
  Widget build(BuildContext context) {
    final horizontalPadding = _getResponsivePadding(context);
    final isSmall = _isSmallScreen(context);

    return GetBuilder<MileageGetxController>(
      init: MileageGetxController(),
      builder: (controller) {
        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: const SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.light,
          ),
          child: Scaffold(
            backgroundColor: const Color(0xFFF5F5F5),
            body: SafeArea(
              top: false,
              child: Column(
                children: [
                  // Unified Header Section
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: primaryColor,
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(30),
                        bottomRight: Radius.circular(30),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: primaryColor.withOpacity(0.3),
                          spreadRadius: 1,
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Back button and title
                        Padding(
                          padding: EdgeInsets.fromLTRB(
                            horizontalPadding,
                            MediaQuery.of(context).padding.top +
                                (isSmall ? 10 : 12),
                            horizontalPadding,
                            isSmall ? 16 : 20,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              GestureDetector(
                                onTap:
                                    () =>
                                        widget.onBack != null
                                            ? widget.onBack!()
                                            : Get.back(),
                                child: Container(
                                  padding: EdgeInsets.all(isSmall ? 6 : 8),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    Icons.arrow_back_ios_new_rounded,
                                    color: Colors.white,
                                    size: isSmall ? 18 : 20,
                                  ),
                                ),
                              ),
                              Text(
                                '${controller.selectedVehicleType} Fueling',
                                style: TextStyle(
                                  fontSize: _getResponsiveFontSize(context, 20),
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              SizedBox(width: isSmall ? 34 : 38),
                            ],
                          ),
                        ),

                        // Fuel Icon
                        Container(
                          padding: EdgeInsets.all(isSmall ? 16 : 20),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.local_gas_station_rounded,
                            color: Colors.white,
                            size: isSmall ? 40 : 48,
                          ),
                        ),

                        SizedBox(height: isSmall ? 20 : 24),

                        // Horizontal divider lines
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Container(
                                    height: 2,
                                    margin: EdgeInsets.only(
                                      left: isSmall ? 30 : 40,
                                    ),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          Colors.white.withOpacity(0),
                                          Colors.white.withOpacity(0.5),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Container(
                                    height: 2,
                                    margin: EdgeInsets.only(
                                      right: isSmall ? 30 : 40,
                                    ),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          Colors.white.withOpacity(0.5),
                                          Colors.white.withOpacity(0),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),

                        SizedBox(height: isSmall ? 20 : 24),

                        // Statistics section
                        Padding(
                          padding: EdgeInsets.fromLTRB(
                            horizontalPadding,
                            0,
                            horizontalPadding,
                            isSmall ? 20 : 24,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              Expanded(
                                child: _buildStatItem(
                                  context: context,
                                  title: 'Total\nFuel',
                                  value:
                                      '${controller.getTotalFuel().toStringAsFixed(2)}L',
                                ),
                              ),
                              Container(
                                width: 1,
                                height: isSmall ? 30 : 35,
                                color: Colors.white30,
                              ),
                              Expanded(
                                child: _buildStatItem(
                                  context: context,
                                  title: 'Total\nCost',
                                  value:
                                      '${controller.getTotalCost().toStringAsFixed(0)}৳',
                                ),
                              ),
                              Container(
                                width: 1,
                                height: isSmall ? 30 : 35,
                                color: Colors.white30,
                              ),
                              Expanded(
                                child: _buildStatItem(
                                  context: context,
                                  title: 'Total\nDistance',
                                  value:
                                      '${controller.getTotalDistance().toStringAsFixed(0)}KM',
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: isSmall ? 8 : 10),
                  CustomTabBar(
                    tabs: const ['All History', 'Best Cost', 'Best Mileage'],
                    onTabChanged: (index) {
                      setState(() {
                        _selectedTabIndex = index;
                      });
                    },
                    initialIndex: _selectedTabIndex,
                  ),
                  SizedBox(height: isSmall ? 4 : 6),
                  // Tab content
                  Expanded(
                    child:
                        controller.filteredEntries.isEmpty
                            ? EmptyHistoryPlaceholder(
                              vehicleType: controller.selectedVehicleType,
                            )
                            : Container(
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
                              child: _buildTabContent(controller),
                            ),
                  ),
                ],
              ),
            ),
            bottomNavigationBar:
                widget.showBottomNav
                    ? _buildBottomNavigation(context, controller)
                    : null,
          ),
        );
      },
    );
  }

  Widget _buildStatItem({
    required BuildContext context,
    required String title,
    required String value,
  }) {
    final isSmall = _isSmallScreen(context);
    final labelFontSize = _getResponsiveFontSize(context, 11);
    final valueFontSize = isSmall ? 16.0 : 18.0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            title,
            textAlign: TextAlign.center,
            maxLines: 2,
            style: TextStyle(
              fontSize: labelFontSize,
              color: Colors.white70,
              fontWeight: FontWeight.w500,
              height: 1.2,
            ),
          ),
        ),
        SizedBox(height: isSmall ? 4 : 6),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            value,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: valueFontSize,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: -0.5,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTabContent(MileageGetxController controller) {
    switch (_selectedTabIndex) {
      case 0: // All History
        return FuelEntryList(
          entries: controller.filteredEntries,
          controller: controller,
          listType: "all",
          showServiceRecords: false, // Only show fuel entries
          showTripRecords: false, // Only show fuel entries
        );
      case 1: // Best Cost
        return FuelEntryList(
          entries: controller.filteredEntries,
          controller: controller,
          listType: "best_cost",
          showServiceRecords: false, // Only show fuel entries
          showTripRecords: false, // Only show fuel entries
        );
      case 2: // Best Mileage
        return FuelEntryList(
          entries: controller.filteredEntries,
          controller: controller,
          listType: "best_mileage",
          showServiceRecords: false, // Only show fuel entries
          showTripRecords: false, // Only show fuel entries
        );
      default:
        return FuelEntryList(
          entries: controller.filteredEntries,
          controller: controller,
          listType: "all",
          showServiceRecords: false, // Only show fuel entries
          showTripRecords: false, // Only show fuel entries
        );
    }
  }

  Widget _buildBottomNavigation(
    BuildContext context,
    MileageGetxController controller,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: primaryColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Container(
          height: 70,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildBottomNavItem(
                icon: Icons.home_outlined,
                label: 'Home',
                isActive: false,
                onTap:
                    () => Get.off(() => const MainNavigation(initialIndex: 0)),
              ),
              _buildBottomNavItem(
                icon: Icons.list_alt_rounded,
                label: 'Detailed Log',
                isActive: true,
                onTap: () {
                  // Already on detailed log
                },
              ),
              _buildBottomNavItem(
                icon: Icons.person_outline_rounded,
                label: 'Profile',
                isActive: false,
                onTap:
                    () => Get.off(() => const MainNavigation(initialIndex: 2)),
              ),
              _buildCenterAddButton(context, controller),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNavItem({
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isActive ? Colors.white : Colors.white.withOpacity(0.6),
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                color: isActive ? Colors.white : Colors.white.withOpacity(0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCenterAddButton(
    BuildContext context,
    MileageGetxController controller,
  ) {
    return GestureDetector(
      onTap:
          () => showDialog(
            context: context,
            builder: (context) => AddEntryDialog(controller: controller),
          ),
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Icon(Icons.add, color: primaryColor, size: 28),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mileage_calculator/controllers/mileage_controller.dart';
import 'package:mileage_calculator/screens/auth/user_profile_screen.dart';
import 'package:mileage_calculator/screens/detailed_history_screen.dart';
import 'package:mileage_calculator/screens/home_screen.dart';
import 'package:mileage_calculator/screens/notification_screen.dart';
import 'package:mileage_calculator/screens/service_screen.dart';
import 'package:mileage_calculator/screens/trip_screen.dart';
import 'package:mileage_calculator/services/analytics_service.dart';
import 'package:mileage_calculator/utils/theme.dart';
import 'package:mileage_calculator/widgets/entry_type_selection_dialog.dart';

class MainNavigation extends StatefulWidget {
  final int initialIndex;

  const MainNavigation({Key? key, this.initialIndex = 0}) : super(key: key);

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  late int _currentIndex;
  late MileageGetxController _mileageController;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;

    // Try to find existing controller first, create if not found
    try {
      _mileageController = Get.find<MileageGetxController>();
      print("MainNavigation found existing MileageController");
    } catch (e) {
      _mileageController = Get.put(MileageGetxController());
      print("MainNavigation created new MileageController");
    }
    print("MainNavigation initialized with index: $_currentIndex");
    // Log initial screen view
    _logCurrentTab();
  }

  static const _tabNames = ['Home', 'Fueling', 'Service', 'Trip', 'Profile'];

  void _logCurrentTab() {
    AnalyticsService.to.logTabChange(_tabNames[_currentIndex]);
  }

  void _onNavItemTapped(int index) {
    if (_currentIndex == index) return;
    setState(() {
      _currentIndex = index;
    });
    _logCurrentTab();
  }

  // Responsive helpers
  double _getNavBarHeight(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth < 360) return 62.0; // Small phones
    if (screenWidth < 400) return 65.0; // Medium phones
    return 70.0; // Large phones
  }

  double _getIconSize(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth < 360) return 20.0; // Small phones
    if (screenWidth < 400) return 22.0; // Medium phones
    return 24.0; // Large phones
  }

  double _getLabelFontSize(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth < 360) return 10.0; // Small phones
    if (screenWidth < 400) return 10.5; // Medium phones
    return 11.5; // Large phones
  }

  double _getButtonSize(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth < 360) return 54.0; // Small phones
    if (screenWidth < 400) return 56.0; // Medium phones
    return 60.0; // Large phones
  }

  @override
  Widget build(BuildContext context) {
    print("Building MainNavigation with currentIndex: $_currentIndex");
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          HomePage(showBottomNav: false), // 0 - Home
          DetailedHistoryScreen(
            showBottomNav: false,
            onBack: () => _onNavItemTapped(0),
          ), // 1 - Fueling
          ServiceScreen(
            showBottomNav: false,
            onBack: () => _onNavItemTapped(0),
          ), // 2 - Service
          TripScreen(
            showBottomNav: false,
            onBack: () => _onNavItemTapped(0),
          ), // 3 - Trip
          UserProfileScreen(showBottomNav: false), // 4 - Profile (from top bar)
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: primaryColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 16,
              offset: const Offset(0, -4),
              spreadRadius: 0,
            ),
          ],
        ),
        child: SafeArea(
          bottom: true,
          child: SizedBox(
            height: _getNavBarHeight(context),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 8.0,
                vertical: 8.0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _buildBottomNavItem(
                    context: context,
                    icon: Icons.home_outlined,
                    activeIcon: Icons.home_rounded,
                    label: 'Home',
                    index: 0,
                  ),
                  _buildBottomNavItem(
                    context: context,
                    icon: Icons.local_gas_station_outlined,
                    activeIcon: Icons.local_gas_station_rounded,
                    label: 'Fueling',
                    index: 1,
                  ),
                  _buildCenterAddButton(context),
                  _buildBottomNavItem(
                    context: context,
                    icon: Icons.build_outlined,
                    activeIcon: Icons.build_rounded,
                    label: 'Service',
                    index: 2,
                  ),
                  _buildBottomNavItem(
                    context: context,
                    icon: Icons.share_location_outlined,
                    activeIcon: Icons.share_location_rounded,
                    label: 'Trip',
                    index: 3,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNavItem({
    required BuildContext context,
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required int index,
  }) {
    final isActive = _currentIndex == index;
    final iconSize = _getIconSize(context);
    final fontSize = _getLabelFontSize(context);

    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _onNavItemTapped(index),
          borderRadius: BorderRadius.circular(12),
          splashColor: Colors.white.withOpacity(0.1),
          highlightColor: Colors.white.withOpacity(0.05),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeInOut,
                  padding: EdgeInsets.all(isActive ? 3.0 : 0.0),
                  decoration: BoxDecoration(
                    color:
                        isActive
                            ? Colors.white.withOpacity(0.15)
                            : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    isActive ? activeIcon : icon,
                    color: Colors.white,
                    size: iconSize,
                  ),
                ),
                const SizedBox(height: 3),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: fontSize,
                      fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                      color: Colors.white,
                      letterSpacing: 0,
                      height: 1.1,
                    ),
                    maxLines: 1,
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCenterAddButton(BuildContext context) {
    final buttonSize = _getButtonSize(context);
    final iconSize = buttonSize * 0.45;

    return Container(
      width: buttonSize,
      height: buttonSize,
      margin: const EdgeInsets.symmetric(horizontal: 8.0),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white, Colors.white.withOpacity(0.95)],
        ),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.15),
            blurRadius: 12,
            offset: const Offset(0, 4),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        child: InkWell(
          onTap:
              () => showDialog(
                context: context,
                builder:
                    (context) => EntryTypeSelectionDialog(
                      controller: _mileageController,
                    ),
              ),
          borderRadius: BorderRadius.circular(buttonSize / 2),
          splashColor: primaryColor.withOpacity(0.15),
          highlightColor: primaryColor.withOpacity(0.08),
          child: Center(
            child: Icon(
              Icons.add_rounded,
              color: primaryColor,
              size: iconSize,
              weight: 2.0,
            ),
          ),
        ),
      ),
    );
  }
}

// Content wrapper for Home
class HomeContent extends StatelessWidget {
  const HomeContent({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const HomePage(showBottomNav: false);
  }
}

// Content wrapper for Detailed History
class DetailedHistoryContent extends StatelessWidget {
  const DetailedHistoryContent({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const DetailedHistoryScreen(showBottomNav: false);
  }
}

// Content wrapper for Notification
class NotificationContent extends StatelessWidget {
  const NotificationContent({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const NotificationScreen(showBottomNav: false);
  }
}

// Content wrapper for User Profile
class UserProfileContent extends StatelessWidget {
  const UserProfileContent({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const UserProfileScreen(showBottomNav: false);
  }
}

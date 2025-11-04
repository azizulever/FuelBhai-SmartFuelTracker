import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mileage_calculator/controllers/mileage_controller.dart';
import 'package:mileage_calculator/screens/auth/user_profile_screen.dart';
import 'package:mileage_calculator/screens/detailed_history_screen.dart';
import 'package:mileage_calculator/screens/home_screen.dart';
import 'package:mileage_calculator/screens/notification_screen.dart';
import 'package:mileage_calculator/screens/service_screen.dart';
import 'package:mileage_calculator/screens/trip_screen.dart';
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
  late PageController _pageController;
  late MileageGetxController _mileageController;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: _currentIndex);

    // Try to find existing controller first, create if not found
    try {
      _mileageController = Get.find<MileageGetxController>();
      print("MainNavigation found existing MileageController");
    } catch (e) {
      _mileageController = Get.put(MileageGetxController());
      print("MainNavigation created new MileageController");
    }
    print("MainNavigation initialized with index: $_currentIndex");
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onNavItemTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    print("Building MainNavigation with currentIndex: $_currentIndex");
    return Scaffold(
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        children: [
          HomePage(showBottomNav: false), // 0 - Home
          DetailedHistoryScreen(showBottomNav: false), // 1 - Fueling
          ServiceScreen(showBottomNav: false), // 2 - Service
          TripScreen(showBottomNav: false), // 3 - Trip
          UserProfileScreen(showBottomNav: false), // 4 - Profile (from top bar)
        ],
      ),
      bottomNavigationBar: Container(
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
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildBottomNavItem(
                  icon: Icons.home_outlined,
                  label: 'Home',
                  index: 0,
                ),
                _buildBottomNavItem(
                  icon: Icons.local_gas_station_rounded,
                  label: 'Fueling',
                  index: 1,
                ),
                _buildBottomNavItem(
                  icon: Icons.build_rounded,
                  label: 'Service',
                  index: 2,
                ),
                _buildBottomNavItem(
                  icon: Icons.share_location_sharp,
                  label: 'Trip',
                  index: 3,
                ),
                _buildCenterAddButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNavItem({
    required IconData icon,
    required String label,
    required int index,
  }) {
    final isActive = _currentIndex == index;
    return GestureDetector(
      onTap: () => _onNavItemTapped(index),
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

  Widget _buildCenterAddButton() {
    return GestureDetector(
      onTap:
          () => showDialog(
            context: context,
            builder:
                (context) =>
                    EntryTypeSelectionDialog(controller: _mileageController),
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

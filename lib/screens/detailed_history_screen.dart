import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mileage_calculator/controllers/mileage_controller.dart';
import 'package:mileage_calculator/utils/theme.dart';
import 'package:mileage_calculator/widgets/custom_tab_bar.dart';
import 'package:mileage_calculator/widgets/empty_history_placeholder.dart';
import 'package:mileage_calculator/widgets/fuel_entry_list.dart';
import 'package:mileage_calculator/widgets/add_entry_dialog.dart';
import 'package:mileage_calculator/widgets/main_navigation.dart';

class DetailedHistoryScreen extends StatefulWidget {
  final bool showBottomNav;

  const DetailedHistoryScreen({Key? key, this.showBottomNav = true})
    : super(key: key);

  @override
  State<DetailedHistoryScreen> createState() => _DetailedHistoryScreenState();
}

class _DetailedHistoryScreenState extends State<DetailedHistoryScreen> {
  int _selectedTabIndex = 0;

  @override
  Widget build(BuildContext context) {
    return GetBuilder<MileageGetxController>(
      init: MileageGetxController(),
      builder: (controller) {
        return Scaffold(
          appBar: AppBar(
            title: Text(
              '${controller.selectedVehicleType} Fueling Details',
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 18),
            ),
            centerTitle: true,
            backgroundColor: primaryColor,
            foregroundColor: Colors.white,
            elevation: 0,
            leading:
                widget.showBottomNav
                    ? IconButton(
                      icon: const Icon(Icons.arrow_back_rounded),
                      onPressed: () => Navigator.of(context).pop(),
                    )
                    : null,
          ),
          body: Column(
            children: [
              // Statistics section
              Container(
                width: double.infinity,
                padding: const EdgeInsets.only(left: 16, right: 16, bottom: 12),
                decoration: BoxDecoration(
                  color: primaryColor,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(16),
                    bottomRight: Radius.circular(16),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: primaryColor.withOpacity(0.3),
                      spreadRadius: 1,
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.only(top: 18, bottom: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildStatItem(
                            title: 'Total Fuel',
                            value:
                                '${controller.getTotalFuel().toStringAsFixed(2)}L',
                            icon: Icons.local_gas_station_rounded,
                          ),
                          _buildStatItem(
                            title: 'Total Cost',
                            value:
                                '৳${controller.getTotalCost().toStringAsFixed(0)}',
                            icon: Icons.payments_rounded,
                          ),
                          _buildStatItem(
                            title: 'Total Distance',
                            value:
                                '${controller.getTotalDistance().toStringAsFixed(0)}KM',
                            icon: Icons.map_rounded,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 8),
              CustomTabBar(
                tabs: const ['All History', 'Best Cost', 'Best Mileage'],
                onTabChanged: (index) {
                  setState(() {
                    _selectedTabIndex = index;
                  });
                },
                initialIndex: _selectedTabIndex,
              ),
              const SizedBox(height: 4),
              // Tab content
              Expanded(
                child:
                    controller.filteredEntries.isEmpty
                        ? EmptyHistoryPlaceholder(
                          vehicleType: controller.selectedVehicleType,
                        )
                        : Container(
                          margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
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
          bottomNavigationBar:
              widget.showBottomNav
                  ? _buildBottomNavigation(context, controller)
                  : null,
        );
      },
    );
  }

  Widget _buildStatItem({
    required String title,
    required String value,
    required IconData icon,
  }) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: Colors.white, size: 22),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          title,
          style: TextStyle(fontSize: 10, color: Colors.white.withOpacity(0.8)),
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

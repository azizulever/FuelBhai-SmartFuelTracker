import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:mileage_calculator/controllers/mileage_controller.dart';
import 'package:mileage_calculator/models/fuel_entry.dart';
import 'package:mileage_calculator/models/service_record.dart';
import 'package:mileage_calculator/models/trip_record.dart';
import 'package:mileage_calculator/utils/theme.dart';
import 'package:mileage_calculator/widgets/edit_entry_dialog.dart';
import 'package:mileage_calculator/widgets/main_navigation.dart';

// Combined entry class to hold fuel, service, and trip entries
class CombinedEntry {
  final DateTime date;
  final FuelEntry? fuelEntry;
  final ServiceRecord? serviceRecord;
  final TripRecord? tripRecord;
  final String entryType; // 'fuel', 'service', or 'trip'

  CombinedEntry({
    required this.date,
    this.fuelEntry,
    this.serviceRecord,
    this.tripRecord,
    required this.entryType,
  });
}

class FuelEntryList extends StatefulWidget {
  final List<FuelEntry> entries;
  final MileageGetxController controller;
  final String listType; // "all", "recent", or "best"
  final bool
  showServiceRecords; // Whether to show service records alongside fuel entries
  final bool
  showTripRecords; // Whether to show trip records alongside fuel entries

  const FuelEntryList({
    required this.entries,
    required this.controller,
    this.listType = "all",
    this.showServiceRecords =
        true, // Default to true for backward compatibility (home screen)
    this.showTripRecords = true, // Default to true for home screen
    Key? key,
  }) : super(key: key);

  @override
  State<FuelEntryList> createState() => _FuelEntryListState();
}

class _FuelEntryListState extends State<FuelEntryList> {
  final ScrollController _scrollController = ScrollController();

  List<FuelEntry> get entries => widget.entries;
  MileageGetxController get controller => widget.controller;
  bool get showServiceRecords => widget.showServiceRecords;
  bool get showTripRecords => widget.showTripRecords;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Combine fuel entries, service records, and trip records
    List<CombinedEntry> combinedList = [];

    // Add fuel entries
    for (var entry in entries) {
      combinedList.add(
        CombinedEntry(date: entry.date, fuelEntry: entry, entryType: 'fuel'),
      );
    }

    // Add service records filtered by vehicle type (only if showServiceRecords is true)
    if (showServiceRecords) {
      for (var service in controller.filteredServiceRecords) {
        combinedList.add(
          CombinedEntry(
            date: service.serviceDate,
            serviceRecord: service,
            entryType: 'service',
          ),
        );
      }
    }

    // Add trip records filtered by vehicle type (only if showTripRecords is true)
    if (showTripRecords) {
      for (var trip in controller.filteredTripRecords) {
        // Only show completed trips (not active trips)
        if (!trip.isActive && trip.endTime != null) {
          combinedList.add(
            CombinedEntry(
              date: trip.endTime!,
              tripRecord: trip,
              entryType: 'trip',
            ),
          );
        }
      }
    }

    // Sort by date (newest first) — base order for all tabs
    combinedList.sort((a, b) => b.date.compareTo(a.date));

    // Apply tab-specific sorting for fuel-only views
    if (widget.listType == 'best_cost') {
      // Sort by cost-per-litre ascending (cheapest/best first)
      // Entries without fuel data go to the end
      combinedList.sort((a, b) {
        if (a.entryType != 'fuel' && b.entryType != 'fuel') return 0;
        if (a.entryType != 'fuel') return 1;
        if (b.entryType != 'fuel') return -1;
        final fa = a.fuelEntry!;
        final fb = b.fuelEntry!;
        if (fa.fuelAmount <= 0 && fb.fuelAmount <= 0) return 0;
        if (fa.fuelAmount <= 0) return 1;
        if (fb.fuelAmount <= 0) return -1;
        final costA = fa.fuelCost / fa.fuelAmount;
        final costB = fb.fuelCost / fb.fuelAmount;
        return costA.compareTo(costB); // ascending = best (lowest) cost first
      });
    } else if (widget.listType == 'best_mileage') {
      // Pre-calculate mileage for each fuel entry using the original date-sorted entries list
      // (entries are sorted newest-first, so entries[i+1] is the previous chronological entry)
      final fuelOnlyInOrder =
          entries; // already filtered by vehicle type, date-sorted newest-first
      double? _calcMileage(FuelEntry current) {
        final idx = fuelOnlyInOrder.indexOf(current);
        if (idx < 0 || idx >= fuelOnlyInOrder.length - 1) return null;
        final prev = fuelOnlyInOrder[idx + 1];
        final dist = current.odometer - prev.odometer;
        if (dist <= 0 || current.fuelAmount <= 0) return null;
        return dist / current.fuelAmount;
      }

      combinedList.sort((a, b) {
        if (a.entryType != 'fuel' && b.entryType != 'fuel') return 0;
        if (a.entryType != 'fuel') return 1;
        if (b.entryType != 'fuel') return -1;
        final mA = _calcMileage(a.fuelEntry!);
        final mB = _calcMileage(b.fuelEntry!);
        if (mA == null && mB == null) return 0;
        if (mA == null) return 1; // null (first entry) goes to end
        if (mB == null) return -1;
        return mB.compareTo(mA); // descending = best (highest) mileage first
      });
    }

    return Scrollbar(
      controller: _scrollController,
      thumbVisibility: true,
      thickness: 4,
      radius: const Radius.circular(8),
      child: ListView.separated(
        controller: _scrollController,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        itemCount: combinedList.length,
        separatorBuilder:
            (context, index) =>
                Divider(height: 1, thickness: 1, color: Colors.grey[300]!),
        itemBuilder: (context, index) {
          final combinedEntry = combinedList[index];

          switch (combinedEntry.entryType) {
            case 'fuel':
              return _buildFuelEntryCard(context, combinedEntry.fuelEntry!);
            case 'service':
              return _buildServiceEntryCard(
                context,
                combinedEntry.serviceRecord!,
              );
            case 'trip':
              return _buildTripEntryCard(context, combinedEntry.tripRecord!);
            default:
              return const SizedBox.shrink();
          }
        },
      ),
    );
  }

  Widget _buildFuelEntryCard(BuildContext context, FuelEntry entry) {
    final originalIndex = entries.indexOf(entry);
    final isFirst = originalIndex == entries.length - 1;
    final mileage = controller.calculateMileage(
      entry,
      originalIndex < entries.length - 1 ? entries[originalIndex + 1] : null,
    );

    final perLiterCost =
        entry.fuelAmount > 0
            ? (entry.fuelCost / entry.fuelAmount).toStringAsFixed(2)
            : "N/A";

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(right: 10, top: 4),
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFF0F4FF),
            ),
            child: Center(
              child: Icon(
                Icons.local_gas_station_rounded,
                color: primaryColor,
                size: 22,
              ),
            ),
          ),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  DateFormat('MMM d, yyyy').format(entry.date),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Odometer: ${entry.odometer.toStringAsFixed(1)} KM',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  'Fuel: ${entry.fuelAmount.toStringAsFixed(2)} Liters',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),

          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              isFirst
                  ? const Text(
                    'Initial Data',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  )
                  : mileage != null
                  ? Text(
                    '${mileage.toStringAsFixed(1)} KM/L',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: primaryColor,
                    ),
                  )
                  : const SizedBox(),

              if (!isFirst && perLiterCost != "N/A")
                Text(
                  '৳$perLiterCost/L',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.green[600],
                  ),
                ),

              Padding(
                padding: const EdgeInsets.only(top: 6.0),
                child: GestureDetector(
                  onTap: () => _showFuelOptions(context, entry, originalIndex),
                  child: Icon(
                    Icons.more_vert,
                    color: Colors.grey[600],
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildServiceEntryCard(BuildContext context, ServiceRecord service) {
    final isMajor = service.serviceType == 'Major';
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(right: 10, top: 4),
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFF0F4FF),
            ),
            child: Center(
              child: Icon(Icons.build_rounded, color: primaryColor, size: 22),
            ),
          ),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      'Service',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color:
                            isMajor
                                ? const Color(0xFFFFEBEE)
                                : const Color(0xFFFFF3E0),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        service.serviceType,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isMajor ? Colors.red : Colors.orange,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  DateFormat('MMM dd, yyyy').format(service.serviceDate),
                  style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                ),
                const SizedBox(height: 2),
                Text(
                  'Odo: ${service.odometerReading.toStringAsFixed(2)} km',
                  style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                ),
              ],
            ),
          ),

          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '৳ ${service.totalCost.toStringAsFixed(0)}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isMajor ? Colors.red : Colors.orange,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Total Cost',
                style: TextStyle(fontSize: 11, color: Colors.grey[600]),
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () => _showServiceOptions(context, service),
                child: Icon(Icons.more_vert, color: Colors.grey[400], size: 20),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTripEntryCard(BuildContext context, TripRecord trip) {
    // Format duration
    String formatDuration(Duration duration) {
      final hours = duration.inHours;
      final minutes = duration.inMinutes.remainder(60);
      if (hours > 0) {
        return '${hours}h ${minutes}m';
      }
      return '${minutes}m';
    }

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(right: 10, top: 4),
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFF0F4FF),
            ),
            child: Center(
              child: Icon(
                Icons.share_location_sharp,
                color: primaryColor,
                size: 22,
              ),
            ),
          ),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      'Trip',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      DateFormat('MMM d, yyyy').format(trip.endTime!),
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Icon(
                      Icons.timer_outlined,
                      size: 14,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      formatDuration(trip.duration),
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Icon(
                      Icons.receipt_outlined,
                      size: 14,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${trip.costEntries.length} ${trip.costEntries.length == 1 ? 'entry' : 'entries'}',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '৳ ${trip.totalCost.toStringAsFixed(0)}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[700],
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Total Cost',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),

              Padding(
                padding: const EdgeInsets.only(top: 6.0),
                child: GestureDetector(
                  onTap: () => _showTripOptions(context, trip),
                  child: Icon(
                    Icons.more_vert,
                    color: Colors.grey[600],
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showTripOptions(BuildContext context, TripRecord trip) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (context) => Container(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.delete, color: Colors.red),
                  ),
                  title: const Text('Delete Trip'),
                  onTap: () {
                    Navigator.pop(context);
                    _showDeleteTripConfirmation(context, trip);
                  },
                ),
              ],
            ),
          ),
    );
  }

  void _showServiceOptions(BuildContext context, ServiceRecord service) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (context) => Container(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.purple.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.visibility, color: Colors.purple),
                  ),
                  title: const Text('View Service Details'),
                  onTap: () {
                    Navigator.pop(context);
                    Get.offAll(() => const MainNavigation(initialIndex: 2));
                  },
                ),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.edit, color: Colors.orange),
                  ),
                  title: const Text('Edit Service'),
                  onTap: () {
                    Navigator.pop(context);
                    _showEditServiceDialog(context, service);
                  },
                ),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.delete, color: Colors.red),
                  ),
                  title: const Text('Delete Service'),
                  onTap: () {
                    Navigator.pop(context);
                    _showDeleteServiceConfirmation(context, service);
                  },
                ),
              ],
            ),
          ),
    );
  }

  void _showEditEntryDialog(BuildContext context, FuelEntry entry, int index) {
    showDialog(
      context: context,
      builder:
          (context) => EditEntryDialog(
            controller: controller,
            entry: entry,
            index: index,
          ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, int index) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss',
      barrierColor: Colors.black.withOpacity(0.5),
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (context, anim1, anim2) => const SizedBox.shrink(),
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curvedAnimation = CurvedAnimation(
          parent: animation,
          curve: Curves.easeInOut,
        );

        return ScaleTransition(
          scale: Tween<double>(begin: 0.8, end: 1.0).animate(curvedAnimation),
          child: FadeTransition(
            opacity: curvedAnimation,
            child: Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              elevation: 0,
              backgroundColor: Colors.transparent,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(20),
                          topRight: Radius.circular(20),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.delete_outline_rounded,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'Confirm Deletion',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),

                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          Text(
                            'Are you sure you want to delete this entry?',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[800],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'This action cannot be undone.',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 24),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(),
                                style: TextButton.styleFrom(
                                  foregroundColor: Colors.grey[700],
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                    vertical: 12,
                                  ),
                                ),
                                child: const Text(
                                  'CANCEL',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),

                              ElevatedButton(
                                onPressed: () {
                                  controller.deleteEntry(index);
                                  Navigator.of(context).pop();
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                    vertical: 12,
                                  ),
                                ),
                                child: const Text(
                                  'DELETE',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _showFuelOptions(
    BuildContext context,
    FuelEntry entry,
    int originalIndex,
  ) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (context) => Container(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.edit, color: Colors.blue),
                  ),
                  title: const Text('Edit Entry'),
                  onTap: () {
                    Navigator.pop(context);
                    _showEditEntryDialog(context, entry, originalIndex);
                  },
                ),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.delete, color: Colors.red),
                  ),
                  title: const Text('Delete Entry'),
                  onTap: () {
                    Navigator.pop(context);
                    _showDeleteConfirmation(context, originalIndex);
                  },
                ),
              ],
            ),
          ),
    );
  }

  void _showEditServiceDialog(BuildContext context, ServiceRecord service) {
    // TODO: Implement edit service dialog
    Get.snackbar(
      'Coming Soon',
      'Edit service functionality will be available soon!',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: primaryColor,
      colorText: Colors.white,
      margin: const EdgeInsets.all(16),
      borderRadius: 8,
    );
  }

  void _showEditTripDialog(BuildContext context, TripRecord trip) {
    // TODO: Implement edit trip dialog
    Get.snackbar(
      'Coming Soon',
      'Edit trip functionality will be available soon!',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: primaryColor,
      colorText: Colors.white,
      margin: const EdgeInsets.all(16),
      borderRadius: 8,
    );
  }

  void _showDeleteServiceConfirmation(
    BuildContext context,
    ServiceRecord service,
  ) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss',
      barrierColor: Colors.black.withOpacity(0.5),
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (context, anim1, anim2) => const SizedBox.shrink(),
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curvedAnimation = CurvedAnimation(
          parent: animation,
          curve: Curves.easeInOut,
        );

        return ScaleTransition(
          scale: Tween<double>(begin: 0.8, end: 1.0).animate(curvedAnimation),
          child: FadeTransition(
            opacity: curvedAnimation,
            child: Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              elevation: 0,
              backgroundColor: Colors.transparent,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(20),
                          topRight: Radius.circular(20),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.delete_outline_rounded,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'Confirm Deletion',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),

                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          Text(
                            'Are you sure you want to delete this service record?',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[800],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'This action cannot be undone.',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 24),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(),
                                style: TextButton.styleFrom(
                                  foregroundColor: Colors.grey[700],
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                    vertical: 12,
                                  ),
                                ),
                                child: const Text(
                                  'CANCEL',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),

                              ElevatedButton(
                                onPressed: () {
                                  controller.deleteServiceRecord(service.id);
                                  Navigator.of(context).pop();
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                    vertical: 12,
                                  ),
                                ),
                                child: const Text(
                                  'DELETE',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _showDeleteTripConfirmation(BuildContext context, TripRecord trip) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss',
      barrierColor: Colors.black.withOpacity(0.5),
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (context, anim1, anim2) => const SizedBox.shrink(),
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curvedAnimation = CurvedAnimation(
          parent: animation,
          curve: Curves.easeInOut,
        );

        return ScaleTransition(
          scale: Tween<double>(begin: 0.8, end: 1.0).animate(curvedAnimation),
          child: FadeTransition(
            opacity: curvedAnimation,
            child: Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              elevation: 0,
              backgroundColor: Colors.transparent,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(20),
                          topRight: Radius.circular(20),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.delete_outline_rounded,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'Confirm Deletion',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),

                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          Text(
                            'Are you sure you want to delete this trip record?',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[800],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'This action cannot be undone.',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 24),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(),
                                style: TextButton.styleFrom(
                                  foregroundColor: Colors.grey[700],
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                    vertical: 12,
                                  ),
                                ),
                                child: const Text(
                                  'CANCEL',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),

                              ElevatedButton(
                                onPressed: () {
                                  controller.deleteTripRecord(trip);
                                  Navigator.of(context).pop();
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                    vertical: 12,
                                  ),
                                ),
                                child: const Text(
                                  'DELETE',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

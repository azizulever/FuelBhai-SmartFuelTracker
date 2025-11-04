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

class FuelEntryList extends StatelessWidget {
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

    // Sort by date (newest first)
    combinedList.sort((a, b) => b.date.compareTo(a.date));

    return ListView.separated(
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
              color: Colors.grey[50],
            ),
            child: Center(
              child: Icon(
                entry.vehicleType == 'Car'
                    ? Icons.directions_car_rounded
                    : Icons.two_wheeler_rounded,
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
                padding: const EdgeInsets.only(top: 2.0),
                child: Row(
                  children: [
                    Container(
                      margin: const EdgeInsets.only(right: 6),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: Colors.blue.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(6),
                        onTap:
                            () => _showEditEntryDialog(
                              context,
                              entry,
                              originalIndex,
                            ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 3,
                          ),
                          child: const Icon(
                            Icons.edit_outlined,
                            color: Colors.blue,
                            size: 18,
                          ),
                        ),
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: Colors.red.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(6),
                        onTap:
                            () =>
                                _showDeleteConfirmation(context, originalIndex),
                        child: const Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 3,
                          ),
                          child: Icon(
                            Icons.delete_outline,
                            color: Colors.red,
                            size: 18,
                          ),
                        ),
                      ),
                    ),
                  ],
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
              color:
                  isMajor ? const Color(0xFFFFEBEE) : const Color(0xFFFFF3E0),
            ),
            child: Center(
              child: Icon(
                Icons.build_rounded,
                color: isMajor ? Colors.red : Colors.orange,
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
                      'Service',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      DateFormat('MMM d, yyyy').format(service.serviceDate),
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
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: isMajor ? Colors.red : Colors.orange,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        service.serviceType,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  'Odo: ${service.odometerReading.toStringAsFixed(0)} km',
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
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),

              Padding(
                padding: const EdgeInsets.only(top: 6.0),
                child: GestureDetector(
                  onTap: () => _showServiceOptions(context, service),
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
              color: const Color(0xFFE3F2FD),
            ),
            child: Center(
              child: Icon(
                Icons.share_location_sharp,
                color: Colors.blue[700],
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
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.visibility, color: Colors.blue),
                  ),
                  title: const Text('View Trip Details'),
                  onTap: () {
                    Navigator.pop(context);
                    Get.offAll(() => const MainNavigation(initialIndex: 3));
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
}

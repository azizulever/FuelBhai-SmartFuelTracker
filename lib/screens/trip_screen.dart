import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:mileage_calculator/controllers/mileage_controller.dart';
import 'package:mileage_calculator/models/trip_record.dart';
import 'package:mileage_calculator/utils/theme.dart';
import 'package:mileage_calculator/services/analytics_service.dart';

class TripScreen extends StatefulWidget {
  final bool showBottomNav;
  final VoidCallback? onBack;

  const TripScreen({Key? key, this.showBottomNav = true, this.onBack})
    : super(key: key);

  @override
  State<TripScreen> createState() => _TripScreenState();
}

class _TripScreenState extends State<TripScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    AnalyticsService.to.logScreenView('TripScreen');
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
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
        final isActive = controller.isTripActive;
        final activeTrip = controller.activeTrip;
        final completedTrips = controller.completedTrips;

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
                  // Styled Header
                  _buildHeader(context),

                  SizedBox(height: isSmall ? 12 : 16),

                  // Top Status Card
                  _buildTopStatusCard(
                    context,
                    controller,
                    isActive,
                    // When active show the live trip; otherwise show the last
                    // completed trip so the card displays its duration/cost and
                    // the button reads “New Trip” instead of “Start Trip”.
                    isActive
                        ? activeTrip
                        : (completedTrips.isNotEmpty
                            ? completedTrips.first
                            : null),
                    isSmall,
                    horizontalPadding,
                  ),

                  SizedBox(height: isSmall ? 12 : 16),

                  // Cost Entries or Trip History
                  Expanded(
                    child:
                        isActive
                            ? _buildCostEntriesList(
                              context,
                              controller,
                              activeTrip!,
                            )
                            : completedTrips.isEmpty
                            ? _buildTripHistory(completedTrips)
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
                              child: _buildTripHistory(completedTrips),
                            ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context) {
    final horizontalPadding = _getResponsivePadding(context);
    final isSmall = _isSmallScreen(context);

    return Container(
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
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          horizontalPadding,
          MediaQuery.of(context).padding.top + (isSmall ? 10 : 12),
          horizontalPadding,
          isSmall ? 16 : 20,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            GestureDetector(
              onTap:
                  () => widget.onBack != null ? widget.onBack!() : Get.back(),
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
              'Trips',
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
    );
  }

  Widget _buildTopStatusCard(
    BuildContext context,
    MileageGetxController controller,
    bool isActive,
    TripRecord? trip,
    bool isSmall,
    double horizontalPadding,
  ) {
    // Determine status color and text
    Color statusColor;
    String statusText;
    if (isActive) {
      statusColor = Colors.green;
      statusText = 'Active';
    } else if (trip != null && trip.endTime != null) {
      statusColor = primaryColor;
      statusText = 'Completed';
    } else {
      statusColor = Colors.grey;
      statusText = 'Ready to start';
    }

    return Container(
      margin: EdgeInsets.symmetric(horizontal: horizontalPadding),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(isSmall ? 14 : 16),
        border: Border.all(color: primaryColor.withOpacity(0.3), width: 2),
      ),
      child: Padding(
        padding: EdgeInsets.all(isSmall ? 18 : 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Row
            Row(
              children: [
                Container(
                  width: isSmall ? 10 : 12,
                  height: isSmall ? 10 : 12,
                  decoration: BoxDecoration(
                    color: statusColor,
                    shape: BoxShape.circle,
                  ),
                ),
                SizedBox(width: isSmall ? 8 : 10),
                Text(
                  statusText,
                  style: TextStyle(
                    fontSize: isSmall ? 16 : 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),

            // Duration Display (shown when active or completed)
            if (isActive || (trip != null && trip.endTime != null)) ...[
              SizedBox(height: isSmall ? 14 : 18),
              Text(
                'Duration',
                style: TextStyle(
                  fontSize: isSmall ? 13 : 14,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w400,
                ),
              ),
              SizedBox(height: isSmall ? 4 : 6),
              Text(
                _formatDuration(trip),
                style: TextStyle(
                  fontSize: isSmall ? 32 : 38,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                  height: 1.1,
                ),
              ),
            ],

            // Cost Display
            SizedBox(height: isSmall ? 14 : 18),
            Text(
              'Total Cost',
              style: TextStyle(
                fontSize: isSmall ? 13 : 14,
                color: Colors.grey[600],
                fontWeight: FontWeight.w400,
              ),
            ),
            SizedBox(height: isSmall ? 4 : 6),
            Text(
              'tk ${(trip?.totalCost ?? 0.0).toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: isSmall ? 28 : 34,
                fontWeight: FontWeight.bold,
                color: primaryColor,
                height: 1.1,
              ),
            ),

            // Entry count (if any)
            if (trip != null && trip.costEntries.isNotEmpty) ...[
              SizedBox(height: isSmall ? 6 : 8),
              Text(
                '${trip.costEntries.length} ${trip.costEntries.length == 1 ? 'entry' : 'entries'}',
                style: TextStyle(
                  fontSize: isSmall ? 12 : 13,
                  color: Colors.grey[500],
                ),
              ),
            ],

            // Action Button
            SizedBox(height: isSmall ? 20 : 24),
            SizedBox(
              width: double.infinity,
              height: isSmall ? 50 : 56,
              child: ElevatedButton(
                onPressed: () {
                  if (isActive) {
                    _showStopTripConfirmation(context, controller);
                  } else if (trip != null && trip.endTime != null) {
                    controller.startTrip();
                  } else {
                    controller.startTrip();
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      isActive
                          ? Colors.red.withOpacity(0.1)
                          : primaryColor.withOpacity(0.1),
                  foregroundColor: isActive ? Colors.red : primaryColor,
                  elevation: 0,
                  shadowColor: Colors.transparent,
                  side: BorderSide(
                    color: isActive ? Colors.red : primaryColor,
                    width: 1,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      isActive
                          ? Icons.stop_rounded
                          : (trip != null && trip.endTime != null)
                          ? Icons.add_rounded
                          : Icons.play_arrow_rounded,
                      size: isSmall ? 22 : 24,
                    ),
                    SizedBox(width: isSmall ? 6 : 8),
                    Text(
                      isActive
                          ? 'Stop Trip'
                          : (trip != null && trip.endTime != null)
                          ? 'New Trip'
                          : 'Start Trip',
                      style: TextStyle(
                        fontSize: isSmall ? 15 : 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDuration(TripRecord? trip) {
    if (trip == null) return '00:00:00';
    final duration = trip.duration;
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  Widget _buildCostEntriesList(
    BuildContext context,
    MileageGetxController controller,
    TripRecord trip,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header with Add Cost button
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Cost Entries',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                GestureDetector(
                  onTap: () => _showAddCostDialog(context, controller),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: const [
                        Icon(Icons.add, size: 18, color: primaryColor),
                        SizedBox(width: 4),
                        Text(
                          'Add Cost',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: primaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Cost entries list
          Expanded(
            child:
                trip.costEntries.isEmpty
                    ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.receipt_long_outlined,
                            size: 64,
                            color: Colors.grey[300],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No cost entries yet',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[500],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Tap "Add Cost" to add expenses',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[400],
                            ),
                          ),
                        ],
                      ),
                    )
                    : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: trip.costEntries.length,
                      separatorBuilder:
                          (context, index) => const Divider(height: 24),
                      itemBuilder: (context, index) {
                        final entry = trip.costEntries[index];
                        return _buildCostEntryCard(context, controller, entry);
                      },
                    ),
          ),
        ],
      ),
    );
  }

  Widget _buildCostEntryCard(
    BuildContext context,
    MileageGetxController controller,
    TripCostEntry entry,
  ) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.red[50],
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.receipt_rounded, color: Colors.red, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                entry.description.isEmpty
                    ? 'Entry ${controller.activeTrip!.costEntries.indexOf(entry) + 1}'
                    : entry.description,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                DateFormat('MMM d, yyyy • hh:mm a').format(entry.timestamp),
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
        Text(
          '৳ ${entry.amount.toStringAsFixed(2)}',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.red,
          ),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: () => _showDeleteCostConfirmation(context, controller, entry),
          child: Icon(Icons.delete_outline, color: Colors.grey[400], size: 20),
        ),
      ],
    );
  }

  Widget _buildTripHistory(List<TripRecord> trips) {
    if (trips.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history_rounded, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              'No trip history',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[500],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Start your first trip to track expenses',
              style: TextStyle(fontSize: 14, color: Colors.grey[400]),
            ),
          ],
        ),
      );
    }

    final scrollController = _scrollController;
    return Scrollbar(
      controller: scrollController,
      thumbVisibility: true,
      thickness: 4,
      radius: const Radius.circular(8),
      child: ListView.separated(
        controller: scrollController,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        itemCount: trips.length,
        separatorBuilder:
            (context, index) =>
                Divider(height: 1, thickness: 1, color: Colors.grey[300]!),
        itemBuilder: (context, index) {
          final trip = trips[index];
          return _buildTripHistoryCard(context, trip);
        },
      ),
    );
  }

  Widget _buildTripHistoryCard(BuildContext context, TripRecord trip) {
    final duration = trip.duration;
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final durationText = hours > 0 ? '${hours}h ${minutes}m' : '${minutes}m';

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
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFFF0F4FF),
            ),
            child: const Center(
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
                      DateFormat('MMM d, yyyy').format(trip.startTime),
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
                      durationText,
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
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: primaryColor,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Total Cost',
                style: TextStyle(fontSize: 11, color: Colors.grey[600]),
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () => _showTripHistoryOptions(context, trip),
                child: Icon(Icons.more_vert, color: Colors.grey[400], size: 20),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showTripHistoryOptions(BuildContext context, TripRecord trip) {
    final controller = Get.find<MileageGetxController>();
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
                    _showDeleteTripConfirmation(context, trip, controller);
                  },
                ),
              ],
            ),
          ),
    );
  }

  void _showDeleteTripConfirmation(
    BuildContext context,
    TripRecord trip,
    MileageGetxController controller,
  ) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text('Delete Trip?'),
            content: const Text(
              'Are you sure you want to delete this trip? This action cannot be undone.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  controller.deleteTripRecord(trip);
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Delete'),
              ),
            ],
          ),
    );
  }

  void _showAddCostDialog(
    BuildContext context,
    MileageGetxController controller,
  ) {
    showDialog(
      context: context,
      builder: (context) => _AddTripCostDialog(controller: controller),
    );
  }

  void _showStopTripConfirmation(
    BuildContext context,
    MileageGetxController controller,
  ) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text('Stop Trip?'),
            content: const Text(
              'Are you sure you want to stop this trip? The timer will stop and the trip will be saved to history.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  controller.stopTrip();
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Stop Trip'),
              ),
            ],
          ),
    );
  }

  void _showDeleteCostConfirmation(
    BuildContext context,
    MileageGetxController controller,
    TripCostEntry entry,
  ) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text('Delete Cost Entry?'),
            content: const Text(
              'Are you sure you want to delete this cost entry?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  controller.deleteTripCostEntry(entry.id);
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Delete'),
              ),
            ],
          ),
    );
  }
}

// Add Trip Cost Dialog Widget
class _AddTripCostDialog extends StatefulWidget {
  final MileageGetxController controller;

  const _AddTripCostDialog({required this.controller});

  @override
  State<_AddTripCostDialog> createState() => _AddTripCostDialogState();
}

class _AddTripCostDialogState extends State<_AddTripCostDialog> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Add Trip Cost',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Amount field
              const Text(
                'Amount',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  hintText: '0.00',
                  prefixText: '৳ ',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter an amount';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  if (double.parse(value) <= 0) {
                    return 'Amount must be greater than 0';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 20),

              // Description field
              const Text(
                'Description (Optional)',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  hintText: 'e.g., Toll, Parking, Fuel',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                maxLength: 50,
              ),

              const SizedBox(height: 24),

              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _submitForm,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Save'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      final amount = double.parse(_amountController.text);
      final description = _descriptionController.text.trim();

      widget.controller.addTripCost(amount, description);
      Navigator.pop(context);
    }
  }
}

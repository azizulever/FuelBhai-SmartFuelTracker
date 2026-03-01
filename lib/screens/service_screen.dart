import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:mileage_calculator/controllers/mileage_controller.dart';
import 'package:mileage_calculator/models/service_record.dart';
import 'package:mileage_calculator/utils/theme.dart';
import 'package:mileage_calculator/widgets/custom_tab_bar.dart';
import 'package:mileage_calculator/services/analytics_service.dart';

class ServiceScreen extends StatefulWidget {
  final bool showBottomNav;
  final VoidCallback? onBack;

  const ServiceScreen({Key? key, this.showBottomNav = true, this.onBack})
    : super(key: key);

  @override
  State<ServiceScreen> createState() => _ServiceScreenState();
}

class _ServiceScreenState extends State<ServiceScreen> {
  int _selectedTabIndex = 0;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    AnalyticsService.to.logScreenView('ServiceScreen');
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
    final isSmall = _isSmallScreen(context);

    return GetBuilder<MileageGetxController>(
      init: MileageGetxController(),
      builder: (controller) {
        final filteredRecords = _getFilteredRecords(controller);

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
                  // Top Header
                  _buildHeader(context, controller),

                  SizedBox(height: isSmall ? 8 : 10),

                  // Filter Tab Bar
                  CustomTabBar(
                    tabs: const ['All History', 'Major only', 'Minor only'],
                    onTabChanged: (index) {
                      setState(() {
                        _selectedTabIndex = index;
                      });
                    },
                    initialIndex: _selectedTabIndex,
                  ),

                  SizedBox(height: isSmall ? 4 : 6),

                  // Service List
                  Expanded(
                    child:
                        filteredRecords.isEmpty
                            ? _buildEmptyState()
                            : Container(
                              margin: EdgeInsets.fromLTRB(
                                _getResponsivePadding(context),
                                0,
                                _getResponsivePadding(context),
                                _getResponsivePadding(context),
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: Colors.grey.shade200),
                              ),
                              child: _buildServiceList(
                                filteredRecords,
                                controller,
                              ),
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

  Widget _buildHeader(BuildContext context, MileageGetxController controller) {
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
      child: Column(
        children: [
          // Back button and title
          Padding(
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
                      () =>
                          widget.onBack != null ? widget.onBack!() : Get.back(),
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
                  'Services',
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

          // Service Icon
          Container(
            padding: EdgeInsets.all(isSmall ? 16 : 20),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.build_rounded,
              color: Colors.white,
              size: isSmall ? 40 : 48,
            ),
          ),

          SizedBox(height: isSmall ? 20 : 24),

          // Horizontal divider lines with icon
          Stack(
            alignment: Alignment.center,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 2,
                      margin: EdgeInsets.only(left: isSmall ? 30 : 40),
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
                      margin: EdgeInsets.only(right: isSmall ? 30 : 40),
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

          // Statistics Row
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: _buildStatItem(
                    context,
                    'Total\nService',
                    controller.totalServiceCount.toString(),
                  ),
                ),
                Container(width: 1, height: 35, color: Colors.white30),
                Expanded(
                  child: _buildStatItem(
                    context,
                    'Total\nCost',
                    '${controller.totalServiceCost.toStringAsFixed(0)}৳',
                  ),
                ),
                Container(width: 1, height: 35, color: Colors.white30),
                Expanded(
                  child: _buildStatItem(
                    context,
                    'Avg\nCost',
                    controller.totalServiceCount > 0
                        ? '${(controller.totalServiceCost / controller.totalServiceCount).toStringAsFixed(0)}৳'
                        : '0৳',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(BuildContext context, String label, String value) {
    final isSmall = _isSmallScreen(context);
    final labelFontSize = _getResponsiveFontSize(context, 11);
    final valueFontSize = isSmall ? 16.0 : 18.0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            label,
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

  Widget _buildServiceList(
    List<ServiceRecord> records,
    MileageGetxController controller,
  ) {
    return Scrollbar(
      controller: _scrollController,
      thumbVisibility: true,
      thickness: 4,
      radius: const Radius.circular(8),
      child: ListView.separated(
        controller: _scrollController,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        itemCount: records.length,
        separatorBuilder:
            (context, index) =>
                Divider(height: 1, thickness: 1, color: Colors.grey[300]!),
        itemBuilder: (context, index) {
          final record = records[index];
          return _buildServiceCard(record, controller);
        },
      ),
    );
  }

  Widget _buildServiceCard(
    ServiceRecord record,
    MileageGetxController controller,
  ) {
    final isMajor = record.serviceType == 'Major';
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon
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

          // Service Info
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
                        record.serviceType,
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
                  DateFormat('MMM dd, yyyy').format(record.serviceDate),
                  style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                ),
                const SizedBox(height: 2),
                Text(
                  'Odo: ${record.odometerReading.toStringAsFixed(2)} km',
                  style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                ),
              ],
            ),
          ),

          // Cost and Actions
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '৳ ${record.totalCost.toStringAsFixed(0)}',
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
                onTap: () {
                  _showServiceOptions(context, record, controller);
                },
                child: Icon(Icons.more_vert, color: Colors.grey[400], size: 20),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.build_circle_outlined, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            'No service records yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add your first service record to track\nyour vehicle maintenance',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  List<ServiceRecord> _getFilteredRecords(MileageGetxController controller) {
    final records = controller.filteredServiceRecords;

    if (_selectedTabIndex == 1) {
      return records.where((r) => r.serviceType == 'Major').toList();
    } else if (_selectedTabIndex == 2) {
      return records.where((r) => r.serviceType == 'Minor').toList();
    }
    return records;
  }

  void _showServiceOptions(
    BuildContext context,
    ServiceRecord record,
    MileageGetxController controller,
  ) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (context) => Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.edit, color: primaryColor),
                  ),
                  title: const Text(
                    'Edit Service',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _showEditServiceDialog(context, record, controller);
                  },
                ),
                const SizedBox(height: 8),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.delete, color: Colors.red),
                  ),
                  title: const Text(
                    'Delete Service',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _showDeleteConfirmation(context, record, controller);
                  },
                ),
              ],
            ),
          ),
    );
  }

  void _showEditServiceDialog(
    BuildContext context,
    ServiceRecord record,
    MileageGetxController controller,
  ) {
    // Import the add service dialog and pass existing data
    showDialog(
      context: context,
      builder:
          (context) => _EditServiceDialog(
            controller: controller,
            existingRecord: record,
          ),
    );
  }

  void _showDeleteConfirmation(
    BuildContext context,
    ServiceRecord record,
    MileageGetxController controller,
  ) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text('Delete Service Record'),
            content: const Text('Are you sure you want to delete this record?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  'Cancel',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ),
              TextButton(
                onPressed: () {
                  controller.deleteServiceRecord(record.id);
                  Navigator.of(context).pop();
                },
                child: const Text(
                  'Delete',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
    );
  }
}

// Edit Service Dialog Widget
class _EditServiceDialog extends StatefulWidget {
  final MileageGetxController controller;
  final ServiceRecord existingRecord;

  const _EditServiceDialog({
    required this.controller,
    required this.existingRecord,
  });

  @override
  State<_EditServiceDialog> createState() => _EditServiceDialogState();
}

class _EditServiceDialogState extends State<_EditServiceDialog>
    with SingleTickerProviderStateMixin {
  late final TextEditingController dateController;
  late final TextEditingController odometerController;
  late final TextEditingController totalCostController;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  final _formKey = GlobalKey<FormState>();
  late String _selectedServiceType;

  @override
  void initState() {
    super.initState();
    // Initialize with existing data
    dateController = TextEditingController(
      text: DateFormat('yyyy-MM-dd').format(widget.existingRecord.serviceDate),
    );
    odometerController = TextEditingController(
      text: widget.existingRecord.odometerReading.toString(),
    );
    totalCostController = TextEditingController(
      text: widget.existingRecord.totalCost.toString(),
    );
    _selectedServiceType = widget.existingRecord.serviceType;

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    dateController.dispose();
    odometerController.dispose();
    totalCostController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: widget.existingRecord.serviceDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: ColorScheme.light(
              primary: primaryColor,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
            dialogBackgroundColor: Colors.white,
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        dateController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Stack(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 30),
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
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.fromLTRB(24, 44, 24, 16),
                      width: double.infinity,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Edit Service Record',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Update service details',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildInputField(
                              label: 'Service Date',
                              controller: dateController,
                              readOnly: true,
                              onTap: () => _selectDate(context),
                              suffixIcon: const Icon(
                                Icons.calendar_today_rounded,
                                color: primaryColor,
                                size: 20,
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please select a date';
                                }
                                return null;
                              },
                            ),
                            _buildInputField(
                              label: 'Odometer Reading (km)',
                              controller: odometerController,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter odometer reading';
                                }
                                if (double.tryParse(value) == null) {
                                  return 'Please enter a valid number';
                                }
                                return null;
                              },
                            ),
                            _buildInputField(
                              label: 'Total Cost (tk)',
                              controller: totalCostController,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter total cost';
                                }
                                if (double.tryParse(value) == null) {
                                  return 'Please enter a valid number';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Service Type',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: primaryColor,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.grey[50],
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey[300]!),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: _buildServiceTypeOption('Major'),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _buildServiceTypeOption('Minor'),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: () {
                                      _animationController.reverse().then((_) {
                                        Navigator.of(context).pop();
                                      });
                                    },
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 16,
                                      ),
                                      side: BorderSide(
                                        color: Colors.grey[400]!,
                                        width: 1,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    child: Text(
                                      'Cancel',
                                      style: TextStyle(
                                        color: Colors.grey[700],
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: _submitForm,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: primaryColor,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 16,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      elevation: 0,
                                    ),
                                    child: const Text(
                                      'Update',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Center(
                child: CircleAvatar(
                  backgroundColor: Colors.purple,
                  radius: 30,
                  child: const Icon(Icons.edit, color: Colors.white, size: 30),
                ),
              ),
            ),
            Positioned(
              top: 40,
              right: 16,
              child: GestureDetector(
                onTap: () {
                  _animationController.reverse().then((_) {
                    Navigator.of(context).pop();
                  });
                },
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.close_rounded,
                    color: Colors.grey[700],
                    size: 20,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceTypeOption(String type) {
    final isSelected = _selectedServiceType == type;
    final Color bgColor =
        type == 'Major'
            ? (isSelected ? Colors.red[50]! : Colors.white)
            : (isSelected ? Colors.orange[50]! : Colors.white);
    final Color borderColor =
        type == 'Major'
            ? (isSelected ? Colors.red : Colors.grey[300]!)
            : (isSelected ? Colors.orange : Colors.grey[300]!);
    final Color textColor =
        type == 'Major'
            ? (isSelected ? Colors.red : Colors.grey[700]!)
            : (isSelected ? Colors.orange : Colors.grey[700]!);

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedServiceType = type;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: borderColor, width: isSelected ? 2 : 1),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isSelected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              color: textColor,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              type,
              style: TextStyle(
                fontSize: 15,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField({
    required String label,
    required TextEditingController controller,
    TextInputType? keyboardType,
    bool readOnly = false,
    VoidCallback? onTap,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: primaryColor,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          readOnly: readOnly,
          onTap: onTap,
          style: const TextStyle(fontSize: 16),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.grey[50],
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: primaryColor, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red, width: 1),
            ),
            suffixIcon: suffixIcon,
          ),
          validator: validator,
        ),
      ],
    );
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      try {
        // Delete old record
        widget.controller.deleteServiceRecord(widget.existingRecord.id);

        final parsed = DateTime.parse(dateController.text);
        final now = DateTime.now();
        final entryDate = DateTime(
          parsed.year,
          parsed.month,
          parsed.day,
          now.hour,
          now.minute,
          now.second,
          now.millisecond,
        );
        // Add updated record
        widget.controller.addServiceEntry(
          entryDate,
          double.parse(odometerController.text),
          double.parse(totalCostController.text),
          _selectedServiceType,
          widget.controller.selectedVehicleType,
        );

        _animationController.reverse().then((_) {
          Navigator.of(context).pop();
        });
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }
}

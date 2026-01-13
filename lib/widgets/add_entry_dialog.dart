import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mileage_calculator/controllers/mileage_controller.dart';
import 'package:mileage_calculator/utils/theme.dart';

class AddEntryDialog extends StatefulWidget {
  final MileageGetxController controller;

  const AddEntryDialog({Key? key, required this.controller}) : super(key: key);

  @override
  State<AddEntryDialog> createState() => _AddEntryDialogState();
}

class _AddEntryDialogState extends State<AddEntryDialog>
    with SingleTickerProviderStateMixin {
  late final TextEditingController dateController;
  late final TextEditingController odometerController;
  late final TextEditingController fuelAmountController;
  late final TextEditingController fuelCostController;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    dateController = TextEditingController(
      text: DateFormat('yyyy-MM-dd').format(DateTime.now()),
    );
    odometerController = TextEditingController();
    fuelAmountController = TextEditingController();
    fuelCostController = TextEditingController();

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
    fuelAmountController.dispose();
    fuelCostController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
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
    final screenHeight = MediaQuery.of(context).size.height;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Stack(
          children: [
            // Dialog content
            ConstrainedBox(
              constraints: BoxConstraints(maxHeight: screenHeight * 0.85),
              child: Container(
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
                      // Title bar
                      Container(
                        padding: const EdgeInsets.fromLTRB(24, 44, 24, 16),
                        width: double.infinity,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Add ${widget.controller.selectedVehicleType} Fueling Record',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 20,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Enter details for your new fuel entry',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),

                      // form
                      Padding(
                        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Date field
                              _buildInputField(
                                label: 'Date',
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

                              // Odometer field
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

                              // Fuel amount field
                              _buildInputField(
                                label: 'Fuel Added (liters)',
                                controller: fuelAmountController,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter fuel amount';
                                  }
                                  if (double.tryParse(value) == null) {
                                    return 'Please enter a valid number';
                                  }
                                  return null;
                                },
                              ),

                              // Fuel cost field
                              _buildInputField(
                                label: 'Fuel Cost (total)',
                                controller: fuelCostController,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter fuel cost';
                                  }
                                  if (double.tryParse(value) == null) {
                                    return 'Please enter a valid number';
                                  }
                                  return null;
                                },
                              ),

                              const SizedBox(height: 24),

                              // Action buttons
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  // Cancel button
                                  TextButton(
                                    onPressed: () {
                                      _animationController.reverse().then((_) {
                                        Navigator.of(context).pop();
                                      });
                                    },
                                    style: TextButton.styleFrom(
                                      foregroundColor: Colors.grey[700],
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 12,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    child: const Text(
                                      'CANCEL',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),

                                  // Save button
                                  ElevatedButton(
                                    onPressed: _submitForm,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: primaryColor,
                                      foregroundColor: Colors.white,
                                      elevation: 0,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 24,
                                        vertical: 12,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    child: const Text(
                                      'SAVE',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
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
            ),

            // Icon at the top
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Center(
                child: CircleAvatar(
                  backgroundColor: primaryColor,
                  radius: 30,
                  child: Icon(
                    widget.controller.selectedVehicleType == 'Car'
                        ? Icons.directions_car_rounded
                        : Icons.two_wheeler_rounded,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
              ),
            ),

            // Close button
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
        widget.controller.addFuelEntry(
          DateTime.parse(dateController.text),
          double.parse(odometerController.text),
          double.parse(fuelAmountController.text),
          widget.controller.selectedVehicleType,
          double.parse(fuelCostController.text),
        );

        _animationController.reverse().then((_) {
          Navigator.of(context).pop();
        });
      } catch (e) {
        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }
}

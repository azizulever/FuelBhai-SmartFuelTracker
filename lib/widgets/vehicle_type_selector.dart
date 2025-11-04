import 'package:flutter/material.dart';
import 'package:mileage_calculator/utils/theme.dart';

class VehicleTypeSelector extends StatelessWidget {
  final String selectedVehicleType;
  final Function(String) onVehicleTypeChanged;

  const VehicleTypeSelector({
    Key? key,
    required this.selectedVehicleType,
    required this.onVehicleTypeChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12), // Reduced from 20
      child: Center(
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(25),
            border: Border.all(color: Colors.grey[200]!),
            boxShadow: [
              BoxShadow(
                color: Colors.grey[200]!,
                spreadRadius: 1,
                blurRadius: 2,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildVehicleButton(context, 'Bike', Icons.two_wheeler_rounded),
              _buildVehicleButton(context, 'Car', Icons.directions_car_rounded),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVehicleButton(BuildContext context, String type, IconData icon) {
    final isSelected = selectedVehicleType == type;

    return GestureDetector(
      onTap: () => onVehicleTypeChanged(type),
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Container(
          padding: const EdgeInsets.symmetric(
            vertical: 8,
            horizontal: 62,
          ), // Reduced horizontal padding
          decoration: BoxDecoration(
            color: isSelected ? primaryColor.withOpacity(0.1) : Colors.white,
            borderRadius: BorderRadius.circular(25),
            border:
                isSelected ? Border.all(color: primaryColor, width: 1) : null,
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: isSelected ? primaryColor : Colors.grey[600],
                size: 20,
              ),
              const SizedBox(width: 6), // Reduced from 8
              Text(
                type,
                style: TextStyle(
                  color: isSelected ? primaryColor : Colors.grey[700],
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

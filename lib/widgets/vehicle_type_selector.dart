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

  // Responsive helpers
  double _getResponsivePadding(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < 360) return 12.0; // Small phones
    if (width < 400) return 16.0; // Medium phones
    return 20.0; // Large phones and tablets
  }

  double _getButtonHorizontalPadding(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < 360) return 32.0; // Small phones
    if (width < 400) return 48.0; // Medium phones
    return 62.0; // Large phones and tablets
  }

  double _getButtonFontSize(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < 360) return 14.0; // Small phones
    if (width < 400) return 15.0; // Medium phones
    return 16.0; // Large phones and tablets
  }

  double _getIconSize(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < 360) return 18.0; // Small phones
    return 20.0; // Medium and large phones
  }

  double _getIconSpacing(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < 360) return 4.0; // Small phones
    return 6.0; // Medium and large phones
  }

  @override
  Widget build(BuildContext context) {
    final horizontalPadding = _getResponsivePadding(context);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
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
            children: [
              Expanded(
                child: _buildVehicleButton(
                  context,
                  'Bike',
                  Icons.two_wheeler_rounded,
                ),
              ),
              Expanded(
                child: _buildVehicleButton(
                  context,
                  'Car',
                  Icons.directions_car_rounded,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVehicleButton(BuildContext context, String type, IconData icon) {
    final isSelected = selectedVehicleType == type;
    final fontSize = _getButtonFontSize(context);
    final iconSize = _getIconSize(context);
    final iconSpacing = _getIconSpacing(context);

    return GestureDetector(
      onTap: () => onVehicleTypeChanged(type),
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
          decoration: BoxDecoration(
            color: isSelected ? primaryColor.withOpacity(0.1) : Colors.white,
            borderRadius: BorderRadius.circular(25),
            border:
                isSelected ? Border.all(color: primaryColor, width: 1) : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: isSelected ? primaryColor : Colors.grey[600],
                size: iconSize,
              ),
              SizedBox(width: iconSpacing),
              Flexible(
                child: Text(
                  type,
                  style: TextStyle(
                    color: isSelected ? primaryColor : Colors.grey[700],
                    fontWeight:
                        isSelected ? FontWeight.w600 : FontWeight.normal,
                    fontSize: fontSize,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

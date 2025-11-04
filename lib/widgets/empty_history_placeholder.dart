import 'package:flutter/material.dart';

class EmptyHistoryPlaceholder extends StatelessWidget {
  final String vehicleType;

  const EmptyHistoryPlaceholder({required this.vehicleType, Key? key})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            vehicleType == 'Car' ? Icons.directions_car : Icons.two_wheeler,
            size: 60,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 8),
          Text(
            'No $vehicleType entries yet.\nAdd your first fueling record.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
          const SizedBox(height: 50),
        ],
      ),
    );
  }
}

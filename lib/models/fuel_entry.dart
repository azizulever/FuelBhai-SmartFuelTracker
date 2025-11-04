import 'dart:core';

class FuelEntry {
  final String id;
  final DateTime date;
  final double odometer;
  final double fuelAmount;
  final double fuelCost;
  final String vehicleType;
  final double mileage;

  FuelEntry({
    this.id = '',
    required this.date,
    required this.odometer,
    required this.fuelAmount,
    required this.fuelCost,
    required this.vehicleType,
    this.mileage = 0.0,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date.millisecondsSinceEpoch,
      'odometer': odometer,
      'fuelAmount': fuelAmount,
      'fuelCost': fuelCost,
      'vehicleType': vehicleType,
      'mileage': mileage,
    };
  }

  factory FuelEntry.fromJson(Map<String, dynamic> json) {
    return FuelEntry(
      id: json['id'] ?? '',
      date: DateTime.fromMillisecondsSinceEpoch(json['date']),
      odometer: json['odometer'].toDouble(),
      fuelAmount: json['fuelAmount'].toDouble(),
      fuelCost: json['fuelCost'].toDouble(),
      vehicleType: json['vehicleType'],
      mileage: json['mileage']?.toDouble() ?? 0.0,
    );
  }
}

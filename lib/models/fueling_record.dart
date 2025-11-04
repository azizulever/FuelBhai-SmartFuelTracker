import 'package:cloud_firestore/cloud_firestore.dart';

class FuelingRecord {
  final String? id;
  final String userId;
  final DateTime date;
  final double liters;
  final double cost;
  final double odometer;
  final String? notes;
  final String vehicleId;

  FuelingRecord({
    this.id,
    required this.userId,
    required this.date,
    required this.liters,
    required this.cost,
    required this.odometer,
    this.notes,
    required this.vehicleId,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'date': Timestamp.fromDate(date),
      'liters': liters,
      'cost': cost,
      'odometer': odometer,
      'notes': notes,
      'vehicleId': vehicleId,
    };
  }

  // For local storage (JSON serializable)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'date': date.toIso8601String(), // Convert DateTime to string
      'liters': liters,
      'cost': cost,
      'odometer': odometer,
      'notes': notes,
      'vehicleId': vehicleId,
    };
  }

  factory FuelingRecord.fromMap(Map<String, dynamic> map, String documentId) {
    return FuelingRecord(
      id: documentId,
      userId: map['userId'] ?? '',
      date: (map['date'] as Timestamp).toDate(),
      liters: map['liters']?.toDouble() ?? 0.0,
      cost: map['cost']?.toDouble() ?? 0.0,
      odometer: map['odometer']?.toDouble() ?? 0.0,
      notes: map['notes'],
      vehicleId: map['vehicleId'] ?? '',
    );
  }

  // For local storage (from JSON)
  factory FuelingRecord.fromJson(Map<String, dynamic> json) {
    return FuelingRecord(
      id: json['id'],
      userId: json['userId'] ?? '',
      date: DateTime.parse(json['date']), // Parse DateTime from string
      liters: json['liters']?.toDouble() ?? 0.0,
      cost: json['cost']?.toDouble() ?? 0.0,
      odometer: json['odometer']?.toDouble() ?? 0.0,
      notes: json['notes'],
      vehicleId: json['vehicleId'] ?? '',
    );
  }
}

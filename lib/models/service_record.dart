import 'package:cloud_firestore/cloud_firestore.dart';

class ServiceRecord {
  final String id;
  final String userId;
  final DateTime serviceDate;
  final double odometerReading;
  final double totalCost;
  final String serviceType; // 'Major' or 'Minor'
  final String vehicleType;

  ServiceRecord({
    required this.id,
    required this.userId,
    required this.serviceDate,
    required this.odometerReading,
    required this.totalCost,
    required this.serviceType,
    required this.vehicleType,
  });

  // For Firebase storage
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'serviceDate': Timestamp.fromDate(serviceDate),
      'odometerReading': odometerReading,
      'totalCost': totalCost,
      'serviceType': serviceType,
      'vehicleType': vehicleType,
    };
  }

  // For local storage (JSON serializable)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'serviceDate': serviceDate.toIso8601String(),
      'odometerReading': odometerReading,
      'totalCost': totalCost,
      'serviceType': serviceType,
      'vehicleType': vehicleType,
    };
  }

  // From Firebase
  factory ServiceRecord.fromMap(Map<String, dynamic> map, String documentId) {
    return ServiceRecord(
      id: documentId,
      userId: map['userId'] ?? '',
      serviceDate: (map['serviceDate'] as Timestamp).toDate(),
      odometerReading: (map['odometerReading'] as num).toDouble(),
      totalCost: (map['totalCost'] as num).toDouble(),
      serviceType: map['serviceType'] as String,
      vehicleType: map['vehicleType'] as String,
    );
  }

  // From local storage (JSON)
  factory ServiceRecord.fromJson(Map<String, dynamic> json) {
    return ServiceRecord(
      id: json['id'] as String,
      userId: json['userId'] ?? '',
      serviceDate: DateTime.parse(json['serviceDate'] as String),
      odometerReading: (json['odometerReading'] as num).toDouble(),
      totalCost: (json['totalCost'] as num).toDouble(),
      serviceType: json['serviceType'] as String,
      vehicleType: json['vehicleType'] as String,
    );
  }
}
